import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexar_app/components/liquidglass/liquidContainer.dart';
import 'package:nexar_app/components/neumorphism/neuContainer.dart';
import 'package:nexar_app/services/providers/providers.dart';


abstract class DesignSystem {

  Widget AppContainer({
    required Widget child,
    required BuildContext context,
  });

  Widget AppTile({
    required Widget child,
  });


  // Widget AppTitle({
  //   required Widget child,
  // });


}


class NeumorphismDesign implements DesignSystem{
  @override
  Widget AppContainer({required Widget child,required BuildContext context}) {  
    // TODO: implement AppContainer
    return neuContainer(child);
  }

  @override
  Widget AppTile({required Widget child}) {
    // TODO: implement AppTile
    return neuHorizenListViewTile(child);
  }

}



class LiquidglassDesign implements DesignSystem{
  @override
  Widget AppContainer({required Widget child,required BuildContext context}) {  
    // TODO: implement AppContainer
    return liquidContaner(child,context);
  }

  @override
  Widget AppTile({required Widget child}) {
    // TODO: implement AppTile
    return neuHorizenListViewTile(child);
  }

}
































