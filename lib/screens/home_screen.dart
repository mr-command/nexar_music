import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:nexar_app/features/library/viewmodel/lib_providers.dart';
import 'package:nexar_app/features/library/views/pages/home_screen.dart';
import 'package:nexar_app/features/library/views/pages/playlist_screen.dart';
import 'package:nexar_app/features/search/views/search_screem.dart';
import 'package:nexar_app/features/settings/views/settings_screen.dart';
import 'package:nexar_app/sections/sidenav.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../sections/homescreen_header.dart';
import '../components/full_player_view.dart';
import '../components/player_bar.dart';
import '../components/song_tile.dart';
import '../services/models.dart';
import '../services/providers.dart';
import '../services/utils.dart';


class NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor =
        Theme.of(context).colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: selected
                ? color.withAlpha(25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: Icon(
                  icon,
                  size: 21,
                  color: selected ? color : inactiveColor,
                ),
              ),

              const SizedBox(height: 3),

              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: selected ? 10 : 9,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: selected ? color : inactiveColor,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designProvider);
    int index = ref.watch(navbarindexProvider);
    return Scaffold(
      backgroundColor: design.scaffoldBackground,
      body: Stack(
        children: [


        Positioned.fill(
          child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: offsetAnimation,
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(index),
            child: switch (index) {
              0 => const SongScreen(),
              1 => const SearchScreen(),
              2 => const PlaylistScreen(),
              3 => const SettingsScreen(),
              _ => const SongScreen(),
            },
          ),
        ),
      ),


          Positioned(
            // top: 400,
            bottom: 70,
            left: 10,
            right: 10,
            child: MiniPlayerBar()),
          

          Positioned(
          left: 20,
          right: 20,
          bottom: 12,
          child: SafeArea(
            top: false,
            child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: design.menuColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: NavItem(
                    icon: LucideIcons.house,
                    label: 'Home',
                    selected: index == 0,
                    color: design.accent,
                    onTap: () {
                      ref.read(navbarindexProvider.notifier).state = 0;
                    },
                  ),
                ),

                Expanded(
                  child: NavItem(
                    icon: LucideIcons.search,
                    label: 'Search',
                    selected: index == 1,
                    color: design.accent,
                    onTap: () {
                      ref.read(navbarindexProvider.notifier).state = 1;
                    },
                  ),
                ),

                Expanded(
                  child: NavItem(
                    icon: LucideIcons.list,
                    label: 'Playlist',
                    selected: index == 2,
                    color: design.accent,
                    onTap: () {
                      ref.read(navbarindexProvider.notifier).state = 2;
                    },
                  ),
                ),

                Expanded(
                  child: NavItem(
                    icon: LucideIcons.settings,
                    label: 'settings',
                    selected: index == 3,
                    color: design.accent,
                    onTap: () {
                      ref.read(navbarindexProvider.notifier).state = 3;
                    },
                  ),
                ),
              ],
            ),
          )
          ),
        ),
        ],
      ),

    );
  }
}


