import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:media_kit/media_kit.dart';

import '../components/design_system.dart';
import 'audio_service.dart';
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

final audioServiceProvider = Provider<AudioService>(
  (ref) => AudioService(ref.watch(playerProvider)),
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
/// so it updates automatically when tracks auto-advance (the old code only
/// updated it on manual taps, leaving the mini-player stale).
final currentSongProvider = Provider<Song?>((ref) {
  final playlist = ref.watch(playlistStreamProvider).value;
  if (playlist == null ||
      playlist.index < 0 ||
      playlist.index >= playlist.medias.length) {
    return null;
  }
  final path = playlist.medias[playlist.index].uri;
  final library = ref.watch(libraryProvider).value ?? const <Song>[];
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
// Library
// ---------------------------------------------------------------------------

final libraryProvider = FutureProvider<List<Song>>((ref) async {
  final paths = await scanAudioFiles();
  return Song.loadLibrary(paths);
});

// ---------------------------------------------------------------------------
// Favorites
// ---------------------------------------------------------------------------

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super(const <String>{});

  void toggle(String path) {
    final next = Set<String>.of(state);
    if (next.contains(path)) {
      next.remove(path);
    } else {
      next.add(path);
    }
    state = next;
  }

  bool isFavorite(String path) => state.contains(path);
}

// ---------------------------------------------------------------------------
// Browsing state
// ---------------------------------------------------------------------------

final searchQueryProvider = StateProvider<String>((ref) => '');

final favoritesOnlyProvider = StateProvider<bool>((ref) => false);

/// Songs matching the active search query and favorites filter.
final visibleSongsProvider = Provider<List<Song>>((ref) {
  final songs = ref.watch(libraryProvider).value ?? const <Song>[];
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final favoritesOnly = ref.watch(favoritesOnlyProvider);
  final favorites = ref.watch(favoritesProvider);

  return [
    for (final song in songs)
      if ((!favoritesOnly || favorites.contains(song.path)) &&
          (query.isEmpty ||
              song.title.toLowerCase().contains(query) ||
              song.artist.toLowerCase().contains(query) ||
              (song.album?.toLowerCase().contains(query) ?? false)))
        song,
  ];
});
