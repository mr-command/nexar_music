import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:media_kit/media_kit.dart';

import 'artwork_repository.dart';
import 'models.dart';

/// Bridges the media_kit [Player] to Android's MediaSession.
///
/// Running inside a mediaPlayback foreground service keeps the process from
/// being throttled while the screen is off — which was the cause of the
/// crackling/distorted audio after locking the phone — and automatically
/// produces the system media notification with play/pause / next / previous
/// controls, colored to match the app accent and album artwork.
class NexarAudioHandler extends BaseAudioHandler {
  NexarAudioHandler(this._player) {
    _player.stream.playing.listen((_) => _sync());
    _player.stream.playlist.listen((_) => _onPlaylistChanged());
    _player.stream.duration.listen((_) => _refreshDuration());
  }

  final Player _player;

  /// Snapshot of the queue passed to the last playQueue call, used to map
  /// engine paths back to full song metadata for the notification.
  List<Song> _songs = const <Song>[];

  static Future<NexarAudioHandler> init(Player player) {
    return AudioService.init(
      builder: () => NexarAudioHandler(player),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'app.nexar.playback',
        androidNotificationChannelName: 'Nexar music player',
        androidNotificationChannelDescription:
            'Shows what is currently playing in Nexar.',
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidShowNotificationBadge: true,
        artDownscaleHeight: 512,
        artDownscaleWidth: 512,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Queue loading
  // -------------------------------------------------------------------------

  Future<void> loadQueue(List<Song> queue, {int startIndex = 0}) async {
    if (queue.isEmpty) return;
    _songs = List.unmodifiable(queue);
    await _player.open(
      Playlist(
        [for (final song in queue) Media(song.path)],
        index: startIndex.clamp(0, queue.length - 1),
      ),
    );
  }

  void _onPlaylistChanged() {
    _publishQueue();
    _sync();
    _publishMediaItem();
  }

  void _publishQueue() {
    final playlist = _player.state.playlist;
    queue.add([
      for (final song in _songs)
        _buildItem(song, artUri: ArtworkRepository.cachedArtworkUri(song.path)),
    ]);
    playbackState.add(_state(queueIndex: playlist.index));
  }

  Song? get _currentSong {
    final playlist = _player.state.playlist;
    final index = playlist.index;
    if (index < 0 || index >= playlist.medias.length) return null;
    final uri = playlist.medias[index].uri;
    for (final song in _songs) {
      if (song.path == uri) return song;
    }
    return null;
  }

  void _publishMediaItem() {
    final song = _currentSong;
    if (song == null) {
      mediaItem.add(null);
      return;
    }
    final item = _buildItem(song,
        artUri: ArtworkRepository.cachedArtworkUri(song.path));
    mediaItem.add(item);
    // Cover art might not be materialized yet; attach it as soon as ready so
    // the notification updates from generic icon → real album art.
    unawaited(_attachArtwork(item, song.path));
  }

  Future<void> _attachArtwork(MediaItem base, String path) async {
    try {
      final uri =
          await ArtworkRepository.artworkFile(path).timeout(const Duration(
        seconds: 4,
      ));
      final stillCurrent = identical(mediaItem.valueOrNull ?? base, base);
      if (uri != null && stillCurrent) {
        mediaItem.add(base.copyWith(artUri: uri));
      }
    } catch (_) {
      // Notification simply stays without art — nothing else to do.
    }
  }

  void _refreshDuration() {
    final song = _currentSong;
    final real = _player.state.duration;
    if (song == null || real <= Duration.zero) return;
    final current = mediaItem.valueOrNull;
    if (current == null || current.id != song.path) return;
    if (current.duration != null && current.duration != Duration.zero) return;
    mediaItem.add(current.copyWith(duration: real));
  }

  // -------------------------------------------------------------------------
  // Playback state -> notification / lock screen
  // -------------------------------------------------------------------------

  PlaybackState _state({int? queueIndex}) {
    final playing = _player.state.playing;
    return PlaybackState(
      controls: playing
          ? const [
              MediaControl.skipToPrevious,
              MediaControl.pause,
              MediaControl.skipToNext,
            ]
          : const [
              MediaControl.skipToPrevious,
              MediaControl.play,
              MediaControl.skipToNext,
            ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.ready,
      playing: playing,
      updatePosition: _player.state.position,
      bufferedPosition: _player.state.buffer,
      speed: _player.state.rate,
      queueIndex: queueIndex ?? _player.state.playlist.index,
    );
  }

  void _sync() => playbackState.add(_state());

  // -------------------------------------------------------------------------
  // System / notification actions
  // -------------------------------------------------------------------------

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> skipToNext() => _player.next();

  @override
  Future<void> skipToPrevious() async {
    if (_player.state.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
    } else {
      await _player.previous();
    }
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.pause();
    await super.stop();
  }
}

MediaItem _buildItem(Song song, {Uri? artUri}) {
  return MediaItem(
    id: song.path,
    album: song.album ?? 'Nexar',
    title: song.title,
    artist: song.artist,
    duration: song.duration,
    playable: true,
    artUri: artUri,
  );
}
