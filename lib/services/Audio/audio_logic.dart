import 'package:media_kit/media_kit.dart';
import 'AudioServices.dart';

Future<void> toggleMusicState(
  AudioServices audio,
  Player player,
  String path,
  int index
) async {
  
  try {
    if (!player.state.playing) {

    await audio.playMusic(path);
    

  } 
  else if(player.state.completed){
    await audio.playMusic(path);
  }
  else {

    await audio.pauseMusic();
    await audio.playMusic(path);
    
  }
  } catch (e) {
    1+1;
  }
}
