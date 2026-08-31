import 'dart:io';

import 'models.dart';

/// Supported audio file extensions.
const audioExtensions = <String>[
  '.mp3',
  '.m4a',
  '.aac',
  '.flac',
  '.wav',
  '.ogg',
  '.opus',
  '.wma',
];

/// Directory names never worth descending into while hunting for music.
const _prunedDirectories = <String>{
  // Android system / app-private noise on shared storage.
  'android',
  'lost.dir',
  'dcim', // camera pictures/videos only
  'movies',
  'alarms',
  'ringtones',
  'notifications',
  'podcasts',
  // Windows noise.
  'appdata',
  'windows',
  r'$recycle.bin',
  'system volume information',
};

/// True when running on a mobile platform.
bool get isMobilePlatform => Platform.isAndroid;

/// Returns every root directory this platform should be scanned for music.
List<Directory> musicDirectories() {
  final env = Platform.environment;
  final dirs = <Directory>[];

  void add(String rawPath) {
    if (rawPath.isEmpty) return;
    final dir = Directory(_canonicalDirPath(rawPath));
    // Same physical directory must never be registered twice (e.g. XDG
    // Music == ~/Music), or its songs would be listed multiple times.
    if (!dirs.any((d) => d.path == dir.path)) dirs.add(dir);
  }

  if (Platform.isAndroid) {
    add('/storage/emulated/0');
    _mountedAndroidVolumes().forEach(add);
  } else if (Platform.isWindows) {
    final profile = env['USERPROFILE'];
    if (profile != null && profile.isNotEmpty) {
      add('$profile\\Music');
      add('$profile\\Downloads');
    }
    for (var code = 67; code <= 90; code++) {
      final drive = String.fromCharCode(code);
      if (drive == 'C') continue;
      add('$drive:\\Music');
    }
  } else {
    final home = env['HOME'];
    final xdgMusic = env['XDG_MUSIC_DIR']?.replaceAll(r'$HOME', home ?? '');
    if (xdgMusic != null && xdgMusic.isNotEmpty) add(xdgMusic);
    if (home != null && home.isNotEmpty) {
      add('$home/Music');
      add('$home/Downloads');
    }
  }

  return dirs;
}

/// Mounted removable volumes on Android look like `/storage/XXXX-XXXX`.
Iterable<String> _mountedAndroidVolumes() sync* {
  try {
    final emulatedRoot = _canonicalDirPath('/storage/emulated/0');
    for (final entity in Directory('/storage').listSync(followLinks: false)) {
      if (entity is! Directory) continue;
      final name = pathBaseName(entity.path);
      if (name == 'emulated' || name == 'self') continue;
      if (RegExp(r'^[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}$').hasMatch(name)) {
        final canonical = _canonicalDirPath(entity.path);
        // Some ROMs expose the internal emulated storage under its volume
        // UUID as well — that would duplicate the whole library.
        if (canonical == emulatedRoot) continue;
        yield canonical;
      }
    }
  } catch (_) {
    // /storage is not accessible on some devices — nothing to do.
  }
}

