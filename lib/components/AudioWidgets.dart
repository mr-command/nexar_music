import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nexar_app/services/utils/helpers.dart';
import 'text_styles.dart';

Widget currentPlayingMusic(context,tag,Player player,audio){

  return Container(
    // padding: EdgeInsets.all(15),
    width: MediaQuery.widthOf(context) * 0.3,
    height: MediaQuery.heightOf(context) * 0.54,

    decoration: BoxDecoration(
      color: Colors.transparent,
    ),

    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        tag == null
            ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("No Music is Playing",style: secondryHeaderTextStyle,),
                    SizedBox(height: 20,),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(30)
                  ),
                  width: 220,height: 220,child: const Icon(Icons.music_note)),
                 
                  
                  ],
                )
              ],
            )
            :Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tag.metadata.title.toString(),style: secondryHeaderTextStyle,),
                    SizedBox(height: 20,),
                    tag.metadata.pictures.isNotEmpty
                    ? ClipRRect(
                      borderRadius: BorderRadiusGeometry.circular(20),
                      child: Image.memory(
                        tag.metadata.pictures.first.bytes,
                        width: 220,
                        height: 220,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(30)
                  ),
                  width: 220,height: 220,child: const Icon(Icons.music_note));
                        },
                      
                      ),
                    )
                    :Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(30)
                  ),
                  width: 220,height: 220,child: const Icon(Icons.music_note)),
                 
                  
                  ],
                )
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                  StreamBuilder<Duration>(
                    stream: player.stream.position,
                    builder: (context, positionSnapshot) {
                      return StreamBuilder<Duration>(
                        stream: player.stream.duration,
                        builder: (context, durationSnapshot) {
                          return Container(
                            width: 300,
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
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