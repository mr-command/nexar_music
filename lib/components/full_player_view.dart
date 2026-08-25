import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/providers.dart';
import 'design_system.dart';
import 'player_bar.dart';

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

    if (song == null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_off_rounded,
                size: 48, color: design.textSecondary),
            const SizedBox(height: 12),
            Text(
              'Nothing playing',
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

    final artSize = compact ? 260.0 : 300.0;

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: song.artwork != null
            ? Image.memory(
                song.artwork!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => _placeholderArt(design),
              )
            : _placeholderArt(design),
      ),
    );

    return SingleChildScrollView(
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
          Text(
            song.artist,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: design.subtitleStyle.copyWith(fontSize: 13.5),
          ),
          const SizedBox(height: 18),
          const SeekBar(withLabels: true),
          const SizedBox(height: 6),
          TransportControls(
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

  Widget _placeholderArt(DesignSystem design) => Container(
        color: design.controlBackground,
        alignment: Alignment.center,
        child: Icon(
          Icons.album_rounded,
          size: 96,
          color: design.textSecondary,
        ),
      );
}
