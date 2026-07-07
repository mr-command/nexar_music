import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nexar_app/services/Audio/audio_logic.dart';
import 'package:nexar_app/services/utils/helpers.dart';

Widget currentPlayingMusic(context,tag,Player player,audio){

  return Container(
    padding: EdgeInsets.all(15),
    // width: MediaQuery.widthOf(context) * 0.4,
    // height: 500,

    decoration: BoxDecoration(
      color: Colors.transparent,
    ),

    child: Column(
      children: [
        tag == null
            ? const Center(child: Text("No music"))
            : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(20),
                  child: tag.metadata.pictures.isNotEmpty 
                  ? Image.memory(tag.metadata.pictures.first.bytes,width: 100,height: 100,)
                  : Container(width: 85,height: 85,color: Colors.grey,child: const Icon(Icons.music_note),
                  )
                                      ),
                Text(betterTitle(tag.metadata.title) ?? "",style: TextStyle(fontFamily: "tahoma",fontSize: 20,fontWeight: FontWeight.bold),),
                SizedBox()
                // Text(betterTitle(tag.metadata.artist) ?? "",style: TextStyle(fontFamily: "tahoma",fontSize: 16,fontWeight: FontWeight.bold)),
              ],
            ),

            Row(
              children: [

                  StreamBuilder<Duration>(
                    stream: player.stream.position,
                    builder: (context, positionSnapshot) {
                      return StreamBuilder<Duration>(
                        stream: player.stream.duration,
                        builder: (context, durationSnapshot) {
                          return Container(
                            width: 500,
                            height: 50,
                            child: ProgressBar(
                              baseBarColor: Colors.white,
                              progressBarColor: Colors.grey,

                              progress: positionSnapshot.data ?? Duration.zero,
                              total: durationSnapshot.data ?? Duration.zero,
                              onSeek: player.seek,
                            ),
                          );
                        },
                      );
                    },
                  ),

              ],
            ),


            Row(
              children: [
                IconButton(
                  onPressed: (){
                    audio.preMusic();
                  },
                   icon: Icon(Icons.skip_previous)
                ),
                IconButton(
                  onPressed: (){
                    if(player.state.playing){
                      audio.pauseMusic();
                    } else {
                      audio.conMusic();
                    }
                  },
                   icon: Icon(Icons.pause)
                ),
                IconButton(
                  onPressed: (){
                    audio.nextMusic();
                  },
                   icon: Icon(Icons.skip_next)
                ),
                
              ],
            )
      ],
    ),
  );
}