import 'package:media_kit/media_kit.dart';
import 'package:nexar_app/services/DataBase/models.dart';
import 'AudioServices.dart';


int preindex = 0;


Future<void> toggleMusicState(
  AudioServices audio,
  Player player,
  List<String> songs,
  int index
) async {
  
  try {
    if (!player.state.playing) {
    preindex = index;
    await audio.loadPlayList(songs,index);
    

  } else {

    await audio.pauseMusic();
    if(preindex != index){
      await audio.loadPlayList(songs,index);
    }
    
  }
  } catch (e) {
    1+1;
  }
}
