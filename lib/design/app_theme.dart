import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double unit = 8;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double sidebar = 220;
  static const double panelRadius = 12;
  static const double controlRadius = 10;
  static const double hit = 28;
  static const Duration motion = Duration(milliseconds: 160);
}

abstract final class AppTheme {
  static const lightAccent = Color(0xFF1F6F8B);
  static const darkAccent = Color(0xFF7FCBE0);

  static ThemeData light() => _build(Brightness.light, lightAccent);

  static ThemeData dark() => _build(Brightness.dark, darkAccent);

  static ThemeData _build(Brightness brightness, Color accent) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
        ).copyWith(
          primary: accent,
          surface: dark ? const Color(0xFF1C1C1E) : const Color(0xFFF4F4F6),
          onSurface: dark ? const Color(0xFFF5F5F7) : const Color(0xFF1D1D1F),
          onSurfaceVariant: dark
              ? const Color(0xFF98989D)
              : const Color(0xFF6E6E73),
          surfaceContainerLow: dark
              ? const Color(0xFF141416)
              : const Color(0xFFE7E7EC),
          surfaceContainerHighest: dark
              ? const Color(0xFF2C2C2E)
              : const Color(0xFFFFFFFF),
          outlineVariant: dark
              ? const Color(0x1FFFFFFF)
              : const Color(0x14000000),
        );
    final family = defaultTargetPlatform == TargetPlatform.macOS
        ? null
        : 'Inter';
    final text = _text(scheme);
    final radius = BorderRadius.circular(AppSpacing.controlRadius);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: family,
      textTheme: text,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      scaffoldBackgroundColor: scheme.surface,
      dividerColor: scheme.outlineVariant,
      listTileTheme: ListTileThemeData(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: radius),
        selectedColor: scheme.onSurface,
        selectedTileColor: accent.withValues(alpha: 0.16),
        iconColor: scheme.onSurfaceVariant,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 32),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
          elevation: 0,
          backgroundColor: accent,
          foregroundColor: dark ? const Color(0xFF062027) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 28),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: scheme.outlineVariant,
        linearMinHeight: 4,
        borderRadius: BorderRadius.circular(4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: true,
        fillColor: scheme.surfaceContainerHighest,
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: text.bodySmall,
        floatingLabelStyle: text.bodySmall?.copyWith(color: accent),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: accent),
        ),
      ),
    );
  }

  static TextTheme _text(ColorScheme scheme) {
    return TextTheme(
      titleLarge: TextStyle(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        height: 24 / 17,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: scheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