/// Normalizes a directory path for identity comparison: absolute form with
/// separators and trailing slash normalized, without resolving symlinks
/// (unavailable/pointless across platforms; keeps the call cheap & safe).
String _canonicalDirPath(String path) {
  var p = Directory(path).absolute.path;
  if (p.length > 1 && (p.endsWith('/') || p.endsWith(r'\'))) {
    p = p.substring(0, p.length - 1);
  }
  return Platform.isWindows ? p.replaceAll('\\', '/').toLowerCase() : p;
}

String musicDirectoryLabel() {
  return musicDirectories().length < 2
      ? (Platform.isWindows ? '%USERPROFILE%\\Music' : '~/Music')
      : (isMobilePlatform ? 'Device storage' : 'Multiple directories');
}

/// Scans every music root of the current platform concurrently and returns
/// sorted file paths.
///
/// Returns an empty list when no root exists — the old code returned the fake
/// path `'list is empty'`, which later crashed playback.
Future<List<String>> scanAudioFiles() async {
  final roots = musicDirectories();
  if (roots.isEmpty) return const <String>[];

  final results = await Future.wait([
    for (final root in roots) _scanRoot(root),
  ]);

  // Overlapping mounts (e.g. an SD-card path also visible under the primary
  // storage) would otherwise push every shared song twice into the library.
  final seen = <String>{};
  final paths = [
    for (final batch in results)
      for (final path in batch)
        if (seen.add(path)) path,
  ];

  paths.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  return paths;
}

/// Walks [root] breadth-first, collecting audio files while skipping pruned,
/// hidden and unreadable directories.
Future<List<String>> _scanRoot(Directory root) async {
  if (!root.existsSync()) return const <String>[];

  final found = <String>[];
  final pending = <Directory>[root];

  while (pending.isNotEmpty) {
    final dir = pending.removeLast();

    List<FileSystemEntity> children;
    try {
      children = await dir.list(followLinks: false).toList();
    } catch (_) {
      continue; // Permission denied or vanished mid-scan — skip quietly.
    }

    for (final entity in children) {
      final name = pathBaseName(entity.path);
      if (name.startsWith('.')) continue;

      if (entity is Directory) {
        if (_prunedDirectories.contains(name.toLowerCase())) continue;
        pending.add(entity);
      } else if (entity is File &&
          audioExtensions.contains(extensionOf(name).toLowerCase())) {
        found.add(_normalize(entity.path));
      }
    }
  }

  return found;
}

// ---------------------------------------------------------------------------
// Path helpers (separator-agnostic: work with both `/` and `\`)
// ---------------------------------------------------------------------------

/// Converts Windows separators to `/` for uniform comparisons.
String _normalize(String path) =>
    Platform.isWindows ? path.replaceAll('\\', '/') : path;

/// File name portion of [path], regardless of separator style.
String pathBaseName(String path) {
  final slash = path.lastIndexOf('/');
  final backslash = path.lastIndexOf('\\');
  final cut = slash > backslash ? slash : backslash;
  return cut == -1 ? path : path.substring(cut + 1);
}

/// Extension (with the dot) of [path] or [name], or '' when there is none.
String extensionOf(String path) {
  final base = pathBaseName(path);
  final dot = base.lastIndexOf('.');
  if (dot == -1 || dot == 0) return '';
  return base.substring(dot);
}

/// Turns a raw filename into a human-friendly track name.
String fallbackTrackName(String path) {
  var base = pathBaseName(path);
  final ext = extensionOf(base);
  var name = ext.isNotEmpty
      ? base.substring(0, base.length - ext.length)
      : base;
  name = name.replaceAll('_', ' ').replaceAll('-', ' ');
  name = name.replaceFirst(RegExp(r'^\d{1,3}\s*[\s.]\s*'), '');
  name = RegExp(r'\s+').allMatches(name).isEmpty
      ? name.trim()
      : name.split(RegExp(r'\s+')).join(' ').trim();
  return name.isEmpty ? 'Unknown Track' : name;
}

/// Formats a duration as m:ss or h:mm:ss.
String formatDuration(Duration? duration) {
  if (duration == null || duration < Duration.zero) return '--:--';
  String two(int value) => value.toString().padLeft(2, '0');
  final hours = duration.inHours;
  if (hours > 0) {
    return '$hours:${two(duration.inMinutes.remainder(60))}:${two(duration.inSeconds.remainder(60))}';
  }
  return '${two(duration.inMinutes)}:${two(duration.inSeconds.remainder(60))}';
}

// ---------------------------------------------------------------------------
// Sorting
// ---------------------------------------------------------------------------

/// Fields the library can be sorted by.
enum SortField { title, artist, album, duration, dateAdded }

extension SortFieldLabel on SortField {
  String get label => switch (this) {
    SortField.title => 'Title',
    SortField.artist => 'Artist',
    SortField.album => 'Album',
    SortField.duration => 'Duration',
    SortField.dateAdded => 'Date added',
  };
}

/// Active sort configuration.
class SortSpec {
  const SortSpec(this.field, {this.ascending = true});

  final SortField field;
  final bool ascending;

  int compare(Song a, Song b) {
    var result = switch (field) {
      SortField.title => _fold(a.title).compareTo(_fold(b.title)),
      SortField.artist => _fold(a.artist).compareTo(_fold(b.artist)),
      SortField.album => _fold(a.album ?? '').compareTo(_fold(b.album ?? '')),
      SortField.duration => (a.duration ?? Duration.zero).compareTo(
        b.duration ?? Duration.zero,
      ),
      SortField.dateAdded =>
        (a.dateModified?.millisecondsSinceEpoch ?? 0).compareTo(
          b.dateModified?.millisecondsSinceEpoch ?? 0,
        ),
    };
    if (result == 0) result = _fold(a.path).compareTo(_fold(b.path));
    return ascending ? result : -result;
  }

  static String _fold(String value) => value.toLowerCase();
}
