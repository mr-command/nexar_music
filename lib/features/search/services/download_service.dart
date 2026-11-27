import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/remote_track.dart';

/// Streams remote tracks to a local folder that the library can index.
class DownloadService {
  DownloadService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

  Future<String> download(
    RemoteTrack track, {
    void Function(int received, int? total)? onProgress,
  }) async {
    final uri = Uri.parse(track.audioUrl);
    final directory = await _downloadDirectory();
    final target = File(p.join(directory.path, _fileNameFor(track, uri)));

    if (await target.exists() && await target.length() > 0) {
      final size = await target.length();
      onProgress?.call(size, size);
      return target.path;
    }

    final partial = File('${target.path}.part');
    final request = http.Request('GET', uri);
    request.headers.addAll({
      'User-Agent': _userAgent,
      'Referer': _originOf(track.pageUrl) ?? _originOf(track.audioUrl) ?? '',
    });

    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Download failed with HTTP ${response.statusCode}',
        uri: uri,
      );
    }

    final total = response.contentLength;
    var received = 0;
    final sink = partial.openWrite();

    try {
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 90),
      )) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.close();
    } catch (_) {
      await sink.close();
      if (await partial.exists()) await partial.delete();
      rethrow;
    }

    if (await target.exists()) await target.delete();
    await partial.rename(target.path);
    return target.path;
  }

  void dispose() => _client.close();

  Future<Directory> _downloadDirectory() async {
    final base =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(base.path, 'Nexar'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  String _fileNameFor(RemoteTrack track, Uri uri) {
    var name = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    if (name.contains('%')) {
      try {
        name = Uri.decodeComponent(name);
      } catch (_) {}
    }

    name = name
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (name.isEmpty) {
      name = '${_slug(track.artist)} - ${_slug(track.title)}';
    }
    if (!RegExp(r'\.[a-zA-Z0-9]{2,5}$').hasMatch(name)) {
      name = '$name.mp3';
    }
    if (name.length > 120) {
      final extension = p.extension(name);
      name = '${name.substring(0, 120 - extension.length)}$extension';
    }
    return name;
  }

  String _slug(String value) {
    final slug = value
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return slug.isEmpty ? 'track' : slug;
  }

  String? _originOf(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    return '${uri.scheme}://${uri.host}/';
  }
}
