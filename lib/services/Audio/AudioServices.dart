import 'package:media_kit/media_kit.dart';


class AudioServices {
  AudioServices(this.player);

  final Player player;

  Future<void> playMusic(String path) async {
    await player.open(
      Media(path),
      play: true,
    );
  }

  Future<void> pauseMusic() async {
    await player.pause();
  }


  Future<void> preMusic() async {
    await player.previous();
  }

}