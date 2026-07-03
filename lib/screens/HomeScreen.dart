import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nexar_app/components/neuContainer.dart';
import 'package:nexar_app/services/utils/helpers.dart';


class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  @override
void initState() {
  super.initState();
}

  Widget build(BuildContext context) {
    final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
    // final Animation<double> animation;
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
                    width: 320,
                    height: 175,
                    child: neuContainer(Container(
                      width: 320,
                      height: 175,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Container(
                              //   width: 50,
                              //   height: 50,
                              //   child: IconButton(
                              //     style: IconButton.styleFrom(fixedSize: Size(100, 100)),
                              //     onPressed: () {
                              //     MusicService().play();
                              //   }, icon: Icon(Icons.play_arrow_rounded)),
                              // ),
                              
                            ],
                          ),
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
                    
                     width: MediaQuery.widthOf(context) * 0.9,
                     height: MediaQuery.heightOf(context) * 0.5,
                     child: ListView.builder(
                      itemCount: musics.length,
                      itemBuilder: (context, index) {
                        final tags = readMetadata(File(musics[index]), getImage: true);
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
                                borderRadius: BorderRadiusGeometry.circular(15),
                                child: Image.memory(
                                  width: 85,
                                  height: 85,
                                  tags.pictures.first.bytes
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
                                  Icon(Icons.play_arrow_rounded),
                                  Icon(Icons.arrow_forward_ios_rounded),
                                ],
                              )


                            ],
                          ),
                        ));
                        } catch (e) {
                          1+1;
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