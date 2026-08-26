import 'package:media_kit/media_kit.dart';

import 'audio_handler.dart';
import 'models.dart';

/// Thin, predictable wrapper around the media_kit [Player] plus the
/// background [NexarAudioHandler].
///
/// Playback state is never cached here: the UI reads it from the player's
/// streams (see providers). This fixes the old bug where a manually-toggled
/// `isplayinProvider` drifted out of sync with the real player.
class AudioService {
  AudioService(this._player, this._handler);

  final Player _player;
  final NexarAudioHandler _handler;

  /// Opens [queue] and starts at [startIndex]. The handler mirrors the queue
  /// into the media session, which drives the lock-screen/notification UI.
  Future<void> playQueue(List<Song> queue, {int startIndex = 0}) async {
    if (queue.isEmpty) return;
    await _handler.loadQueue(queue, startIndex: startIndex);
  }

  Future<void> togglePlayPause() {
    if (_player.state.playing) {
      return _player.pause();
    }
    return _player.play();
  }

  Future<void> next() => _player.next();

  /// Standard UX: restart current track when more than 3s in,
  /// otherwise jump to the previous one.
  Future<void> previous() =>
      _player.state.position > const Duration(seconds: 3)
          ? _player.seek(Duration.zero)
          : _player.previous();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setShuffle(bool enabled) => _player.setShuffle(enabled);

  Future<void> setLoop(bool enabled) =>
      _player.setPlaylistMode(enabled ? PlaylistMode.loop : PlaylistMode.none);
}
