import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';

import '../../../components/design_system.dart';
import '../../../services/providers.dart';
import '../models/remote_track.dart';
import '../viewmodel/remote_search_providers.dart';

class RemoteTrackTile extends ConsumerWidget {
  const RemoteTrackTile({super.key, required this.track});

  final RemoteTrack track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designProvider);
    final status = ref.watch(
      downloadsProvider.select((downloads) => downloads[track.id]),
    );

    final isDownloading = status?.isDownloading == true;
    final isSaved = status?.path != null;
    final hasError = status?.error != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: design.controlBackground,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isDownloading || isSaved
              ? null
              : () => ref.read(downloadsProvider.notifier).download(track),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _Artwork(track: track, design: design),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: design.titleStyle,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${track.artist}  ·  ${track.source}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: design.subtitleStyle.copyWith(fontSize: 12),
                      ),
                      if (hasError) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Download failed — tap retry',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: design.subtitleStyle.copyWith(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _TrailingAction(
                  design: design,
                  isDownloading: isDownloading,
                  isSaved: isSaved,
                  hasError: hasError,
                  progress: status?.progress,
                  onPressed: isDownloading || isSaved
                      ? null
                      : () => ref
                            .read(downloadsProvider.notifier)
                            .download(track),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.track, required this.design});

  final RemoteTrack track;
  final DesignSystem design;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 50,
      height: 50,
      color: design.surfaceColor,
      alignment: Alignment.center,
      child: Icon(
        SolarIconsBold.musicNote,
        size: 22,
        color: design.textSecondary,
      ),
    );

    final artworkUrl = track.artworkUrl;
    final artwork = artworkUrl == null
        ? placeholder
        : Image.network(
            artworkUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => placeholder,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : placeholder,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(width: 50, height: 50, child: artwork),
    );
  }
}

class _TrailingAction extends StatelessWidget {
  const _TrailingAction({
    required this.design,
    required this.isDownloading,
    required this.isSaved,
    required this.hasError,
    required this.progress,
    required this.onPressed,
  });

  final DesignSystem design;
  final bool isDownloading;
  final bool isSaved;
  final bool hasError;
  final double? progress;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (isSaved) {
      return Tooltip(
        message: 'Saved to your library',
        child: Icon(Icons.check_circle_rounded, color: design.accent, size: 26),
      );
    }

    if (isDownloading) {
      return SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 2.5,
          color: design.accent,
          backgroundColor: design.dividerColor,
        ),
      );
    }

    return IconButton(
      tooltip: hasError ? 'Retry download' : 'Download',
      onPressed: onPressed,
      icon: Icon(
        hasError ? Icons.refresh_rounded : Icons.download_rounded,
        color: design.accent,
      ),
    );
  }
}
