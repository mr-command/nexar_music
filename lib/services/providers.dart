import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:media_kit/media_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/design_system.dart';
import 'artwork_repository.dart';
import 'audio_handler.dart';
import 'audio_service.dart';
import 'library_cache.dart';
import 'models.dart';
import 'utils.dart';

// ---------------------------------------------------------------------------
// Design / theme
// ---------------------------------------------------------------------------

enum AppStyle { neumorphism, liquid }

final themeProvider = StateProvider<AppStyle>((ref) => AppStyle.neumorphism);

final designProvider = Provider<DesignSystem>((ref) {
  return switch (ref.watch(themeProvider)) {
    AppStyle.neumorphism => const NeumorphismDesign(),
    AppStyle.liquid => const LiquidGlassDesign(),
  };
});

// ---------------------------------------------------------------------------
// Audio engine
// ---------------------------------------------------------------------------

final playerProvider = Provider<Player>((ref) {
  final player = Player();
  ref.onDispose(player.dispose);
  return player;
});

/// Created once in main() before runApp so the media session is ready
/// before any playback can start.
final audioHandlerProvider = Provider<NexarAudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden in main');
});

final audioServiceProvider = Provider<AudioService>(
  (ref) => AudioService(ref.watch(playerProvider), ref.watch(audioHandlerProvider)),
);

/// Stream-backed playback state — can never drift out of sync with the
/// engine, even after auto-advance, track end or external changes.
final isPlayingProvider = StreamProvider<bool>(
  (ref) => ref.watch(playerProvider).stream.playing,
);

final positionProvider = StreamProvider<Duration>(
  (ref) => ref.watch(playerProvider).stream.position,
);

final durationProvider = StreamProvider<Duration>(
  (ref) => ref.watch(playerProvider).stream.duration,
);

final playlistStreamProvider = StreamProvider<Playlist>(
  (ref) => ref.watch(playerProvider).stream.playlist,
);

final shuffleStateProvider = StreamProvider<bool>(
  (ref) => ref.watch(playerProvider).stream.shuffle,
);

final loopStateProvider = StreamProvider<bool>((ref) async* {
  await for (final mode in ref.watch(playerProvider).stream.playlistMode) {
    yield mode != PlaylistMode.none;
  }
});

/// The song currently loaded by the engine. Derived from the playlist stream,
/// so it updates automatically when tracks auto-advance.
final currentSongProvider = Provider<Song?>((ref) {
  final playlist = ref.watch(playlistStreamProvider).value;
  if (playlist == null ||
      playlist.index < 0 ||
      playlist.index >= playlist.medias.length) {
    return null;
  }
  final path = playlist.medias[playlist.index].uri;
  final library = ref.watch(libraryControllerProvider).songs;
  for (final song in library) {
    if (song.path == path) return song;
  }
  // Track is playing but no longer part of the scanned library.
  return Song(
    path: path,
    title: fallbackTrackName(path),
    artist: 'Unknown Artist',
  );
});

// ---------------------------------------------------------------------------
// Library — cached, progressive loader
//
// Warm start  : metadata comes straight from a SharedPreferences JSON cache
//               (validated against file mtimes/sizes) → near-instant list.
// Cold start  : filename placeholders appear immediately, real tags stream in
//               chunk-by-chunk from background isolates.
// ---------------------------------------------------------------------------

class LibraryState {
  const LibraryState({
    this.scanning = false,
    this.parsing = false,
    this.error,
    this.songs = const <Song>[],
  });

  /// Initial scan phase (permissions + directory walk + cache read).
  final bool scanning;

  /// Tags still streaming in in the background over placeholder rows.
  final bool parsing;
  final String? error;
  final List<Song> songs;

  bool get isBusy => scanning || parsing;
}

final libraryControllerProvider =
    StateNotifierProvider<LibraryController, LibraryState>(
        (ref) => LibraryController(
              isFavorite: (path) => ref.read(favoritesProvider).contains(path),
            ));

Song _placeholderSong(String path) => Song(
      path: path,
      title: fallbackTrackName(path),
      artist: 'Unknown Artist',
    );

