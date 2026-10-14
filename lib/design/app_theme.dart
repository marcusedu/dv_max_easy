import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration medium = Duration(milliseconds: 200);
  static const Duration pageTransition = Duration(milliseconds: 220);
  static const Cubic easeOut = Cubic(0.23, 1.0, 0.32, 1.0);
  static const Cubic easeInOut = Cubic(0.77, 0.0, 0.175, 1.0);
}

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
  static const Duration motion = AppMotion.fast;
}

abstract final class AppTheme {
  static const lightAccent = Color(0xFF1F6F8B);
  static const darkAccent = Color(0xFF5ED4F5);

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
          surface: dark ? const Color(0xFF101418) : const Color(0xFFF4F4F6),
          onSurface: dark ? const Color(0xFFF2F4F8) : const Color(0xFF1D1D1F),
          onSurfaceVariant: dark
              ? const Color(0xFF9AA3B2)
              : const Color(0xFF6E6E73),
          surfaceContainerLow: dark
              ? const Color(0xFF0C1016)
              : const Color(0xFFE7E7EC),
          surfaceContainerHighest: dark
              ? const Color(0xFF171C24)
              : const Color(0xFFFFFFFF),
          outlineVariant: dark
              ? const Color(0x1AFFFFFF)
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
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 240),
        showDuration: const Duration(milliseconds: 1600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: text.bodySmall?.copyWith(color: scheme.onSurface),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius - 2),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.35 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
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

class PressableScale extends StatefulWidget {
  const PressableScale({
    required this.child,
    this.scaleDown = 0.97,
    this.duration = AppMotion.fast,
    this.curve = AppMotion.easeOut,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final double scaleDown;
  final Duration duration;
  final Curve curve;
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        if (mounted && !_pressed) setState(() => _pressed = true);
      },
      onPointerUp: (_) {
        if (mounted && _pressed) setState(() => _pressed = false);
      },
      onPointerCancel: (_) {
        if (mounted && _pressed) setState(() => _pressed = false);
      },
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1.0,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}

class SmoothProgressIndicator extends StatelessWidget {
  const SmoothProgressIndicator({
    this.value,
    this.minHeight = 4,
    this.backgroundColor,
    this.color,
    super.key,
  });

  final double? value;
  final double minHeight;
  final Color? backgroundColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final target = value;
    if (target == null) {
      return LinearProgressIndicator(
        minHeight: minHeight,
        backgroundColor: backgroundColor,
        color: color,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: target.clamp(0.0, 1.0)),
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      builder: (context, animatedValue, _) {
        return LinearProgressIndicator(
          value: animatedValue,
          minHeight: minHeight,
          backgroundColor: backgroundColor,
          color: color,
        );
      },
    );
  }
}

