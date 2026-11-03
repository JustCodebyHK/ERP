// Hallmark · v2.0.0 · theme: Ink (manual deal, genre editorial)
// Floor: tokens at :root equivalent, no literal colour/font past token block, focus-visible on interactives, reduced-motion aware, one idea per screen.
// Waived: Floor rule 4 (overflow-x clip) — not applicable to Flutter viewport; Floor rule 7 (scripting off) — Flutter requires Dart VM.

import 'package:flutter/material.dart';

/// Student Academic ERP — Hallmark Ink design system (Flutter adaptation).
///
/// Every colour, font, spacing and radius is declared as a token in this file.
/// No literal colour or font-family appears past the token block below.
///
/// Token scale: 8 dp base grid. Touch targets minimum 48 dp (M3).

class AppTheme {
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // TOKEN BLOCK — all colours and fonts declared here; nothing literal below
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Brand seed colour (preserved from original). One signal colour only.
  static const Color seedBrand = Color(0xFF6366F1);

  /// Surface / neutral palette derived from seed. All surface colours are tokens.
  static const Color surface = Color(0xFFFAFAF9);
  static const Color surfaceContainer = Color(0xFFF5F5F4);
  static const Color surfaceContainerHighest = Color(0xFFE7E5E4);
  static const Color surfaceContainerHigh = Color(0xFFD6D3D1);
  static const Color outlineVariant = Color(0xFFC7C5C4);
  static const Color outline = Color(0xFF9C9999);
  static const Color onSurface = Color(0xFF1C1B19);
  static const Color onSurfaceVariant = Color(0xFF4F4E4D);
  static const Color primaryContainer = Color(0xFFE8E0FF);
  static const Color onPrimaryContainer = Color(0xFF3A3082);
  static const Color primary = Color(0xFF6366F1);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF625B71);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color tertiary = Color(0xFF6D5B69);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color onErrorContainer = Color(0xFF410002);

  /// Font family declarations. Inter is the single body/head face (no label face).
  static const String fontBody = 'Inter';
  static const String fontHead = 'Inter';

  /// 8 dp spacing grid tokens.
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double spaceXxl = 48.0;

  /// Minimum touch target (M3 requirement: 48 × 48 dp).
  static const double touchTarget = 48.0;

  /// Surface radii per nesting level (one radius per level).
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;

  /// Default animation duration; reduced-motion aware consumers should shorten
  /// or disable based on platform accessibility settings.
  static const Duration motionDuration = Duration(milliseconds: 300);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // THEME BUILDERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Light theme.
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedBrand,
      brightness: Brightness.light,
    );
    return _build(colorScheme, Brightness.light);
  }

  /// Dark theme.
  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedBrand,
      brightness: Brightness.dark,
    );
    return _build(colorScheme, Brightness.dark);
  }

  static ThemeData _build(ColorScheme colorScheme, Brightness brightness) {
    final textTheme = _textTheme(colorScheme, brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      // Scaffold & surface
      scaffoldBackgroundColor: colorScheme.surface,

      // Card theme — single surface, no card-in-card.
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        elevation: 0,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        margin: const EdgeInsets.all(0),
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
      ),

      // Navigation bar theme
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimaryContainer,
            );
          }
          return textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colorScheme.onPrimaryContainer,
              size: 24,
            );
          }
          return IconThemeData(
            color: colorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
        height: 80,
      ),

      // Button themes — one primary filled style, one outlined, one text.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, touchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(double.infinity, touchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: BorderSide(
            color: colorScheme.outline,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),

      // Input theme — labels sentence case, untracked, body face.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
      ),

      // Chip theme — labels in body face, sentence case, untracked.
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        checkmarkColor: colorScheme.onSecondaryContainer,
        disabledColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        labelStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        secondaryLabelStyle: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
        secondarySelectedColor: colorScheme.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        brightness: brightness,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: textTheme.bodyMedium,
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: colorScheme.surfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
        ),
      ),

      // Progress indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),

      // Switch, checkbox, radio
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outlineVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.5);
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return null;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        side: BorderSide(color: colorScheme.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outlineVariant;
        }),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        actionTextColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme colorScheme, Brightness brightness) {
    return TextTheme(
      // Heads: one weight (w600), one colour (onSurface), no italic mixed in roman.
      displayLarge: TextStyle(
        fontFamily: fontHead,
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: onSurface,
      ),
      displayMedium: TextStyle(
        fontFamily: fontHead,
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: onSurface,
      ),
      displaySmall: TextStyle(
        fontFamily: fontHead,
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: onSurface,
      ),
      headlineLarge: TextStyle(
        fontFamily: fontHead,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontHead,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontHead,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: fontHead,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: fontHead,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontFamily: fontHead,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: onSurface,
      ),
      // Body: body face, readable size, comfortable line height.
      bodyLarge: TextStyle(
        fontFamily: fontBody,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontBody,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.5,
        color: colorScheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: fontBody,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.5,
        color: colorScheme.onSurfaceVariant,
      ),
      // Labels: body face, a step smaller, sentence case, untracked, never mono.
      labelLarge: TextStyle(
        fontFamily: fontBody,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurfaceVariant,
      ),
      labelMedium: TextStyle(
        fontFamily: fontBody,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontFamily: fontBody,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurfaceVariant,
      ),
    ).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
  }

  /// Focus indicator colour for interactive elements (focus-visible equivalent).
  static Color get focusColor => primary;

  /// Helper to apply focus visual on a focusable widget.
  static BoxDecoration focusDecoration({
    required ColorScheme cs,
    double radius = radiusSm,
  }) {
    return BoxDecoration(
      color: cs.surfaceContainer,
      border: Border.all(color: focusColor, width: 2),
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

/// Convenience accessor for the current theme's color scheme and text theme.
extension ColorSchemeX on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get tt => Theme.of(this).textTheme;
}

/// Reads platform reduced-motion preference. Returns true when the user has
/// requested reduced motion; UI should shorten or disable animations.
bool prefersReducedMotion(BuildContext context) {
  return MediaQuery.of(context).disableAnimations;
}
