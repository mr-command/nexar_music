import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nexar_app/services/Audio/AudioServices.dart';
import 'package:nexar_app/services/DataBase/models.dart';
import 'package:nexar_app/services/providers/providers.dart';

Widget liquidPauseButton(Player player, AudioServices audio,WidgetRef ref){
  final playing = ref.watch(isplayinProvider);
  return IconButton(

    onPressed: (){
      if(player.state.playing){
        audio.pauseMusic();
      } else {
        audio.conMusic();
      }
    },
    icon: playing
    ? Icon(Icons.pause)
    : Icon(Icons.play_arrow),

    style: IconButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.transparent,
      fixedSize: Size(20, 20)
    ),
    
  );
}

Widget liquidPreviousButton(Player player, AudioServices audio,WidgetRef ref){
  return IconButton(
    onPressed: (){

      audio.preMusic();

      final media = player.state.playlist.medias[player.state.playlist.index - 1];

      final AudioMetadata metadata = readMetadata(File(media.uri),getImage: true);

      ref.read(nowPlaying.notifier).state = Song(id: player.state.playlist.index,path: media.uri,metadata: metadata);
    },
    icon: Icon(Icons.skip_previous_rounded),

    style: IconButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.transparent,
      fixedSize: Size(20, 20)
    ),
    
  );
}

Widget liquidNextButton(Player player, AudioServices audio,WidgetRef ref){
  return IconButton(
    onPressed: (){

      audio.nextMusic();

      final media = player.state.playlist.medias[player.state.playlist.index + 1];
      print(media.uri);
      final AudioMetadata metadata = readMetadata(File(media.uri),getImage: true);

      ref.read(nowPlaying.notifier).state = Song(id: player.state.playlist.index,path: media.uri,metadata: metadata);
    },
    icon: Icon(Icons.skip_next_rounded),

    style: IconButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.transparent,
      fixedSize: Size(20, 20)
    ),
    
  );
}