/// Fingerprint deciding whether two rows are "the same song": matching
/// title, artist and duration. Files that merely live in two folders
/// (Downloads/Music/WhatsApp…) or arrive twice through mirrored mounts are
/// folded into a single entry.
String _trackSignature(Song song) =>
    '${song.title.toLowerCase()}|'
    '${song.artist.toLowerCase()}|'
    '${song.duration?.inMilliseconds ?? -1}';

/// Collapses repeated tracks, preferring a favorited copy, then the shortest
/// path (most canonical location).
List<Song> _dedupeSameTracks(
    List<Song> songs, bool Function(String path) isFavorite) {
  final best = <String, Song>{};
  for (final song in songs) {
    final signature = _trackSignature(song);
    final current = best[signature];
    if (current == null || _prefer(song, current, isFavorite)) {
      best[signature] = song;
    }
  }
  // Preserve first-appearance ordering of winning entries.
  final winners = Set<String>.of(best.values.map((s) => s.path));
  return [for (final song in songs) if (winners.contains(song.path)) song];
}

bool _prefer(
    Song candidate, Song incumbent, bool Function(String) isFavorite) {
  final candidateScore =
      (isFavorite(candidate.path) ? 2 : 0) - candidate.path.length;
  final incumbentScore =
      (isFavorite(incumbent.path) ? 2 : 0) - incumbent.path.length;
  return candidateScore > incumbentScore;
}

class LibraryController extends StateNotifier<LibraryState> {
  LibraryController({required this.isFavorite})
      : super(const LibraryState(scanning: true)) {
    _initialLoad();
  }

  /// Used to keep the user-favorited copy when folding duplicate tracks.
  final bool Function(String path) isFavorite;

  int _generation = 0;

  /// Manual rescan requested by the user (Refresh button).
  Future<void> refresh() => _load();

  Future<void> _initialLoad() => _load();

  Future<void> _load() async {
    final generation = ++_generation;
    state = const LibraryState(scanning: true);

    // Android 6+ needs the audio permission granted at runtime before
    // shared storage can be listed; desktop platforms need nothing.
    if (Platform.isAndroid) {
      await [Permission.audio, Permission.storage].request();
    }
    try {
      final paths = await scanAudioFiles();
      if (generation != _generation) return;

      final stamps = await stampFiles(paths);
      if (generation != _generation) return;

      final cache = await LibraryCache.load();
      if (generation != _generation) return;

      var reused = <String, Song>{};
      final pending = <String>[];
      for (final path in paths) {
        final stamp = stamps[path];
        final entry = cache[path];
        if (stamp != null &&
            entry != null &&
            entry.modifiedMs == stamp.modifiedMs &&
            entry.size == stamp.size) {
          reused[path] = entry.toSong(path);
        } else {
          pending.add(path);
        }
      }

      // Phase 1 done — show whatever the cache gave us right away; every
      // uncached file gets an instant filename-based placeholder row.
      void publish({bool done = false}) {
        state = LibraryState(
          parsing: !done && pending.isNotEmpty,
          songs: _dedupeSameTracks(
            [
              for (final path in paths)
                reused[path] ?? _placeholderSong(path),
            ],
            isFavorite,
          ),
        );
      }

      publish();

      // Prune entries for files that vanished or changed shape so the cache
      // cannot grow without bound over years of edits/deletions.
      final nextCache = <String, CachedSong>{
        for (final entry in cache.entries)
          if (stamps.containsKey(entry.key) &&
              entry.value.modifiedMs == stamps[entry.key]!.modifiedMs)
            entry.key: entry.value,
      };

      const chunkSize = 48;
      var savedAny = false;
      for (var start = 0; start < pending.length && generation == _generation;
          start += chunkSize) {
        final chunk =
            pending.sublist(start, (start + chunkSize).clamp(0, pending.length));
        try {
          final parsed = await Song.parseBatch(chunk)
              .timeout(const Duration(minutes: 2));
          if (generation != _generation) return;
          for (final song in parsed) {
            reused[song.path] = song;
            final stamp = stamps[song.path];
            nextCache[song.path] = CachedSong.fromSong(song,
                size: stamp?.size ?? 0);
          }
          savedAny = true;
          publish();
        } catch (_) {
          // Isolate failure/timeout on one chunk must not lose the rest.
        }
      }

      if (generation != _generation) return;

      // All tags resolved — clear the parsing indicator for good.
      publish(done: true);

      if (savedAny || nextCache.length != cache.length) {
        unawaited(LibraryCache.save(nextCache));
      }
    } catch (error) {
      if (generation == _generation) {
        state = LibraryState(error: '$error');
      }
    }
  }
}


