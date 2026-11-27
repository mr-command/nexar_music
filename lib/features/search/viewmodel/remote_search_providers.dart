import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../library/viewmodel/lib_providers.dart';
import '../models/remote_track.dart';
import '../services/download_service.dart';
import '../services/remote_music_service.dart';

final remoteMusicServiceProvider = Provider<RemoteMusicService>((ref) {
  final service = RemoteMusicService();
  ref.onDispose(service.dispose);
  return service;
});

/// Current text typed into the online search page. Kept alive between tabs so
/// the query (and its results) survive navigation.
final remoteSearchQueryProvider = StateProvider<String>((ref) => '');

/// Live search against every configured online source.
final remoteSearchProvider = FutureProvider.autoDispose
    .family<RemoteSearchResult, String>((ref, query) async {
      final term = query.trim();
      if (term.length < 2) return const RemoteSearchResult();

      return ref.read(remoteMusicServiceProvider).search(term);
    });

final downloadServiceProvider = Provider<DownloadService>((ref) {
  final service = DownloadService();
  ref.onDispose(service.dispose);
  return service;
});

class DownloadStatus {
  const DownloadStatus({
    this.isDownloading = false,
    this.progress,
    this.path,
    this.error,
  });

  final bool isDownloading;
  final double? progress;
  final String? path;
  final String? error;
}

final downloadsProvider =
    StateNotifierProvider<DownloadsController, Map<String, DownloadStatus>>(
      (ref) => DownloadsController(ref),
    );

class DownloadsController extends StateNotifier<Map<String, DownloadStatus>> {
  DownloadsController(this._ref) : super(const {});

  final Ref _ref;

  Future<void> download(RemoteTrack track) async {
    final key = track.id;
    final current = state[key];
    if (current?.isDownloading == true || current?.path != null) return;

    state = {...state, key: const DownloadStatus(isDownloading: true)};

    try {
      final path = await _ref
          .read(downloadServiceProvider)
          .download(
            track,
            onProgress: (received, total) {
              if (!mounted) return;
              state = {
                ...state,
                key: DownloadStatus(
                  isDownloading: true,
                  progress: total != null && total > 0
                      ? (received / total).clamp(0.0, 1.0)
                      : null,
                ),
              };
            },
          );
      if (!mounted) return;

      state = {...state, key: DownloadStatus(progress: 1, path: path)};
      await _ref
          .read(libraryControllerProvider.notifier)
          .addDownloadedSong(path);
    } catch (error) {
      if (!mounted) return;
      state = {...state, key: DownloadStatus(error: '$error')};
    }
  }
}
