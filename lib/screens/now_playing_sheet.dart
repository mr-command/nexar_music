import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexar_app/services/utils.dart';

import '../components/full_player_view.dart';
import '../services/providers.dart';

/// Full-screen player, presented as a modal bottom sheet.
class NowPlayingSheet extends ConsumerWidget {
  const NowPlayingSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designProvider);
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 720;
    final coverColor = ref.watch(coverColorProvider).value;
    final sheetTint = Color.alphaBlend(
      (coverColor ?? design.accent).withAlpha(30),
      design.menuColor,
    );
    final sheet = Container(
      // margin: EdgeInsets.fromLTRB(
      //   wide ? (size.width - 520) / 2 : 0,
      //   wide ? 24 : 0,
      //   wide ? (size.width - 520) / 2 : 0,
      //   0,
      // ),
      constraints: BoxConstraints(maxHeight: size.height * 0.92),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sheetTint, design.menuColor],
        ),
        borderRadius: BorderRadius.vertical(
          
          top: Radius.circular(wide ? 32 : 28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Text('Playing', style: design.subtitleStyle),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Flexible(child: FullPlayerView(compact: !wide)),
        ],
      ),
    );

    return sheet;
  }
}
