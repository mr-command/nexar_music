import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/models.dart';
import '../services/providers.dart';
import '../services/utils.dart';
import 'design_system.dart';

/// Reusable album-art widget with graceful fallback.
///
/// Artwork bytes are loaded lazily through [artworkProvider] (background
/// isolate + LRU memory cache), so scrolling stays smooth even in huge
/// libraries and the decoded bitmap is downsampled to the rendered size.
class AlbumArt extends ConsumerWidget {
  const AlbumArt({
    super.key,
    required this.song,
    this.size = 48,
    this.radius = 12,
  });

  final Song song;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designProvider);
    final artwork = ref.watch(artworkProvider(song.path)).value;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: artwork != null && artwork.isNotEmpty
            ? Image.memory(
                key: ValueKey(song.path),
                artwork,
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                // Decode at display resolution — keeps memory per tile tiny.
                cacheWidth:
                    (size * MediaQuery.devicePixelRatioOf(context)).round(),
                errorBuilder: (_, _, _) => _placeholder(design),
              )
            : _placeholder(design),
      ),
    );
  }

  Widget _placeholder(DesignSystem design) => Container(
        color: design.controlBackground,
        alignment: Alignment.center,
        child: Icon(
          Icons.music_note_rounded,
          color: design.textSecondary,
          size: size * 0.45,
        ),
      );
}

/// A single row in the library list.
class SongTile extends ConsumerWidget {
  const SongTile({
    super.key,
    required this.queue,
    required this.index,
  });

  /// The visible (filtered) queue the tile belongs to — used as playback queue.
  final List<Song> queue;
  final int index;

  void _onTap(WidgetRef ref, Song song, bool isCurrent) {
    final audio = ref.read(audioServiceProvider);
    if (isCurrent) {
      audio.togglePlayPause();
    } else {
      audio.playQueue(queue, startIndex: index);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designProvider);
    final song = queue[index];
    final currentPath = ref.watch(
      currentSongProvider.select((song) => song?.path),
    );
    final isCurrent = song.path == currentPath;
    final isPlaying = ref.watch(isPlayingProvider).value ?? false;
    final isFavorite = ref.watch(
      favoritesProvider.select((favorites) => favorites.contains(song.path)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Material(
        borderOnForeground: false,
        color: isCurrent ? design.accent.withAlpha(28) : design.surfaceColor.withAlpha(20),
        
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          
          borderRadius: BorderRadius.circular(18),
          onTap: () => _onTap(ref, song, isCurrent),
          // Diagnostics: reveals where this entry physically lives, so
          // real on-disk copies are distinguishable from scan bugs.
          onLongPress: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: design.menuColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text('File location', style: design.titleStyle),
              content: Text(song.path,
                  style: design.subtitleStyle.copyWith(fontSize: 11)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close', style: design.subtitleStyle),
                ),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                AlbumArt(song: song),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: design.titleStyle.copyWith(
                          color:
                              isCurrent ? design.accent : design.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${song.artist}  ·  ${formatDuration(song.duration)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: design.subtitleStyle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                if (isCurrent)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      isPlaying
                          ? Icons.graphic_eq_rounded
                          : Icons.pause_circle_outline_rounded,
                      color: design.accent,
                      size: 20,
                    ),
                  )
                else
                  IconButton(
                    tooltip: 'Favorite',
                    onPressed: () =>
                        ref.read(favoritesProvider.notifier).toggle(song.path),
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite ? design.accent : design.textSecondary,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Raw art bytes when callers need them directly (kept for symmetry/tests).
Future<Uint8List?> loadArtworkBytes(WidgetRef ref, String path) {
  return ref.read(artworkProvider(path).future);
}
