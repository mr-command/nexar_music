/// A track discovered on one of the online music sources.
class RemoteTrack {
  const RemoteTrack({
    required this.title,
    required this.artist,
    required this.pageUrl,
    required this.audioUrl,
    required this.source,
    this.artworkUrl,
  });

  final String title;
  final String artist;
  final String pageUrl;
  final String audioUrl;
  final String source;
  final String? artworkUrl;

  /// Stable identity used for dedupe and download-state lookups.
  String get id => audioUrl.isNotEmpty ? audioUrl : pageUrl;
}

/// Combined response from every configured source.
class RemoteSearchResult {
  const RemoteSearchResult({
    this.tracks = const <RemoteTrack>[],
    this.errors = const <String>[],
  });

  final List<RemoteTrack> tracks;

  /// Per-source failures. Results from healthy sources are still returned.
  final List<String> errors;

  bool get isEmpty => tracks.isEmpty;
}
