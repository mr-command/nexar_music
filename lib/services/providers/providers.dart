import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nexar_app/components/design/models.dart';
import 'package:nexar_app/services/Audio/AudioServices.dart';
import 'package:nexar_app/services/DataBase/models.dart';


enum AppStyle{
  liquid,
  neumorphism
}


final playerProvider = Provider<Player>((ref) {
  final player = Player();

  ref.onDispose(player.dispose);

  return player;
});

final audioServiceProvider = Provider<AudioServices>((ref) {
  return AudioServices(ref.watch(playerProvider));
});


final nowPlaying = StateProvider<Song?>(
  (ref) => null
);

final themeProvider = StateProvider(
  (ref) => AppStyle.liquid
);

final designSYstemProvider = Provider(
  (ref){
    final style = ref.watch(themeProvider);

    switch(style){
      case AppStyle.liquid:
        return LiquidglassDesign();

      case AppStyle.neumorphism:
        return NeumorphismDesign();
    }
  }
);
final currentSongProvider = Provider<Song?>((ref) {
  return null;
});


final isplayinProvider = StateProvider<bool>(
  (ref){
    final player = ref.watch(playerProvider);
    return player.state.playing;
  }
);


