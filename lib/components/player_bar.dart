import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nexar_app/services/models.dart';

import '../screens/now_playing_sheet.dart';
import '../services/providers.dart';
import 'song_tile.dart';

/// Transport controls shared by the mini bar, side panel and full player.
class TransportControls extends ConsumerWidget {
  const TransportControls({
    super.key,
    this.size = 24,
    this.playSize = 56,
    this.showExtras = true,
    required this.song,
  });

  final double size;
  final double playSize;

  /// Whether shuffle/repeat buttons are included.
  final bool showExtras;
  final Song song;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designProvider);
    final audio = ref.read(audioServiceProvider);
    final isPlaying = ref.watch(isPlayingProvider).value ?? false;
    final loopMode =
        ref.watch(loopStateProvider).value ?? PlaylistMode.none;
    final isFavorite = ref.watch(
      favoritesProvider.select((favorites) => favorites.contains(song.path)),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        if (showExtras)
          SizedBox(),
        if (showExtras)
          _ToggleIcon(
            active: ref.watch(shuffleStateProvider).value ?? false,
            onToggle: () {
              final enabled =
                  !(ref.read(shuffleStateProvider).value ?? false);
              audio.setShuffle(enabled);
            },
            icon: Icons.shuffle_rounded,
            size: size,
            activeTooltip: 'Shuffle on',
            inactiveTooltip: 'Shuffle off',
          ),
        IconButton(
          tooltip: 'Previous',
          onPressed: audio.previous,
          icon: Icon(Icons.skip_previous_rounded, size: size + 6),
          color: design.textPrimary,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Material(
            color: design.accent,
            borderRadius: BorderRadius.circular(playSize),
            child: InkWell(
              borderRadius: BorderRadius.circular(playSize),
              onTap: audio.togglePlayPause,
              child: SizedBox(
                width: playSize,
                height: playSize,
                child: Icon(
                  isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: playSize * 0.6,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next',
          onPressed: audio.next,
          icon: Icon(Icons.skip_next_rounded, size: size + 6),
          color: design.textPrimary,
        ),

        if (showExtras)
          _ToggleIcon(
            active: loopMode != PlaylistMode.none,
            onToggle: () {
              // Cycle: off -> repeat all -> repeat one -> off.
              final next = switch (loopMode) {
                PlaylistMode.none => PlaylistMode.loop,
                PlaylistMode.loop => PlaylistMode.single,
                PlaylistMode.single => PlaylistMode.none,
              };
              audio.setLoop(next);
            },
            icon: loopMode == PlaylistMode.single
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            size: size,
            activeTooltip:
                loopMode == PlaylistMode.single ? 'Repeat one' : 'Repeat all',
            inactiveTooltip: 'Repeat off',
          ),

        if(showExtras)
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
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite ? design.accent : design.textSecondary,
                    
                    size: 25,
                  ),
                ),
            ),
            ], 
          ),
      ],
    );
  }
}

class _ToggleIcon extends ConsumerWidget {
  const _ToggleIcon({
    required this.active,
    required this.onToggle,
    required this.icon,
    required this.size,
    required this.activeTooltip,
    required this.inactiveTooltip,
  });

  final bool active;
  final VoidCallback onToggle;
  final IconData icon;
  final double size;
  final String activeTooltip;
  final String inactiveTooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designProvider);
    return IconButton(
      tooltip: active ? activeTooltip : inactiveTooltip,
      onPressed: onToggle,
      icon: Icon(icon, size: size),
      color: active ? design.accent : design.textSecondary,
    );
  }
}

/// Seekable progress bar with optional time labels.
class SeekBar extends ConsumerWidget {
  const SeekBar({super.key, this.withLabels = false});

  final bool withLabels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designProvider);
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final duration = ref.watch(durationProvider).value ?? Duration.zero;
    final audio = ref.read(audioServiceProvider);

    return ProgressBar(
      progress: position,
      total: duration,
      onSeek: audio.seek,
      barHeight: withLabels ? 5 : 3,
      baseBarColor:
          design.hasBackdropImage ? Colors.white24 : design.dividerColor,
      progressBarColor: design.accent,
      bufferedBarColor:
          design.hasBackdropImage ? Colors.white38 : design.dividerColor,
      thumbColor: design.accent,
      thumbRadius: withLabels ? 7 : 0,
      barCapShape: BarCapShape.round,
      timeLabelLocation: withLabels
          ? TimeLabelLocation.below
          : TimeLabelLocation.none,
      timeLabelTextStyle:
          design.subtitleStyle.copyWith(fontSize: 11),
    );
  }
}

/// Compact persistent player shown at the bottom of the window.
/// Its width is fully constrained by its parent (fixes the old overflow).
class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  void _openFullPlayer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NowPlayingSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designProvider);
    final song = ref.watch(currentSongProvider);

    if (song == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: design.hasBackdropImage
            ? null
            : design.surfaceColor,
        ),
        
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SeekBar(),
            InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => _openFullPlayer(context),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 10, 12),
                child: Row(
                  children: [
                    AlbumArt(song: song, size: 44, radius: 10),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: design.titleStyle,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: design.subtitleStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TransportControls(
                      size: 20,
                      playSize: 42,
                      showExtras: false,
                      song: song,
                    ),
                    IconButton(
                      tooltip: 'Open player',
                      onPressed: () => _openFullPlayer(context),
                      icon: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: design.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
