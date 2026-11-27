import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/remote_track.dart';

/// Scrapes the configured catalog sites for a search term.
///
/// Each source is parsed independently: one broken layout or network error
/// never hides results from the other source.
class RemoteMusicService {
  RemoteMusicService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _requestTimeout = Duration(seconds: 20);
  static const int _maxTracksPerSource = 24;

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,'
        'image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'fa-IR,fa;q=0.9,en;q=0.8',
  };

  /// NicMusic sometimes labels a post by genre instead of artist; those are
  /// not useful as artist names.
  static const Set<String> _genericArtists = {
    'جدید',
    'شاد',
    'غمگین',
    'عاشقانه',
    'ایرانی',
    'خارجی',
    'رپ',
    'پاپ',
    'سنتی',
    'ریمیکس',
    'موزیک',
    'آهنگ',
    'اهنگ',
    'گلچین',
    'میکس',
    'تک آهنگ',
  };

  Future<RemoteSearchResult> search(String query) async {
    final term = query.trim();
    if (term.isEmpty) return const RemoteSearchResult();

    final responses = await Future.wait([
      _searchRemixBaz(term),
      _searchNicMusic(term),
    ]);

    // Interleave the two catalogs so results from both sites stay visible
    // instead of one source burying the other.
    final tracks = <RemoteTrack>[];
    final seen = <String>{};
    final errors = <String>[];
    var index = 0;

    for (final response in responses) {
      errors.addAll(response.errors);
    }

    while (true) {
      var added = false;
      for (final response in responses) {
        if (index >= response.tracks.length) continue;
        final track = response.tracks[index];
        if (seen.add(track.id)) tracks.add(track);
        added = true;
      }
      if (!added) break;
      index++;
    }

    return RemoteSearchResult(tracks: tracks, errors: errors);
  }

  void dispose() => _client.close();

  Future<_SourceResult> _searchRemixBaz(String query) async {
    const source = 'RemixBaz';
    const baseUrl = 'https://remiixbaz.com/';
    final uri = Uri.https('remiixbaz.com', '/', {'s': query});

    try {
      final document = await _loadDocument(uri, referer: baseUrl);
      final tracks = <RemoteTrack>[];

      for (final article in document.querySelectorAll('article.posts')) {
        if (tracks.length >= _maxTracksPerSource) break;

        final link =
            article.querySelector('header h2 a') ??
            article.querySelector('header h1 a');
        final audioUrl = _audioUrl(article.querySelector('audio'), baseUrl);
        if (link == null || audioUrl == null) continue;

        final rawTitle = _text(link.attributes['title']) ?? _text(link.text);
        final pageUrl = _absolute(link.attributes['href'], baseUrl);
        if (rawTitle == null || pageUrl == null) continue;

        final metadata = _metadataFor(
          rawTitle,
          article: article,
          audioUrl: audioUrl,
          fallbackTitle: 'Remix',
          useFromArtist: true,
        );

        tracks.add(
          RemoteTrack(
            title: metadata.title,
            artist: metadata.artist,
            pageUrl: pageUrl,
            audioUrl: audioUrl,
            source: source,
            artworkUrl: _imageUrl(article, baseUrl),
          ),
        );
      }

      return _SourceResult(tracks: tracks);
    } catch (error) {
      return _SourceResult(errors: ['$source: ${_readableError(error)}']);
    }
  }

  Future<_SourceResult> _searchNicMusic(String query) async {
    const source = 'NicMusic';
    const baseUrl = 'https://nicmusic.net/';
    final uri = Uri.https('nicmusic.net', '/', {'s': query});

    try {
      final document = await _loadDocument(uri, referer: baseUrl);
      final tracks = <RemoteTrack>[];

      for (final article in document.querySelectorAll(
        'main .nic_main article',
      )) {
        if (tracks.length >= _maxTracksPerSource) break;

        final link =
            article.querySelector('header h1 a') ??
            article.querySelector('header h2 a');
        final audioUrl = _audioUrl(article.querySelector('audio'), baseUrl);
        if (link == null || audioUrl == null) continue;

        final rawTitle = _text(link.attributes['title']) ?? _text(link.text);
        final pageUrl = _absolute(link.attributes['href'], baseUrl);
        if (rawTitle == null || pageUrl == null) continue;

        final metadata = _metadataFor(
          rawTitle,
          article: article,
          audioUrl: audioUrl,
          fallbackTitle: 'Track',
        );

        tracks.add(
          RemoteTrack(
            title: metadata.title,
            artist: metadata.artist,
            pageUrl: pageUrl,
            audioUrl: audioUrl,
            source: source,
            artworkUrl: _imageUrl(article, baseUrl),
          ),
        );
      }

      return _SourceResult(tracks: tracks);
    } catch (error) {
      return _SourceResult(errors: ['$source: ${_readableError(error)}']);
    }
  }

  Future<Document> _loadDocument(Uri uri, {required String referer}) async {
    final response = await _client
        .get(uri, headers: {..._headers, 'Referer': referer})
        .timeout(_requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'Request failed with HTTP ${response.statusCode}',
        uri,
      );
    }

    return html_parser.parse(
      utf8.decode(response.bodyBytes, allowMalformed: true),
    );
  }

  String? _audioUrl(Element? audio, String baseUrl) {
    if (audio == null) return null;
    final direct = _text(audio.attributes['src']);
    if (direct != null) return _absolute(direct, baseUrl);
    final source = audio.querySelector('source');
    final nested = _text(source?.attributes['src']);
    return nested == null ? null : _absolute(nested, baseUrl);
  }

  String? _imageUrl(Element article, String baseUrl) {
    final image = article.querySelector('img');
    if (image == null) return null;

    for (final attribute in const [
      'data-src',
      'data-lazy-src',
      'data-original',
      'src',
    ]) {
      final value = _text(image.attributes[attribute]);
      if (value == null || value.startsWith('data:')) continue;
      return _absolute(value, baseUrl);
    }
    return null;
  }

  String? _absolute(String? value, String baseUrl) {
    final raw = _text(value);
    if (raw == null) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    if (uri.hasScheme) return uri.toString();
    return Uri.parse(baseUrl).resolveUri(uri).toString();
  }

  String? _text(String? value) {
    final trimmed = value?.replaceAll(RegExp(r'\s+'), ' ').trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// Pulls "artist – title" metadata out of the raw article title, with a
  /// little help from the markup and the audio file name when the title alone
  /// is not enough (mostly NicMusic album-style titles).
  _TrackMetadata _metadataFor(
    String rawTitle, {
    required Element article,
    required String audioUrl,
    required String fallbackTitle,
    bool useFromArtist = false,
  }) {
    var title = rawTitle.replaceAll(RegExp(r'\s+'), ' ').trim();
    String? artist = _articleArtist(article);

    title = title.replaceFirst(
      RegExp(r'^(?:دانلود|Download)\s+', caseSensitive: false),
      '',
    );
    title = title.replaceFirst(
      RegExp(r'^(?:آهنگ|اهنگ|ریمیکس|موزیک|آلبوم|ترک)\s+', caseSensitive: false),
      '',
    );

    final named = RegExp(
      r'^(.*?)\s+(?:به\s*نام|بنام)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(title);
    if (named != null) {
      artist ??= _text(named.group(1));
      title = named.group(2) ?? title;
    } else if (useFromArtist) {
      final fromArtist = RegExp(
        r'^(.*?)\s+از\s+(.+)$',
        caseSensitive: false,
      ).firstMatch(title);
      if (fromArtist != null) {
        final left = _text(fromArtist.group(1));
        final right = _text(fromArtist.group(2));
        if (left != null && right != null) {
          title = left;
          artist ??= right;
        }
      }
    }

    artist ??= _artistFromAudioUrl(audioUrl);

    if (artist != null && artist.isNotEmpty) {
      title = title.replaceFirst(
        RegExp(
          '^${RegExp.escape(artist)}\\s*[-–—:]*\\s*',
          caseSensitive: false,
        ),
        '',
      );
    }

    title = _stripTitleNoise(title);

    return _TrackMetadata(
      title: title.isEmpty ? fallbackTitle : title,
      artist: artist ?? 'Unknown Artist',
    );
  }

  String? _articleArtist(Element article) {
    // RemixBaz embeds "کاری از <strong>دیجی ...</strong>" / "به نام ..."
    for (final strong in article.querySelectorAll('.the_content strong')) {
      final text = _text(strong.text);
      if (text == null) continue;
      final match = RegExp(
        r'(?:ریمیکس|آهنگ|اهنگ|موزیک)\s+(.+?)\s+به\s*نام',
        caseSensitive: false,
      ).firstMatch(text);
      final artist = _text(match?.group(1));
      if (artist != null) return artist;
    }

    // NicMusic lists the artist in a meta line like "دانلود آهنگ بنیامین".
    for (final span in article.querySelectorAll('header span')) {
      final text = _text(span.text);
      if (text == null) continue;
      final match = RegExp(
        r'^(?:دانلود\s+)?(?:آهنگ|اهنگ|موزیک|ریمیکس)\s+(.+)$',
        caseSensitive: false,
      ).firstMatch(text);
      final artist = _text(match?.group(1));
      if (artist != null && !_genericArtists.contains(artist)) return artist;
    }

    return null;
  }

  String? _artistFromAudioUrl(String audioUrl) {
    final fileName = Uri.tryParse(audioUrl)?.pathSegments.last;
    if (fileName == null) return null;
    final base = fileName.replaceFirst(RegExp(r'\.[a-zA-Z0-9]{2,5}$'), '');
    final parts = base.split(' - ');
    if (parts.length < 2) return null;
    return _text(parts.first);
  }

  String _stripTitleNoise(String input) {
    var title = input;

    title = title.replaceAll(RegExp(r'\s*MP3\s*$', caseSensitive: false), ' ');
    title = title.replaceAll(
      RegExp(r'\s*\((?:با\s*)?کیفیت[^)]*\)', caseSensitive: false),
      ' ',
    );
    title = title.replaceAll(
      RegExp(r'\s*\([^)]*متن[^)]*\)', caseSensitive: false),
      ' ',
    );
    title = title.replaceAll(
      RegExp(r'\s*/\s*(?:نسخه اصلی|کیفیت[^/]*)\s*$', caseSensitive: false),
      ' ',
    );
    title = title.replaceAll(
      RegExp(r'\s*[-–—]\s*(?:نسخه اصلی|کیفیت[^/]*)\s*$', caseSensitive: false),
      ' ',
    );
    title = title.replaceAll(RegExp(r'^[«"“\s]+|[»"”\s]+$'), '');

    return title.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _readableError(Object error) {
    if (error is http.ClientException) return error.message;
    if (error is FormatException) return 'unexpected response format';
    return error.toString();
  }
}

class _SourceResult {
  const _SourceResult({
    this.tracks = const <RemoteTrack>[],
    this.errors = const <String>[],
  });

  final List<RemoteTrack> tracks;
  final List<String> errors;
}

class _TrackMetadata {
  const _TrackMetadata({required this.title, required this.artist});

  final String title;
  final String artist;
}
