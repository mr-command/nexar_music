import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    final sheet = Container(
      // margin: EdgeInsets.fromLTRB(
      //   wide ? (size.width - 520) / 2 : 0,
      //   wide ? 24 : 0,
      //   wide ? (size.width - 520) / 2 : 0,
      //   0,
      // ),
      constraints: BoxConstraints(maxHeight: size.height * 0.92),
      decoration: BoxDecoration(
        color: design.menuColor,
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
                IconButton(
                  tooltip: 'Close',
                  onPressed: Navigator.of(context).pop,
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: design.textPrimary),
                ),
                Text('NOW PLAYING', style: design.subtitleStyle),
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
