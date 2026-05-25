import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:liquid_glass_bridge/liquid_glass_bridge.dart';
import 'package:nexar_app/components/neuContainer.dart';
import 'package:nexar_app/logic/audio.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  @override
  Widget build(BuildContext context) {
    final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
    // final Animation<double> animation;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: background,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            neuContainer(Text("Nexar",style: TextStyle(fontFamily: "tahoma",fontWeight: FontWeight.bold),)),
            // neuContainer(Text("N",style: TextStyle(fontFamily: "tahoma",fontWeight: FontWeight.bold,fontSize: 25),))
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
                      child: IconButton(onPressed: () {
                        MusicService().play();
                      }, icon: Icon(Icons.play_arrow_rounded)),
                    )),
                  )
                ],
              ),

              // playLists section
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(left: 25),
                    child: Row(
                      children: [
                        Text("playLists",style: TextStyle(fontFamily: "tahoma",fontSize: 18,fontWeight: FontWeight.bold),),
                      ],
                    ),
                  ),
                  Container(
                    width: 350,
                    height: 220,
                    padding: EdgeInsets.all(10),
                    alignment: Alignment(0, 0),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      // border: Border.all(),

                    ),
                    child: AnimatedList(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.all(5),
                      key: _listKey,
                      initialItemCount: 5,
                      scrollCacheExtent: ScrollCacheExtent.viewport(3),
                      itemBuilder: (context, index, animation) => Container(
                        margin: EdgeInsets.only(right: 7.5,left: 7.5),
                        width: 180,height: 220,
                        child: neuHorizenListViewTile(Container(
                          padding: EdgeInsets.all(10),
                          width: 180,height: 220,
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(15)
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadiusGeometry.circular(20),
                                    child: Image.file(
                                      File(
                                      "../../Downloads/pictures/habib.jpeg"
                                      ),
                                      width: 120,
                                      height: 120,
                                      filterQuality: FilterQuality.high,
                                      
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [

                                  Text("Habib",style: TextStyle(fontFamily: "tahoma",fontSize: 18,fontWeight: FontWeight.bold),)
                                ],
                              )
                            ],
                          ),
                        ))),
                      
                    ),
                  ),
                ],
              ),

              // music list section
              Row(
                children: [
                  Column(
                    children: [

                    ],
                  )
                ],
              )
            ],
          ),
      ),
    );
  }
}