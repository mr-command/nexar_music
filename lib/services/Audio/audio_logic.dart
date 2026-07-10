import 'package:media_kit/media_kit.dart';
import 'package:nexar_app/services/DataBase/models.dart';
import 'AudioServices.dart';

Future<void> toggleMusicState(
  AudioServices audio,
  Player player,
  List<String> songs,
  int index
) async {
  
  try {
    if (!player.state.playing) {

    await audio.repeatMusic();
    

  } else {

    await audio.pauseMusic();
    await audio.loadPlayList(songs);
    
  }
  } catch (e) {
    1+1;
  }
}
