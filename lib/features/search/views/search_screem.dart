// ---------------------------------------------------------------------------
// SearchScreen (search + filters + theme switcher)
// ---------------------------------------------------------------------------

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nexar_app/features/library/viewmodel/lib_providers.dart';
import 'package:nexar_app/sections/homescreen_header.dart';
import 'package:nexar_app/sections/homescreen_header_widgets.dart';
import 'package:nexar_app/services/providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key,});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
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
    final appStyle = ref.watch(themeProvider);
    final scanActive = ref.watch(
      libraryControllerProvider.select((state) => state.isBusy),
    );
    final width = MediaQuery.widthOf(context);
    final showSideNav = width >= 760;
    final showPanel = width >= 1180;
    final visibleSongs = ref.watch(visibleSongsProvider);

    return Container(
      // padding: EdgeInsetsGeometry.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
              
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
            
          // const SizedBox(height: 14),
          Header(
                compact: !showSideNav,
                songCount: visibleSongs.length,
                pageName: "Search",
              ),
        ],
      ),
    );
  }
}
