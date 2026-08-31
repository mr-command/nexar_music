// ---------------------------------------------------------------------------
// Side navigation (desktop / tablet)
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexar_app/services/providers.dart';
import 'package:nexar_app/services/utils.dart';

class SideNav extends ConsumerWidget {
  const SideNav({super.key, required this.expanded});

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
        mainAxisAlignment: expanded
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: selected ? Colors.white : design.textSecondary,
          ),
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

      return expanded ? item : Tooltip(message: label, child: item);
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: expanded ? 240 : 76,
        child: design.AppContainer(
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
                        colors: [design.accent, design.accent.withAlpha(130)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(height: 10),
                  Center(child: Text('Nexar', style: design.headingStyle)),
                ],
                const SizedBox(height: 22),
                navItem(
                  icon: Icons.library_music_rounded,
                  label: 'All music',
                  selected: !favoritesOnly,
                  onTap: () =>
                      ref.read(favoritesOnlyProvider.notifier).state = false,
                ),
                navItem(
                  icon: Icons.favorite_rounded,
                  label: 'Favorites',
                  selected: favoritesOnly,
                  badge: favoritesCount > 0 ? '$favoritesCount' : null,
                  onTap: () =>
                      ref.read(favoritesOnlyProvider.notifier).state = true,
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
                              value: AppStyle.light,
                              icon: Icon(Icons.layers_rounded, size: 16),
                              label: Text('Soft'),
                            ),
                            ButtonSegment(
                              value: AppStyle.dark,
                              icon: Icon(Icons.water_drop, size: 16),
                              label: Text('liquid'),
                            ),
                          ],
                          selected: {ref.watch(themeProvider)},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) =>
                              ref.read(themeProvider.notifier).state =
                                  selection.first,
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
                  ),

                // _ThemeMenu(design: design),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
