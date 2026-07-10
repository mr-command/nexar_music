import 'package:media_kit/media_kit.dart';
import 'package:nexar_app/services/DataBase/models.dart';


class AudioServices {
  AudioServices(this.player);
  bool is_shuffle = false;
  final Player player;

  List<String> _medias = [];
  
  Future<void> loadPlayList(List<String> medias) async {
    _medias = medias;
    await player.open(
      Playlist(
        medias.map((e) => Media(e),).toList()
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


class PlaylistServices {
  final List<Song> songs;
  int _currentIndex = 0;

  PlaylistServices(this.songs);

  Song get current => songs[_currentIndex];

  Song next() {
    if (_currentIndex < songs.length - 1) {
      _currentIndex++;
    }
    return current;
  }

  Song previous() {
    if (_currentIndex > 0) {
      _currentIndex--;
    }
    return current;
  }

  void jumpTo(int index) {
    if (index >= 0 && index < songs.length) {
      _currentIndex = index;
    }
  }

  bool get hasNext => _currentIndex < songs.length - 1;
  bool get hasPrevious => _currentIndex > 0;
}