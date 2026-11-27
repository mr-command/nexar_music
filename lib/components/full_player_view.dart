import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexar_app/services/utils.dart';
import 'package:solar_icons/solar_icons.dart';

import '../services/providers.dart';
import 'player_bar.dart';
import 'song_tile.dart';

/// Full-featured now-playing view. Used inside the modal sheet (mobile) and
/// the right-hand panel (desktop).
class FullPlayerView extends ConsumerWidget {
  const FullPlayerView({super.key, this.compact = false});

  /// Compact mode fits inside the bottom sheet.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designProvider);
    final song = ref.watch(currentSongProvider);

    final isPlaying = ref.watch(isPlayingProvider).value ?? false;
    final coverColor = ref.watch(coverColorProvider).value;


    if (song == null) {

      return Padding(
        
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(SolarIconsBold.muted,
                size: 48, color: design.textSecondary),
            const SizedBox(height: 12),
            Text(
              'playing right now',
              style: design.headingStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick a track from your library',
              style: design.subtitleStyle,
            ),
          ],
        ),
      );
    }
  final isFavorite = ref.watch(
      favoritesProvider.select(
      (favorites) => favorites.contains(song.path),
    ),
  );
    final artSize = compact ? 260.0 : 300.0;
    final playerTint = Color.alphaBlend(
      design.accent.withAlpha(30),
      design.menuColor,
    );

    final artwork = Container(
      width: artSize,
      height: artSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: AlbumArt(song: song, size: artSize, radius: 28),
    );

    return Container(
      decoration: BoxDecoration(
        
        borderRadius: BorderRadius.vertical(top:Radius.circular(24)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [playerTint, design.menuColor],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          artwork,
          const SizedBox(height: 26),
          Text(
            song.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: design.headingStyle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 30,),
              Text(
                song.artist,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: design.subtitleStyle.copyWith(fontSize: 13.5),
              ),
              Stack(
                children: [
                  Positioned(
                  child: IconButton(
                    style: IconButton.styleFrom(
                      fixedSize: Size(40, 40)
                    ),
                      tooltip: 'Favorite',
                      onPressed: () =>
                          ref.read(favoritesProvider.notifier).toggle(song.path),
                      icon: Icon(
                        isFavorite
                            ? SolarIconsBold.heartAngle
                            : SolarIconsOutline.heartAngle,
                        color: isFavorite
                            ?  design.accent
                            : design.textSecondary,
                        
                        size: 25,
                      ),
                    ),
                ),
                ], 
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SeekBar(withLabels: true),
          const SizedBox(height: 6),
          TransportControls(
            song: song,
            size: 28,
            playSize: 64,
          ),
          if (!isPlaying && !compact) ...[
            const SizedBox(height: 10),
            Text(
              'Paused',
              style: design.subtitleStyle,
            ),
          ],
        ],
      ),
    );
  }
}
