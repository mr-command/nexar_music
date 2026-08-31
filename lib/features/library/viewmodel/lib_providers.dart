import 'dart:io';

import 'package:flutter_riverpod/legacy.dart';
import 'package:nexar_app/services/library_cache.dart';
import 'package:nexar_app/services/models.dart';
import 'package:nexar_app/services/providers.dart';
import 'package:nexar_app/services/utils.dart';
import 'package:permission_handler/permission_handler.dart';





// Library — cached paths + progressive metadata loading



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
      ),
    );

Song _placeholderSong(String path) =>
    Song(path: path, title: fallbackTrackName(path), artist: 'Unknown Artist');

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
  List<Song> songs,
  bool Function(String path) isFavorite,
) {
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
  return [
    for (final song in songs)
      if (winners.contains(song.path)) song,
  ];
}

bool _prefer(Song candidate, Song incumbent, bool Function(String) isFavorite) {
  final candidateScore =
      (isFavorite(candidate.path) ? 2 : 0) - candidate.path.length;
  final incumbentScore =
      (isFavorite(incumbent.path) ? 2 : 0) - incumbent.path.length;
  return candidateScore > incumbentScore;
}

class LibraryController extends StateNotifier<LibraryState> {
  LibraryController({required this.isFavorite})
    : super(const LibraryState(scanning: true)) {
    _load();
  }

  /// Used to keep the user-favorited copy when folding duplicate tracks.
  final bool Function(String path) isFavorite;

  int _generation = 0;

  /// Manual rescan requested by the user (Refresh button): walks storage
  /// again and rewrites the path cache.
  Future<void> refresh() => _load(forceRescan: true);

  Future<void> _load({bool forceRescan = false}) async {
    final generation = ++_generation;
    state = const LibraryState(scanning: true);

    // Android 6+ needs the audio permission granted at runtime before
    // shared storage can be listed; desktop platforms need nothing.
    if (Platform.isAndroid) {
      await [Permission.audio, Permission.storage].request();
    }

    try {
      var paths = forceRescan ? const <String>[] : await MusicCache.loadPaths();

      // No cached paths yet — scan the directories and remember the result.
      if (paths.isEmpty) {
        paths = await scanAudioFiles();
        await MusicCache.savePaths(paths);
      }
      if (generation != _generation) return;

      var resolved = <String, Song>{};

      // Phase 1 — show instant filename-based placeholder rows.
      void publish({bool done = false}) {
        state = LibraryState(
          parsing: !done && paths.isNotEmpty,
          songs: _dedupeSameTracks([
            for (final path in paths) resolved[path] ?? _placeholderSong(path),
          ], isFavorite),
        );
      }

      publish();

      // Phase 2 — resolve real tags chunk-by-chunk with the metadata reader.
      const chunkSize = 48;
      for (
        var start = 0;
        start < paths.length && generation == _generation;
        start += chunkSize
      ) {
        final chunk = paths.sublist(
          start,
          (start + chunkSize).clamp(0, paths.length),
        );
        try {
          final parsed = await Song.parseBatch(
            chunk,
          ).timeout(const Duration(minutes: 2));
          if (generation != _generation) return;
          for (final song in parsed) {
            resolved[song.path] = song;
          }
          publish();
        } catch (_) {
          // Isolate failure/timeout on one chunk must not lose the rest.
        }
      }

      if (generation != _generation) return;

      // All tags resolved — clear the parsing indicator for good.
      publish(done: true);
    } catch (error) {
      if (generation == _generation) {
        state = LibraryState(error: '$error');
      }
    }
  }
}