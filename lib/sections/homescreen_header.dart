// ---------------------------------------------------------------------------
// Header (search + filters + theme switcher)
// ---------------------------------------------------------------------------

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nexar_app/components/animated_widgets.dart';
import 'package:nexar_app/features/library/viewmodel/lib_providers.dart';
import 'package:nexar_app/sections/homescreen_header_widgets.dart';
import 'package:nexar_app/services/providers.dart';
import 'package:solar_icons/solar_icons.dart';

class Header extends ConsumerStatefulWidget {
  const Header({super.key, required this.compact, required this.songCount, required this.pageName});

  final bool compact;
  final int songCount;
  final String pageName;

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
    final pageName = widget.pageName;
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
            // spacing: 20,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              
              // const SizedBox(width: 12),
              Text(pageName, style: design.headingStyle,),
              // SizedBox(width: 20,),
              // SizedBox(width: MediaQuery.widthOf(context) * 0.1),

              // Expanded(
              //   child: Text(
              //     '$songCount tracks',
              //     style: design.subtitleStyle,
              //     maxLines: 1,
              //     overflow: TextOverflow.ellipsis,
              //   ),
              // ),
              // if (scanActive)
              //   Padding(
              //     padding: const EdgeInsets.only(right: 4),
              //     child: SizedBox.square(
              //       dimension: 16,
              //       child: CircularProgressIndicator(
              //         strokeWidth: 2,
              //         color: design.accent,
              //       ),
              //     ),
              //   ),
              // IconButton.filledTonal(
              //   tooltip: 'Refresh library',
              //   onPressed: () =>
              //       ref.read(libraryControllerProvider.notifier).refresh(),
              //   style: IconButton.styleFrom(
              //     backgroundColor: design.controlBackground,
              //   ),
              //   icon: Icon(Icons.refresh_rounded, color: design.textPrimary),
              // ),
              // const SizedBox(width: 8),
              // SortMenu(design: design),
              // const SizedBox(width: 8,),
              // ThemeMenu(design: design,appStyle: appStyle,)
              AnimatedSearchBar(
                hintText: 'Search songs...',
                width: MediaQuery.widthOf(context) * 0.48,
                
                onChanged: (query) {
                  ref.read(searchQueryProvider.notifier).state = query;
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Everything You Love , in one place",style: design.subtitleStyle,),
              PopupMenuButton<AppStyle>(
                icon: const Icon(Icons.more_vert),

                onSelected: (value) {
                  switch (value) {
                    case AppStyle.light:
                      ref.read(themeProvider.notifier).state = AppStyle.light;
                      break;

                    case AppStyle.dark:
                      ref.read(themeProvider.notifier).state = AppStyle.dark;
                      break;
                  }
                },

                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: AppStyle.light,
                    child: Row(
                      children: [
                        Icon(
                          appStyle == AppStyle.light
                              ? Icons.check_rounded
                              : Icons.radio_button_off_outlined,
                          size: 18,
                          color: appStyle == AppStyle.light
                              ? design.accent
                              : design.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Light',
                          style: TextStyle(
                            color: appStyle == AppStyle.light
                                ? design.accent
                                : design.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  PopupMenuItem(
                    value: AppStyle.dark,
                    child: Row(
                      children: [
                        Icon(
                          appStyle == AppStyle.dark
                              ? Icons.check_rounded
                              : Icons.radio_button_off_outlined,
                          size: 18,
                          color: appStyle == AppStyle.dark
                              ? design.accent
                              : design.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Dark',
                          style: TextStyle(
                            color: appStyle == AppStyle.dark
                                ? design.accent
                                : design.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )

            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              // Expanded(
              //   child: TextField(
              //     controller: _searchController,
              //     onChanged: (value) =>
              //         ref.read(searchQueryProvider.notifier).state = value,
              //     style: design.titleStyle,
              //     cursorColor: design.accent,
              //     decoration: InputDecoration(
              //       hintText: 'Search songs or anything else IDK ...',
              //       hintStyle: design.subtitleStyle,
              //       prefixIcon: Icon(
              //         LucideIcons.search,
              //         color: design.textSecondary,
              //       ),
              //       isDense: true,
              //       filled: true,
              //       fillColor: design.surfaceColor,
              //       border: OutlineInputBorder(
              //         borderRadius: BorderRadius.circular(16),
              //         borderSide: BorderSide.none,
              //       ),
              //       contentPadding: const EdgeInsets.symmetric(vertical: 14),
              //     ),
              //   ),
              // ),

              const SizedBox(width: 10),
              // IconButton.filledTonal(
              //   tooltip: 'Random Song',
              //   onPressed: songCount == 0
              //       ? null
              //       : () => ref
              //             .read(audioServiceProvider)
              //             .playQueue(
              //               ref.read(visibleSongsProvider),
              //               startIndex: Random().nextInt(songCount),
              //             ),
              //   style: IconButton.styleFrom(
              //     backgroundColor: design.controlBackground,
              //   ),
              //   icon: Icon(Icons.shuffle_rounded, color: design.textPrimary),
              // ),




            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              filterChip(
                'All musics',
                !favoritesOnly,
                () => ref.read(favoritesOnlyProvider.notifier).state = false,
                ref,
                SolarIconsBold.musicNotes
              ),
              const SizedBox(width: 8),
              filterChip(
                'Favorites',
                favoritesOnly,
                () => ref.read(favoritesOnlyProvider.notifier).state = true,
                ref,
                SolarIconsBold.heart
              ),
            ],
          ),
        ],
      ),
    );
  }
}