// ---------------------------------------------------------------------------
// Artwork (lazy, LRU-cached in memory only)
// ---------------------------------------------------------------------------

final artworkProvider = FutureProvider.family<Uint8List?, String>(
  (ref, path) => ArtworkRepository.load(path),
);

// ---------------------------------------------------------------------------
// Favorites
// ---------------------------------------------------------------------------

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  static const String _favoritesKey = 'favorite_music';

  FavoritesNotifier() : super(<String>{}) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    final favorites = prefs.getStringList(_favoritesKey) ?? [];

    state = favorites.toSet();
  }

  Future<void> toggle(String path) async {
    final next = Set<String>.of(state);

    if (next.contains(path)) {
      next.remove(path);
    } else {
      next.add(path);
    }

    state = next;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _favoritesKey,
      next.toList(),
    );
  }

  bool isFavorite(String path) {
    return state.contains(path);
  }
}

// ---------------------------------------------------------------------------
// Browsing state (search / filters / sorting)
// ---------------------------------------------------------------------------

final searchQueryProvider = StateProvider<String>((ref) => '');

final favoritesOnlyProvider = StateProvider<bool>((ref) => false);

const String _sortFieldKey = 'sort_field';
const String _sortAscendingKey = 'sort_ascending';

/// Persisted sorting selection so the layout survives app restarts.
final sortProvider =
    StateNotifierProvider<SortController, SortSpec>((ref) => SortController());

class SortController extends StateNotifier<SortSpec> {
  SortController() : super(const SortSpec(SortField.title)) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fieldIndex = prefs.getInt(_sortFieldKey);
      final ascending = prefs.getBool(_sortAscendingKey) ?? true;
      if (fieldIndex != null &&
          fieldIndex >= 0 &&
          fieldIndex < SortField.values.length) {
        state = SortSpec(SortField.values[fieldIndex], ascending: ascending);
      } else if (!ascending) {
        state = SortSpec(state.field, ascending: false);
      }
    } catch (_) {}
  }

  Future<void> setField(SortField field) async {
    if (field == state.field) {
      await setAscending(!state.ascending);
      return;
    }
    await _apply(SortSpec(field));
  }

  Future<void> setAscending(bool ascending) =>
      _apply(SortSpec(state.field, ascending: ascending));

  Future<void> toggleDirection() => setAscending(!state.ascending);

  Future<void> _apply(SortSpec spec) async {
    state = spec;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_sortFieldKey, spec.field.index);
      await prefs.setBool(_sortAscendingKey, spec.ascending);
    } catch (_) {}
  }
}

/// Songs matching search/filters, sorted by the active [SortSpec].
final visibleSongsProvider = Provider<List<Song>>((ref) {
  final songs = ref.watch(libraryControllerProvider).songs;
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final favoritesOnly = ref.watch(favoritesOnlyProvider);
  final favorites = ref.watch(favoritesProvider);
  final sort = ref.watch(sortProvider);

  final filtered = [
    for (final song in songs)
      if ((!favoritesOnly || favorites.contains(song.path)) &&
          (query.isEmpty ||
              song.title.toLowerCase().contains(query) ||
              song.artist.toLowerCase().contains(query) ||
              (song.album?.toLowerCase().contains(query) ?? false)))
        song,
  ];

  if (filtered.length > 1) {
    filtered.sort(sort.compare);
  }
  return filtered;
});
