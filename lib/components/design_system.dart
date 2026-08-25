import 'package:flutter/material.dart';
import 'package:liquid_glass_bridge/liquid_glass_bridge.dart';

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
  Color get textPrimary;
  Color get textSecondary;
  Color get dividerColor;

  TextStyle get headingStyle;
  TextStyle get titleStyle;
  TextStyle get subtitleStyle;

  /// Large frosted container used for sidebars, bars and sheets.
  Widget glass({
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

  static const _bg = Color(0xFFE9E2F2);
  static const _surface = Color(0xFFF4EFFA);
  static const _control = Color(0xFFEFE8F8);
  static const _accent = Color(0xFF7C3AED);
  static const _textPrimary = Color(0xFF241C33);
  static const _textSecondary = Color(0xFF6F6786);

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
  Color get accent => _accent;

  @override
  Color get textPrimary => _textPrimary;

  @override
  Color get textSecondary => _textSecondary;

  @override
  Color get dividerColor => const Color(0xFFD5CCDF);

  @override
  TextStyle get headingStyle => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: _textPrimary,
      );

  @override
  TextStyle get titleStyle => const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      );

  @override
  TextStyle get subtitleStyle => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _textSecondary,
      );

  @override
  Widget glass({
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
            color: Color(0x40B4A8C8),
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
  bool get hasBackdropImage => true;

  @override
  Color get scaffoldBackground => const Color(0xFF12101C);

  @override
  Color get surfaceColor => Colors.white.withAlpha(36);

  @override
  Color get controlBackground => Colors.white.withAlpha(46);

  @override
  Color get accent => const Color(0xFFFF5C93);

  @override
  Color get textPrimary => Colors.white;

  @override
  Color get textSecondary => Colors.white.withAlpha(166);

  @override
  Color get dividerColor => Colors.white.withAlpha(56);

  @override
  TextStyle get headingStyle => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      );

  @override
  TextStyle get titleStyle => const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  @override
  TextStyle get subtitleStyle => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white.withAlpha(166),
      );

  @override
  Widget glass({
    required Widget child,
    double radius = 24,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    Color? color,
  }) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(radius),
      padding: padding,
      tintColor: color ?? Colors.white,
      tintOpacity: 0.10,
      blurSigma: 16,
      highlightStrength: 0.22,
      quality: LiquidGlassQuality.medium,
      mode: LiquidGlassMode.auto,
      child: child,
    );
  }
}
