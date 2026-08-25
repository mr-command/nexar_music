import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import 'utils.dart';

/// Immutable song model.
class Song {
  const Song({
    required this.path,
    required this.title,
    required this.artist,
    this.album,
    this.duration,
    this.artwork,
  });

  final String path;
  final String title;
  final String artist;
  final String? album;
  final Duration? duration;

  /// Embedded cover art bytes (may be null).
  final Uint8List? artwork;

  /// Loads metadata for every file inside a background isolate so the UI
  /// thread never blocks — the old code parsed metadata synchronously inside
  /// `ListView.itemBuilder`, freezing the whole app on large libraries.
  static Future<List<Song>> loadLibrary(List<String> filePaths) {
    if (filePaths.isEmpty) return Future.value(const <Song>[]);
    return Isolate.run(() {
      final songs = <Song>[];
      for (final path in filePaths) {
        songs.add(_parse(path));
      }
      return songs;
    });
  }

  static Song _parse(String path) {
    try {
      final meta = readMetadata(File(path), getImage: true);
      final title = meta.title?.trim();
      final artist = meta.artist?.trim();
      return Song(
        path: path,
        title: title == null || title.isEmpty
            ? fallbackTrackName(path)
            : title,
        artist: artist == null || artist.isEmpty ? 'Unknown Artist' : artist,
        album: meta.album?.trim(),
        duration: meta.duration,
        artwork: meta.pictures.isNotEmpty ? meta.pictures.first.bytes : null,
      );
    } catch (_) {
      // One unreadable/corrupt file must not break the whole library.
      return Song(
        path: path,
        title: fallbackTrackName(path),
        artist: 'Unknown Artist',
      );
    }
  }

  @override
  bool operator ==(Object other) => other is Song && other.path == path;

  @override
  int get hashCode => path.hashCode;
}
