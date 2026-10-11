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
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    );
    final family = defaultTargetPlatform == TargetPlatform.macOS
        ? null
        : 'Inter';
    final text = _text(scheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: family,
      textTheme: text,
      splashFactory: NoSplash.splashFactory,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: BorderSide(color: scheme.outlineVariant),
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
