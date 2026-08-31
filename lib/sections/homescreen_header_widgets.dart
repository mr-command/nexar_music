import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexar_app/components/design_system.dart';
import 'package:nexar_app/services/providers.dart';
import 'package:nexar_app/services/utils.dart';


Widget filterChip(
  String label,
  bool selected,
  VoidCallback onTap,
  WidgetRef ref
){
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

class ThemeMenu extends ConsumerWidget {
  const ThemeMenu({required this.design,required this.appStyle});

  final DesignSystem design;
  final AppStyle appStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStyle = ref.watch(themeProvider);
    return PopupMenuButton<AppStyle>(
      
      tooltip: 'Appearance',
      surfaceTintColor: design.surfaceColor,
      icon: Icon(Icons.palette_outlined, color: design.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      position: PopupMenuPosition.under,
      color: design.menuColor,
      elevation: 6,
      style: IconButton.styleFrom(backgroundColor: design.controlBackground),
      onSelected: (style) {
        print(style);
        ref.read(themeProvider.notifier).state = style;
      },
      itemBuilder: (context) => [
        
        PopupMenuItem(
          value: AppStyle.light,
          child: Row(
            children: [
              appStyle == AppStyle.light? Icon(Icons.check_rounded,size: 18,
                  color: design.accent) : Icon(Icons.radio_button_off_outlined,size: 18,
                  color: design.textSecondary),
              SizedBox(width: 10,),
              Text('Light',style: TextStyle(color: appStyle == AppStyle.light? design.accent : design.textSecondary,),),
              SizedBox(width: 10,),
               
            ],
          ),
        ),
        PopupMenuItem(
          value: AppStyle.dark,
          child: Row(
            children: [
              appStyle == AppStyle.dark? Icon(Icons.check_rounded,size: 18,
                  color: design.accent) : Icon(Icons.radio_button_off_outlined,size: 18,
                  color: design.textSecondary),
              SizedBox(width: 10,),
              Text('Dark',style: TextStyle(color: appStyle == AppStyle.dark? design.accent : design.textSecondary,),),
              SizedBox(width: 10,),
               
            ],
          ),
        ),
      ],
    );
  }
}

/// Sort selector matching the app's visual language: pill-shaped trigger,
/// rounded frosted menu, accent checkmarks and a direction toggle.
class SortMenu extends ConsumerWidget {
  const SortMenu({super.key, required this.design});

  final DesignSystem design;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(sortProvider);
    return PopupMenuButton<SortField?>(
      tooltip: 'Sort songs',
      color: design.menuColor,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      position: PopupMenuPosition.under,
      onSelected: (field) {
        if (field == null) {
          ref.read(sortProvider.notifier).toggleDirection();
        } else {
          ref.read(sortProvider.notifier).setField(field);
        }
      },
      itemBuilder: (context) => [
        for (final field in SortField.values)
          PopupMenuItem(
            value: field,
            child: Row(
              children: [
                Icon(
                  field == sort.field
                      ? Icons.check_rounded
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color:
                      field == sort.field ? design.accent : design.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    field.label,
                    style: design.titleStyle.copyWith(
                      color: field == sort.field
                          ? design.accent
                          : design.textPrimary,
                    ),
                  ),
                ),
                if (field == sort.field)
                  Icon(
                    sort.ascending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 16,
                    color: design.accent,
                  ),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<SortField?>(
          value: null,
          child: _ReverseOrderRow(),
        ),
      ],
      style: IconButton.styleFrom(backgroundColor: design.controlBackground),
      icon: Icon(Icons.sort_rounded, color: design.textPrimary),
    );
  }
}

class _ReverseOrderRow extends ConsumerWidget {
  const _ReverseOrderRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final design = ref.watch(designProvider);
    return Row(
      children: [
        Icon(Icons.swap_vert_rounded, size: 18, color: design.textSecondary),
        const SizedBox(width: 10),
        Text('Reverse order', style: design.subtitleStyle),
      ],
    );
  }
}
