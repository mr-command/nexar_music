import 'package:flutter/material.dart';
import 'package:app_color_parser/app_color_parser.dart';
Color background = HexColorExtension.fromHex('#ECF0F3');
Color dark_shadow = HexColorExtension.fromHex('#D1D9E6');

Widget neuContainer(dynamic child){
  return Container(
    padding: EdgeInsets.only(left:10 , right: 10,top: 5,bottom: 5),
    alignment: Alignment(0, 0),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          offset: Offset(-5, -5),
          blurRadius: 5,
          spreadRadius: 1,
          color:HexColorExtension.fromHex('#FFFFFF') ,
         
        ),
        BoxShadow(
          offset: Offset(5, 5),
          blurRadius: 5,
          spreadRadius: 1,
          color: dark_shadow
        ),
      ],
      gradient: LinearGradient(colors: [dark_shadow,HexColorExtension.fromHex('#ffffff')],begin: AlignmentGeometry.directional(-1.5, -1.5))
    ),

    child: child,
  );
}


Widget neuHorizenListViewTile(dynamic child){
  return Container(
    padding: EdgeInsets.only(left:10 , right: 10,top: 5,bottom: 5),
    alignment: Alignment(0, 0),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
      gradient: LinearGradient(colors: [dark_shadow,HexColorExtension.fromHex('#ffffff')],begin: AlignmentGeometry.directional(-1.5, -1.5))
    ),

    child: child,
  );
}


