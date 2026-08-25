import 'package:media_kit/media_kit.dart';

import 'models.dart';

/// Thin, predictable wrapper around the media_kit [Player].
///
/// Playback state is never cached here: the UI reads it from the player's
/// streams (see providers). This fixes the old bug where a manually-toggled
/// `isplayinProvider` drifted out of sync with the real player.
class AudioService {
  AudioService(this._player);

  final Player _player;

  /// Opens [queue] and starts at [startIndex].
  Future<void> playQueue(List<Song> queue, {int startIndex = 0}) async {
    if (queue.isEmpty) return;
    final index = startIndex.clamp(0, queue.length - 1);
    await _player.open(
      Playlist(
        [for (final song in queue) Media(song.path)],
        index: index,
      ),
    );
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
  Future<void> previous() {
    if (_player.state.position > const Duration(seconds: 3)) {
      return _player.seek(Duration.zero);
    }
    return _player.previous();
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setShuffle(bool enabled) => _player.setShuffle(enabled);

  Future<void> setLoop(bool enabled) =>
      _player.setPlaylistMode(enabled ? PlaylistMode.loop : PlaylistMode.none);
}
