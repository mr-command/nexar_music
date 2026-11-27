import 'package:shared_preferences/shared_preferences.dart';

/// The app's single library cache.
///
/// Device storage is walked once; the resulting audio file paths are then
/// persisted in SharedPreferences. On every launch those paths are read back
/// and metadata is fetched from the files directly — no repeated directory
/// scan — until the cache is cleared or the user forces a refresh.
abstract final class MusicCache {
  static const String _key = 'cached_music_paths';
  static const String _downloadedKey = 'downloaded_music_paths';

  /// Cached audio paths, or an empty list when nothing was scanned yet.
  static Future<List<String>> loadPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key) ?? const <String>[];
    } catch (_) {
      return const <String>[];
    }
  }

  /// Persists [paths] after a scan so future launches can skip it.
  static Future<void> savePaths(List<String> paths) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, paths);
    } catch (_) {
      // Persistence is best-effort; losing it only costs one extra scan.
    }
  }

  /// Drops the cache so the next launch performs a full scan again.
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }

  /// Audio files downloaded from the online catalog. Kept separately from the
  /// scan cache so a full rescan never drops them.
  static Future<List<String>> loadDownloadedPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_downloadedKey) ?? const <String>[];
    } catch (_) {
      return const <String>[];
    }
  }

  static Future<void> addDownloadedPath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final paths = prefs.getStringList(_downloadedKey) ?? <String>[];
      if (!paths.contains(path)) {
        paths.add(path);
        await prefs.setStringList(_downloadedKey, paths);
      }
    } catch (_) {}
  }
}
