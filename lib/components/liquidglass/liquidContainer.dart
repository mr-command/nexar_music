import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:liquid_glass_bridge/liquid_glass_bridge.dart';

Widget liquidContaner(dynamic child){
  return Container(
    
    child: LiquidGlassSurface(
      
      child: child),
  );
}