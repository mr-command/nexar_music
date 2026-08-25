import 'dart:io';

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

/// Cross-platform user music directory.
///
/// Fixes the old bug where `Platform.environment['HOME']!` crashed on Windows
/// (Windows has no HOME variable).
Directory? musicDirectory() {
  final env = Platform.environment;
  final home = env['HOME'] ?? env['USERPROFILE'];
  if (home == null || home.isEmpty) return null;
  return Directory('$home/Music');
}

String musicDirectoryLabel() => musicDirectory()?.path ?? '~/Music';

/// Scans the music directory recursively and returns sorted file paths.
///
/// Returns an empty list when the directory does not exist — the old code
/// returned the fake path `'list is empty'`, which later crashed playback.
Future<List<String>> scanAudioFiles() async {
  final root = musicDirectory();
  if (root == null || !root.existsSync()) return [];
  try {
    final paths = await root
        .list(recursive: true, followLinks: false)
        .where((entity) => entity is File)
        .cast<File>()
        .where(
          (file) => audioExtensions.contains(
            extensionOf(file.path).toLowerCase(),
          ),
        )
        .map((file) => file.path)
        .toList();
    paths.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return paths;
  } catch (_) {
    // Corrupted or unreadable directory: treat as empty instead of crashing.
    return [];
  }
}

String extensionOf(String path) {
  final dot = path.lastIndexOf('.');
  final slash = path.lastIndexOf('/');
  if (dot <= slash || dot == -1) return '';
  return path.substring(dot);
}

/// Turns a raw filename into a human-friendly track name.
String fallbackTrackName(String path) {
  var name = extensionOf(path).isNotEmpty
      ? path.substring(
          path.lastIndexOf('/') + 1,
          path.length - extensionOf(path).length,
        )
      : path.substring(path.lastIndexOf('/') + 1);
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
