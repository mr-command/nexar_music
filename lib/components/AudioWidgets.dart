import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nexar_app/components/design/models.dart';
import 'package:nexar_app/components/liquidglass/liquid_buttons.dart';
import 'package:nexar_app/components/liquidglass/liquid_proccesbar.dart';

Widget currentPlayingMusic(context,tag,Player player,audio,WidgetRef ref,DesignSystem design){

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
                    design.AppTitle(child:"No Music is Playing"),
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
                    ?design.AppTitle(child:tag.metadata.title.toString().substring(0,20))
                    :design.AppTitle(child:tag.metadata.title.toString().substring(0,tag.metadata.title.toString().length)),
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
                liquidPauseButton(player, audio,ref),
                liquidNextButton(player, audio, ref)
                
              ],
            )
      ],
    ),
  );
}