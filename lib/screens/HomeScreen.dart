import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexar_app/components/AudioWidgets.dart';
import 'package:nexar_app/components/liquidglass/liquidContainer.dart';
import 'package:nexar_app/components/neumorphism/neuContainer.dart';
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
    final design = ref.watch(designSYstemProvider);


    List<String> musics = getMusicsDirectory();
    // audio.loadPlayList(musics);
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.black,
      //   title: Row(
      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //     children: [
      //       design.AppContainer(child:Text("Nexar",style: TextStyle(fontFamily: "tahoma",fontWeight: FontWeight.bold),),context: context),
            
      //     ],
      //   ),
      // ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/liquid.jpg'),
            fit: BoxFit.cover
          )
        ),
        
        width: double.infinity,
        height: double.infinity,
        child: ListView(
            padding: EdgeInsets.all(20),
            children: [
              // current playing music section

              Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(left: 25),
                    child: Row(
                      children: [
                         design.AppTitle(child: "Playing Right Now",),

                      ],
                    ),
                  ),
                  SizedBox(height: 10,),
                  Container(
                    width: MediaQuery.widthOf(context) * 0.3,
                    height: MediaQuery.heightOf(context) * 0.6,
                    child: design.AppContainer(child:Container(
                      width: MediaQuery.widthOf(context) * 0.3,
                      height: MediaQuery.heightOf(context) * 0.6,
                      child: Column(
                        children: [
                          currentPlayingMusic(context, currentSong,player,audio,ref,design),
                        ],
                      ),
                    ),context:context),
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
              //           Text("P L A Y L I S T S",),
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
                      child: design.AppTitle(child: "M U S I C S"))
                  ],
                ),


                Container(
                    
                     width: MediaQuery.widthOf(context) * 0.85,
                     height: MediaQuery.heightOf(context) * 0.55,
                     child: ListView.builder(
                      itemCount: musics.length,
                      itemBuilder: (context, index) {
                        final currentSong = ref.watch(currentSongProvider);
                        final isCurrentSong = currentSong?.path == musics[index];
                        final tags = readMetadata(File(musics[index]), getImage: true);
                        final song = Song(
                          id: index,
                          path: musics[index],
                          metadata: tags,
                        );
                        
                        
                        
                        try {
                          return design.AppTile(
                          context: context,
                          child : Container(
                          
                          width: MediaQuery.widthOf(context) * 0.8,
                          height: 100,
                          margin: EdgeInsets.all(10),
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
                                        errorBuilder: (context, error, stackTrace) {
                                        return  Container(
                                        width: 85,
                                        height: 85,
                                        color: Colors.grey,
                                        child: const Icon(Icons.music_note),
                                      );
                                        },
                                      )
                                    : Container(
                                        width: 85,
                                        height: 85,
                                        color: Colors.grey,
                                        child: const Icon(Icons.music_note),
                                      ),
                                      
                              ),
                              SizedBox(width: 10,),
                              tags.title != null 
                              ? design.AppTitle(child:tags.title.toString())
                              : design.AppTitle(child:"unknown")

                                ],
                              ),
                              tags.artist != null
                              ? design.AppTitle(child: tags.artist.toString())
                              : design.AppTitle(child:"unknown artist"),

                              Row(
                                children: [
                                  
                                  IconButton(
                                    onPressed: () {
                                      ref.read(nowPlaying.notifier).state = song;
                                      toggleMusicState(audio,player,musics,index);
                                    },
                                     icon: isCurrentSong
                                     ? Icon(Icons.pause,size: 30,color: Colors.white,)
                                     : Icon(Icons.play_arrow,size: 30,color: Colors.white,)
                                    ),
                                  
                                ],
                              )


                            ],
                          ),
                        )
                        );
                        } catch (e) {
                          print(e);
                        }
                      },
                    ),
                   )
                ],
              ),
      ),

      drawer: Drawer(
        
        backgroundColor: Colors.black.withAlpha(120),
        
        child: Column(
          children: [
            TextButton(onPressed: (){
              ref.read(themeProvider.notifier).state = AppStyle.neumorphism;
            }, child: Text("neuMorphism",style: TextStyle(color: Colors.white),)),
            TextButton(onPressed: (){
              ref.read(themeProvider.notifier).state = AppStyle.liquid;
            }, child: Text("liquid glass",style: TextStyle(color: Colors.white)))
          ],
        ),
      ),
    );
  }
}

