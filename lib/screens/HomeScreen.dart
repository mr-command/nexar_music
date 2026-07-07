import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexar_app/components/AudioWidgets.dart';
import 'package:nexar_app/components/neuContainer.dart';
import 'package:nexar_app/services/Audio/AudioServices.dart';
import 'package:nexar_app/services/Audio/audio_logic.dart';
import 'package:nexar_app/services/DataBase/models.dart';
import 'package:nexar_app/services/providers/providers.dart';
import 'package:nexar_app/services/utils/helpers.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final player = ref.read(playerProvider);
    final audio = ref.read(audioServiceProvider);
    final currentSong = ref.watch(nowPlaying);
    List<String> musics = getMusicsDirectory();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: background,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            neuContainer(Text("Nexar",style: TextStyle(fontFamily: "tahoma",fontWeight: FontWeight.bold),)),
            
          ],
        ),
      ),
      body: Container(
        color: background,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // current playing music section

              Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(left: 25),
                    child: Row(
                      children: [
                         Text("Playing Right Now",style: TextStyle(fontFamily: "tahoma",fontSize: 18,fontWeight: FontWeight.bold),),

                      ],
                    ),
                  ),
                  SizedBox(height: 10,),
                  Container(
                    width: MediaQuery.widthOf(context) * 0.5,
                    height: MediaQuery.heightOf(context) * 0.4,
                    child: neuContainer(Container(
                      width: MediaQuery.widthOf(context) * 0.5,
                      height: MediaQuery.heightOf(context) * 0.4,
                      child: Column(
                        children: [
                          currentPlayingMusic(context, currentSong,player,audio),
                        ],
                      ),
                    )),
                  )
                ],
              ),

              // playLists section
              // Column(
              //   children: [
              //     Container(
              //       padding: EdgeInsets.only(left: 25),
              //       child: Row(
              //         children: [
              //           Text("P L A Y L I S T S",style: TextStyle(fontFamily: "tahoma",fontSize: 18,fontWeight: FontWeight.bold),),
              //         ],
              //       ),
              //     ),
              //   ]
              //   ),


                // musics list

                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.only(left: 25),
                      child: Text("M U S I C S",style:TextStyle(fontFamily: "tahoma",fontSize: 18,fontWeight: FontWeight.bold)))
                  ],
                ),


                Container(
                    
                     width: MediaQuery.widthOf(context) * 0.85,
                     height: MediaQuery.heightOf(context) * 0.35,
                     child: ListView.builder(
                      itemCount: musics.length,
                      itemBuilder: (context, index) {
                        final tags = readMetadata(File(musics[index]), getImage: true);
                        final song = Song(
                          path: musics[index],
                          metadata: tags,
                        );
                        
                        try {
                          return neuContainer(
                          Container(
                          
                          width: MediaQuery.widthOf(context) * 0.8,
                          height: 100,
                          
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: tags.pictures.isNotEmpty
                                    ? Image.memory(
                                        tags.pictures.first.bytes,
                                        width: 85,
                                        height: 85,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 85,
                                        height: 85,
                                        color: Colors.grey,
                                        child: const Icon(Icons.music_note),
                                      ),
                              ),
                              SizedBox(width: 10,),
                              Text(tags.title.toString(),style:TextStyle(fontFamily: "tahoma",fontSize: 16,fontWeight: FontWeight.bold)),

                                ],
                              ),

                              Text(tags.artist.toString(),style:TextStyle(fontFamily: "tahoma",fontSize: 16,fontWeight: FontWeight.bold),overflow: TextOverflow.ellipsis,),


                              Row(
                                children: [
                                  Icon(Icons.arrow_back_ios_new_rounded),
                                  IconButton(
                                    onPressed: () {
                                      ref.read(nowPlaying.notifier).state = song;
                                      toggleMusicState(audio,player,song.path,index);
                                    },
                                     icon: Icon(Icons.play_arrow)
                                    ),
                                  Icon(Icons.arrow_forward_ios_rounded),
                                ],
                              )


                            ],
                          ),
                        ));
                        } catch (e) {
                          print(e);
                        }
                      },
                    ),
                   )
                ],
              ),
      ),
    );
  }
}

