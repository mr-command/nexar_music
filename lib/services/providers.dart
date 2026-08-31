import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nexar_app/features/library/viewmodel/lib_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/design_system.dart';
import 'artwork_repository.dart';
import 'audio_handler.dart';
import 'audio_service.dart';
import 'models.dart';
import 'utils.dart';

// ---------------------------------------------------------------------------
// Design / theme
// ---------------------------------------------------------------------------

enum AppStyle { light, dark }



final themeProvider = StateProvider<AppStyle>((ref) => AppStyle.dark);

final designProvider = Provider<DesignSystem>((ref) {
  return switch (ref.watch(themeProvider)) {
    AppStyle.light => const NeumorphismDesign(),
    AppStyle.dark => const LiquidGlassDesign(),
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
  (ref) =>
      AudioService(ref.watch(playerProvider), ref.watch(audioHandlerProvider)),
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

final loopStateProvider = StreamProvider<PlaylistMode>((ref) async* {
  await for (final mode in ref.watch(playerProvider).stream.playlistMode) {
    yield mode;
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
// Artwork (lazy, LRU-cached in memory only)
// ---------------------------------------------------------------------------

final artworkProvider = FutureProvider.family<Uint8List?, String>(
  (ref, path) => ArtworkRepository.load(path),
);

// ---------------------------------------------------------------------------
// Favorites
// ---------------------------------------------------------------------------

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) {
    return FavoritesNotifier();
  },
);

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

    await prefs.setStringList(_favoritesKey, next.toList());
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
final sortProvider = StateNotifierProvider<SortController, SortSpec>(
  (ref) => SortController(),
);

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
