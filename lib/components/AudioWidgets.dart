import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nexar_app/components/liquidglass/liquid_buttons.dart';
import 'package:nexar_app/components/liquidglass/liquid_proccesbar.dart';
import 'package:nexar_app/services/Audio/AudioServices.dart';
import 'package:nexar_app/services/utils/helpers.dart';
import 'text_styles.dart';

Widget currentPlayingMusic(context,tag,Player player,audio,WidgetRef ref){

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
                    tag.metadata.title.toString().length > 20
                    ?Text(tag.metadata.title.toString().substring(0,20),style: secondryHeaderTextStyle,)
                    :Text(tag.metadata.title.toString().substring(0,tag.metadata.title.toString().length),style: secondryHeaderTextStyle,),
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

                  liquidproccesbar(player)

              ],
            ),


            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                liquidPreviousButton(player, audio,ref),
                liquidPauseButton(player, audio),
                liquidNextButton(player, audio, ref)
                
              ],
            )
      ],
    ),
  );
}