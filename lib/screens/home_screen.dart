import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/design_system.dart';
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
                    _Header(
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
                              _SideNav(expanded: showPanel),
                              Expanded(child: content),
                              if (showPanel)
                                SizedBox(
                                  width: 360,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 12, 12, 12),
                                    child: design.glass(
                                      radius: 28,
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
// Header (search + filters + theme switcher)
// ---------------------------------------------------------------------------

class _Header extends ConsumerStatefulWidget {
  const _Header({required this.compact, required this.songCount});

  final bool compact;
  final int songCount;

  @override
  ConsumerState<_Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<_Header> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final design = ref.watch(designProvider);
    final favoritesOnly = ref.watch(favoritesOnlyProvider);
    final compact = widget.compact;
    final songCount = widget.songCount;

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 24, 16, compact ? 16 : 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [design.accent, design.accent.withAlpha(130)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.graphic_eq_rounded,
                    color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text('Nexar', style: design.headingStyle),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$songCount tracks',
                  style: design.subtitleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // IconButton(
              //   tooltip: 'Refresh library',
              //   onPressed: () => ref.invalidate(libraryProvider),
              //   icon:
              //       Icon(Icons.refresh_rounded, color: design.textSecondary),
              // ),
              // if (compact) _ThemeMenu(design: design),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      ref.read(searchQueryProvider.notifier).state = value,
                  style: design.titleStyle,
                  cursorColor: design.accent,
                  decoration: InputDecoration(
                    hintText: 'Search songs or anything else IDK ...',
                    hintStyle: design.subtitleStyle,
                    prefixIcon: Icon(Icons.search_rounded,
                        color: design.textSecondary),
                    isDense: true,
                    filled: true,
                    fillColor: design.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Shuffle all',
                onPressed: songCount == 0
                    ? null
                    : () => ref.read(audioServiceProvider).playQueue(
                          ref.read(visibleSongsProvider),
                          startIndex: Random().nextInt(songCount),
                        ),
                style: IconButton.styleFrom(
                  backgroundColor: design.controlBackground,
                ),
                icon: Icon(Icons.shuffle_rounded, color: design.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _FilterChip(
                label: 'All music',
                selected: !favoritesOnly,
                onTap: () =>
                    ref.read(favoritesOnlyProvider.notifier).state = false,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Favorites',
                selected: favoritesOnly,
                onTap: () =>
                    ref.read(favoritesOnlyProvider.notifier).state = true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends ConsumerWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designProvider);
    return Material(
      color: selected ? design.accent : design.surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: design.subtitleStyle.copyWith(
              color: selected ? Colors.white : design.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// class _ThemeMenu extends ConsumerWidget {
//   const _ThemeMenu({required this.design});

//   final DesignSystem design;

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return PopupMenuButton<AppStyle>(
//       tooltip: 'Appearance',
//       icon: Icon(Icons.palette_outlined, color: design.textPrimary),
//       onSelected: (style) => ref.read(themeProvider.notifier).state = style,
//       itemBuilder: (context) => [
//         PopupMenuItem(
//           value: AppStyle.neumorphism,
//           child: Text('Neumorphism'),
//         ),
//         PopupMenuItem(
//           value: AppStyle.liquid,
//           child: Text('Liquid Glass'),
//         ),
//       ],
//     );
//   }
// }

// ---------------------------------------------------------------------------
// Side navigation (desktop / tablet)
// ---------------------------------------------------------------------------

class _SideNav extends ConsumerWidget {
  const _SideNav({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designProvider);
    final favoritesOnly = ref.watch(favoritesOnlyProvider);
    final favoritesCount = ref.watch(favoritesProvider).length;

    Widget navItem({
      required IconData icon,
      required String label,
      required bool selected,
      String? badge,
      required VoidCallback onTap,
    }) {
      final row = Row(
        mainAxisAlignment:
            expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 20,
              color: selected ? Colors.white : design.textSecondary),
          if (expanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: design.titleStyle.copyWith(
                  color: selected ? Colors.white : design.textPrimary,
                ),
              ),
            ),
            if (badge != null)
              Text(badge, style: design.subtitleStyle.copyWith(fontSize: 11)),
          ],
        ],
      );

      final item = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Material(
          color: selected ? design.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: expanded ? 14 : 10,
                vertical: 12,
              ),
              child: row,
            ),
          ),
        ),
      );

      return expanded
          ? item
          : Tooltip(message: label, child: item);
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: expanded ? 240 : 76,
        child: design.glass(
          radius: 26,
          color: design.hasBackdropImage ? null : design.surfaceColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          design.accent,
                          design.accent.withAlpha(130),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child:
                        const Icon(Icons.graphic_eq_rounded,
                            color: Colors.white),
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Text('Nexar', style: design.headingStyle),
                  ),
                ],
                const SizedBox(height: 22),
                navItem(
                  icon: Icons.library_music_rounded,
                  label: 'All music',
                  selected: !favoritesOnly,
                  onTap: () => ref
                      .read(favoritesOnlyProvider.notifier)
                      .state = false,
                ),
                navItem(
                  icon: Icons.favorite_rounded,
                  label: 'Favorites',
                  selected: favoritesOnly,
                  badge: favoritesCount > 0 ? '$favoritesCount' : null,
                  onTap: () => ref
                      .read(favoritesOnlyProvider.notifier)
                      .state = true,
                ),
                const Spacer(),
                if (expanded)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('APPEARANCE', style: design.subtitleStyle),
                        const SizedBox(height: 8),
                        SegmentedButton<AppStyle>(
                          segments: const [
                            ButtonSegment(
                              value: AppStyle.neumorphism,
                              icon: Icon(Icons.layers_rounded, size: 16),
                              label: Text('Soft'),
                            ),
                            
                          ],
                          selected: {ref.watch(themeProvider)},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) => ref
                              .read(themeProvider.notifier)
                              .state = selection.first,
                          style: SegmentedButton.styleFrom(
                            textStyle: design.subtitleStyle,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          musicDirectoryLabel(),
                          style: design.subtitleStyle.copyWith(fontSize: 10.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                
                
                  // _ThemeMenu(design: design),
              ],
            ),
          ),
        ),
      ),
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
    final library = ref.watch(libraryProvider);
    final favoritesOnly = ref.watch(favoritesOnlyProvider);

    return library.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _Message(
        icon: Icons.error_outline_rounded,
        title: 'Could not read your music folder',
        message: '$error',
      ),
      data: (_) {
        if (songs.isEmpty) {
          if (favoritesOnly) {
            return const _Message(
              icon: Icons.favorite_border_rounded,
              title: 'No favorites yet',
              message:
                  'Tap the heart on any track to add it to your favorites.',
            );
          }
          return _Message(
            icon: Icons.library_music_rounded,
            title: 'Your library is empty',
            message:
                'Add audio files to ${musicDirectoryLabel()} and hit refresh.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 110),
          itemCount: songs.length,
          itemBuilder: (context, index) =>
              SongTile(queue: songs, index: index),
        );
      },
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
            Text(title, textAlign: TextAlign.center, style: design.headingStyle),
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
