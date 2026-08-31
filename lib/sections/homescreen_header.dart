// ---------------------------------------------------------------------------
// Header (search + filters + theme switcher)
// ---------------------------------------------------------------------------

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexar_app/features/library/viewmodel/lib_providers.dart';
import 'package:nexar_app/sections/homescreen_header_widgets.dart';
import 'package:nexar_app/services/providers.dart';

class Header extends ConsumerStatefulWidget {
  const Header({super.key, required this.compact, required this.songCount});

  final bool compact;
  final int songCount;

  @override
  ConsumerState<Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<Header> {
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
    final appStyle = ref.watch(themeProvider);
    final scanActive = ref.watch(
      libraryControllerProvider.select((state) => state.isBusy),
    );

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
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: Colors.white,
                ),
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
              if (scanActive)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: design.accent,
                    ),
                  ),
                ),
              IconButton.filledTonal(
                tooltip: 'Refresh library',
                onPressed: () =>
                    ref.read(libraryControllerProvider.notifier).refresh(),
                style: IconButton.styleFrom(
                  backgroundColor: design.controlBackground,
                ),
                icon: Icon(Icons.refresh_rounded, color: design.textPrimary),
              ),
              const SizedBox(width: 8),
              SortMenu(design: design),
              ThemeMenu(design: design,appStyle: appStyle,)
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
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: design.textSecondary,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: design.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Shuffle all',
                onPressed: songCount == 0
                    ? null
                    : () => ref
                          .read(audioServiceProvider)
                          .playQueue(
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
              filterChip(
                'All music',
                !favoritesOnly,
                () => ref.read(favoritesOnlyProvider.notifier).state = false,
                ref,
              ),
              const SizedBox(width: 8),
              filterChip(
                'Favorites',
                favoritesOnly,
                () => ref.read(favoritesOnlyProvider.notifier).state = true,
                ref,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
