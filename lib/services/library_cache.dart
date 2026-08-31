import 'package:shared_preferences/shared_preferences.dart';

/// The app's single library cache.
///
/// Device storage is walked once; the resulting audio file paths are then
/// persisted in SharedPreferences. On every launch those paths are read back
/// and metadata is fetched from the files directly — no repeated directory
/// scan — until the cache is cleared or the user forces a refresh.
abstract final class MusicCache {
  static const String _key = 'cached_music_paths';

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
}
