import 'package:flutter/material.dart';
// import 'package:liquid_glass_bridge/liquid_glass_bridge.dart';

/// Pluggable design system: every screen renders through this interface so
/// the whole app can switch between Neumorphism and Liquid Glass styles.
abstract class DesignSystem {
  const DesignSystem();

  String get label;

  /// Whether a full-screen backdrop image is painted behind the content.
  bool get hasBackdropImage;

  Color get scaffoldBackground;
  Color get surfaceColor;
  Color get controlBackground;
  Color get accent;

  /// Foreground (icons/labels) placed directly on top of [accent].
  Color get onAccent;
  Color get textPrimary;
  Color get textSecondary;
  Color get dividerColor;

  /// Opaque color for popup menus/sheets overlaid on top of everything.
  Color get menuColor;

  TextStyle get headingStyle;
  TextStyle get titleStyle;
  TextStyle get subtitleStyle;

  /// Large frosted container used for sidebars, bars and sheets.
  Widget AppContainer({
    required Widget child,
    double radius = 24,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    Color? color,
  });
}

// ---------------------------------------------------------------------------
// Neumorphism
// ---------------------------------------------------------------------------

class NeumorphismDesign extends DesignSystem {
  const NeumorphismDesign();

  /// Raw accent as an int, shared with the native notification styling.
  static const int accentValue = 0xFF3F6B4A;

  static const _bg = Color(0xFFF3EFE6);
  static const _surface = Color(0xFFFCFAF4);
  static const _control = Color(0xFFEAE4D7);
  static const _accent = Color(0xFF3F6B4A);
  static const _onAccent = Color(0xFFFFF9F0);
  static const _textPrimary = Color(0xFF232B25);
  static const _textSecondary = Color(0xFF5C665D);

  @override
  String get label => 'Neumorphism';

  @override
  bool get hasBackdropImage => false;

  @override
  Color get scaffoldBackground => _bg;

  @override
  Color get surfaceColor => _surface;

  @override
  Color get controlBackground => _control;

  @override
  Color get accent => const Color.fromARGB(255, 63, 107, 103);

  @override
  Color get onAccent => _onAccent;

  @override
  Color get textPrimary => _textPrimary;

  @override
  Color get textSecondary => _textSecondary;

  @override
  Color get dividerColor => const Color(0xFFD6D1C2);

  @override
  Color get menuColor => _surface;

  @override
  TextStyle get headingStyle => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: _textPrimary,
        fontFamily: "tahoma"
      );

  @override
  TextStyle get titleStyle => const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      );

  @override
  TextStyle get subtitleStyle => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _textSecondary,
      );

  @override
  Widget AppContainer({
    required Widget child,
    double radius = 24,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    Color? color,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? _surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40AFA78F),
            offset: Offset(5, 5),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Color(0xD9FFFFFF),
            offset: Offset(-5, -5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

// ---------------------------------------------------------------------------
// Liquid Glass
// ---------------------------------------------------------------------------

class LiquidGlassDesign extends DesignSystem {
  const LiquidGlassDesign();

  @override
  String get label => 'Liquid Glass';

  @override
  bool get hasBackdropImage => false;

  @override
  Color get scaffoldBackground => const Color(0xFF0F1310);

  @override
  Color get surfaceColor => const Color(0xFF1A201B);

  @override
  Color get controlBackground => const Color(0xFF242B25);

  @override
  Color get accent => const Color.fromARGB(255, 143, 205, 207);

  @override
  Color get onAccent => const Color(0xFF102015);

  @override
  Color get textPrimary => const Color(0xFFF2F4ED);

  @override
  Color get textSecondary => const Color(0xFFA9B3A8);

  @override
  Color get dividerColor => const Color(0xFF333C34);

  @override
  Color get menuColor => const Color(0xFF151A16);

  @override
  TextStyle get headingStyle => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Color(0xFFF2F4ED),
      );

  @override
  TextStyle get titleStyle => const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF2F4ED),
      );

  @override
  TextStyle get subtitleStyle => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFFA9B3A8),
      );

  @override
  Widget AppContainer({
    required Widget child,
    double radius = 24,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    Color? color,
  }) {
    return BackdropFilter(
      filterConfig: ImageFilterConfig.blur(
        sigmaX: 12,
        sigmaY: 12
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: (color ?? surfaceColor).withAlpha(235),
        ),
        
        child: child,
      ),
    );
  }
}
