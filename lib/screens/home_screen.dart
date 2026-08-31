import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexar_app/features/library/viewmodel/lib_providers.dart';
import 'package:nexar_app/sections/sidenav.dart';

import '../sections/homescreen_header.dart';
import '../components/full_player_view.dart';
import '../components/player_bar.dart';
import '../components/song_tile.dart';
import '../services/models.dart';
import '../services/providers.dart';
import '../services/utils.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designProvider);

    return Scaffold(
      backgroundColor: design.scaffoldBackground,
      body: Stack(
        children: [
          if (design.hasBackdropImage)
            Positioned.fill(
              child: Image.asset(
                'assets/images/liquid.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    ColoredBox(color: design.scaffoldBackground),
              ),
            ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final showSideNav = width >= 760;
                final showPanel = width >= 1180;
                final visibleSongs = ref.watch(visibleSongsProvider);

                final content = Column(
                  children: [
                    Header(
                      compact: !showSideNav,
                      songCount: visibleSongs.length,
                    ),
                    Expanded(child: _LibraryView(songs: visibleSongs)),
                  ],
                );

                return CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.space): () =>
                        ref.read(audioServiceProvider).togglePlayPause(),
                  },
                  child: Focus(
                    autofocus: true,
                    child: showSideNav
                        ? Row(
                            children: [
                              SideNav(expanded: showPanel),
                              Expanded(child: content),
                              if (showPanel)
                                SizedBox(
                                  width: 360,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      0,
                                      12,
                                      12,
                                      12,
                                    ),
                                    child: Container(
                                      // radius: 28,
                                      color: design.hasBackdropImage
                                          ? null
                                          : design.surfaceColor,
                                      child: const FullPlayerView(),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : content,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MiniPlayerBar(),
    );
  }
}

// ---------------------------------------------------------------------------
// Library list with all states (loading / error / empty / data)
// ---------------------------------------------------------------------------

class _LibraryView extends ConsumerWidget {
  const _LibraryView({required this.songs});

  final List<Song> songs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designProvider);
    final state = ref.watch(libraryControllerProvider);
    final favoritesOnly = ref.watch(favoritesOnlyProvider);

    if (state.error != null && songs.isEmpty && !state.parsing) {
      return _Message(
        icon: Icons.error_outline_rounded,
        title: 'Could not read your music folder',
        message: '${state.error}',
      );
    }
    if (state.scanning && songs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (songs.isEmpty) {
      if (favoritesOnly) {
        return const _Message(
          icon: Icons.favorite_border_rounded,
          title: 'No favorites yet',
          message: 'Tap the heart on any track to add it to your favorites.',
        );
      }
      return _Message(
        icon: Icons.library_music_rounded,
        title: 'Your library is empty',
        message: 'Add audio files to ${musicDirectoryLabel()} and hit refresh.',
      );
    }

    return Column(
      children: [
        // Slim accent bar while background tags are still streaming in —
        // the list itself is already usable (placeholders fill instantly).
        if (state.parsing)
          SizedBox(
            height: 2,
            child: LinearProgressIndicator(
              color: design.accent,
              backgroundColor: design.dividerColor,
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 110),
            itemCount: songs.length,
            itemBuilder: (context, index) =>
                SongTile(queue: songs, index: index),
          ),
        ),
      ],
    );
  }
}

class _Message extends ConsumerWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: design.textSecondary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: design.headingStyle,
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: design.subtitleStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
