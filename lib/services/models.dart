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
    this.dateModified,
  });

  final String path;
  final String title;
  final String artist;
  final String? album;
  final Duration? duration;

  /// File modification time (when the file landed on disk) — used for
  /// "Date added" sorting. Null when unknown.
  final DateTime? dateModified;

  /// Parses header tags for a batch of files inside background isolates so
  /// the UI thread never blocks. Cover art is intentionally NOT extracted
  /// here; it is loaded lazily per visible tile via [readEmbeddedArtwork].
  static Future<List<Song>> parseBatch(List<String> filePaths) async {
    if (filePaths.isEmpty) return const <Song>[];
    // ~3 parallel isolates: big speedup on multi-core phones without
    // spawning one isolate per file.
    const chunks = 3;
    var size = filePaths.length ~/ chunks;
    if (size == 0) size = filePaths.length;
    final futures = <Future<List<Song>>>[];
    for (var start = 0; start < filePaths.length; start += size) {
      final slice = filePaths.sublist(start, start + size > filePaths.length
          ? filePaths.length
          : start + size);
      futures.add(Isolate.run(() => [for (final path in slice) _parse(path)]));
    }
    final results = await Future.wait(futures);
    return [
      for (final part in results) ...part,
    ];
  }

  static Song _parse(String path) {
    try {
      final meta = readMetadata(File(path), getImage: false);
      final title = meta.title?.trim();
      final artist = meta.artist?.trim();
      DateTime? modified;
      try {
        modified = File(path).statSync().modified;
      } catch (_) {}
      return Song(
        path: path,
        title: title == null || title.isEmpty
            ? fallbackTrackName(path)
            : title,
        artist: artist == null || artist.isEmpty ? 'Unknown Artist' : artist,
        album: meta.album?.trim(),
        duration: meta.duration,
        dateModified: modified,
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

/// Standalone cover-art extractor used by [ArtworkRepository].
/// Returns raw encoded image bytes (png/jpg) or null.
Uint8List? readEmbeddedArtwork(String path) {
  try {
    final meta = readMetadata(File(path), getImage: true);
    return meta.pictures.isNotEmpty ? meta.pictures.first.bytes : null;
  } catch (_) {
    return null;
  }
}
