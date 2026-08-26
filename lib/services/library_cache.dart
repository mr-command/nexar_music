import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// On-disk representation of one parsed song.
///
/// Identity = file modification time + size, so edited/replaced files are
/// automatically re-parsed on the next launch instead of served stale.
class CachedSong {
  const CachedSong({
    required this.modifiedMs,
    required this.size,
    required this.title,
    required this.artist,
    this.album,
    this.durationMs,
  });

  factory CachedSong.fromSong(Song song, {required int size}) =>
      CachedSong(
        modifiedMs: song.dateModified?.millisecondsSinceEpoch ?? 0,
        size: size,
        title: song.title,
        artist: song.artist,
        album: song.album,
        durationMs: song.duration?.inMilliseconds,
      );

  factory CachedSong.fromJson(Map<String, dynamic> json) => CachedSong(
        modifiedMs: (json['m'] as num?)?.toInt() ?? 0,
        size: (json['s'] as num?)?.toInt() ?? 0,
        title: json['t'] as String,
        artist: json['a'] as String? ?? '',
        album: json['al'] as String?,
        durationMs: (json['d'] as num?)?.toInt(),
      );

  final int modifiedMs;
  final int size;
  final String title;
  final String artist;
  final String? album;
  final int? durationMs;

  Map<String, dynamic> toJson() => {
        'm': modifiedMs,
        's': size,
        't': title,
        'a': artist,
        if (album != null) 'al': album,
        if (durationMs != null) 'd': durationMs,
      };

  Song toSong(String path) => Song(
        path: path,
        title: title,
        artist: artist,
        album: album,
        duration:
            durationMs == null ? null : Duration(milliseconds: durationMs!),
        dateModified:
            modifiedMs <= 0 ? null : DateTime.fromMillisecondsSinceEpoch(
                modifiedMs),
      );
}

abstract final class LibraryCache {
  static const String _key = 'nexar_library_cache_v1';

  /// Compact JSON: `{"<path>": {...}}` — a whole large library fits in a few
  /// hundred KB, which SharedPreferences handles comfortably.
  static Future<Map<String, CachedSong>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return <String, CachedSong>{};
      final decoded =
          (jsonDecode(raw) as Map<String, dynamic>).cast<String, Object?>();
      return decoded.map((path, entry) => MapEntry(path,
          CachedSong.fromJson((entry as Map).cast<String, dynamic>())));
    } catch (_) {
      return <String, CachedSong>{};
    }
  }

  static Future<void> save(Map<String, CachedSong> cache) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode({
        for (final entry in cache.entries) entry.key: entry.value.toJson(),
      }));
    } catch (_) {
      // Cache persistence is best-effort; losing it only costs speed.
    }
  }
}
