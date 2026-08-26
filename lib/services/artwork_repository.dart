import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'models.dart';

/// Lazy, memory-bounded loader for embedded cover art.
///
/// Artwork is the single most expensive part of library loading (extracting
/// + decoding hundreds of images), so it is parsed off the UI thread only
/// when a tile actually becomes visible and cached in a small LRU — never
/// kept inside [Song], so playlist/list operations stay cheap.
abstract final class ArtworkRepository {
  static const int _maxEntries = 192;
  static const int _maxFailedEntries = 128;

  static final Map<String, Uint8List> _cache = <String, Uint8List>{};
  static final Map<String, Uri> _cachedUris = <String, Uri>{};
  static final Map<String, Future<Uri?>> _fileFutures = <String, Future<Uri?>>{};
  static final Set<String> _failed = <String>{};

  static Directory? _coversDir;

  static Uint8List? peek(String path) => _cache[path];

  /// Art file URI when already materialized in memory (synchronous).
  static Uri? cachedArtworkUri(String path) => _cachedUris[path];

  /// Raw encoded image bytes for [path], parsed in a background isolate.
  ///
  /// Returns null for songs without embedded art; failures are remembered so
  /// scrolling through art-less tracks does no repeated work.
  static Future<Uint8List?> load(String path) async {
    final cached = _cache[path];
    if (cached != null) return cached;
    if (_failed.contains(path)) return null;

    try {
      // Kick off the notification copy opportunistically.
      unawaited(artworkFile(path));
      final bytes = await Isolate.run(() => readEmbeddedArtwork(path));
      if (bytes == null || bytes.isEmpty) {
        _rememberFailed(path);
        return null;
      }
      _cache[path] = bytes;
      while (_cache.length > _maxEntries) {
        _cache.remove(_cache.keys.first);
      }
      return bytes;
    } catch (_) {
      _rememberFailed(path);
      return null;
    }
  }

  /// URI of an on-disk copy of the artwork. Android's MediaStyle notification
  /// can only render artwork from file URIs, not byte arrays.
  /// Concurrent callers share one extraction future per song.
  static Future<Uri?> artworkFile(String path) {
    final existing = _cachedUris[path];
    if (existing != null) return Future.value(existing);
    return _fileFutures.putIfAbsent(path, () async {
      try {
        final source =
            _cache[path] ?? await Isolate.run(() => readEmbeddedArtwork(path));
        if (source == null || source.isEmpty) {
          _rememberFailed(path);
          return null;
        }
        final uri = await _writeArtFile(source, path);
        _cachedUris[path] = uri;
        while (_cachedUris.length > _maxEntries * 2) {
          _cachedUris.remove(_cachedUris.keys.first);
        }
        return uri;
      } catch (_) {
        return null;
      } finally {
        _fileFutures.remove(path);
      }
    });
  }

  static void _rememberFailed(String path) {
    _failed.add(path);
    if (_failed.length > _maxFailedEntries) {
      _failed.remove(_failed.first);
    }
  }

  static Future<Uri> _writeArtFile(Uint8List bytes, String songPath) async {
    final dir = _coversDir ??
        Directory('${(await getApplicationCacheDirectory()).path}/covers');
    await dir.create(recursive: true);
    final name = songPath.hashCode.abs().toRadixString(36);
    final file = File('${dir.path}/$name.art');
    await file.writeAsBytes(bytes, flush: false);
    return Uri.file(file.path);
  }
}
