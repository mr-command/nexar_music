import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:liquid_glass_bridge/liquid_glass_bridge.dart';

Widget liquidContaner(dynamic child,BuildContext context){
  return Center(
    
    child: Container(
      width: MediaQuery.widthOf(context) * 0.3,
       height: MediaQuery.heightOf(context) * 0.6,
      child: LiquidGlassSurface(
        blurSigma: 8,
        // elevation: 100,
        style: LiquidGlassStyle(blurSigma: 10,tintOpacity: 0.1,borderRadius: BorderRadius.circular(25)),
        
        
        tintColor: Colors.white,
        quality: LiquidGlassQuality.low,
        borderRadius: BorderRadius.circular(25),
        mode: LiquidGlassMode.auto,
        highlightStrength: 0.2,

        child: child
      ),
    ),
  );
}