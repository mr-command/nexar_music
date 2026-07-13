import 'package:media_kit/media_kit.dart';
import 'package:nexar_app/services/DataBase/models.dart';


class AudioServices {
  AudioServices(this.player);
  bool is_shuffle = false;
  final Player player;

  List<String> _medias = [];
  
  Future<void> loadPlayList(List<String> medias,int index) async {
    _medias = medias;
    await player.open(
      Playlist(
        medias.map((e) => Media(e),).toList(),
        index: index,

      )
    );
  }
  Future<void> loadPlayable(Song song) async {
    await player.open(
      Media(
        song.path,
        extras: {
          'song':song
        }
        
      )
    );
  }



  Future<void> pauseMusic() async {
    await player.pause();
  }
  Future<void> conMusic() async {
    await player.play();
  }

  Future<void> nextMusic() async {
    await player.next();
  }

  Future<void> preMusic() async {
    await player.previous();
  }


  Future<void> shuffleMusic() async {
    
    await player.setShuffle(!is_shuffle);
  }


  Future<void> repeatMusic() async {
    
    await player.setPlaylistMode(PlaylistMode.loop);
  }


}

