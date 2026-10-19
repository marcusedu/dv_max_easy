import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Wallpaper do menu lateral. Um ladrilho de traços se repete, no mesmo
/// espírito do fundo do WhatsApp, com os motivos do app.
class SidebarDoodle extends StatelessWidget {
  const SidebarDoodle({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SidebarDoodlePainter(
            color: scheme.primary.withValues(alpha: dark ? 0.28 : 0.22),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _SidebarDoodlePainter extends CustomPainter {
  const _SidebarDoodlePainter({required this.color});

  final Color color;

  static const _tile = 168.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    var row = 0;
    for (var y = -_tile; y < size.height + _tile; y += _tile) {
      final shift = row.isOdd ? _tile / 2 : 0.0;
      for (var x = -_tile; x < size.width + _tile; x += _tile) {
        canvas.save();
        canvas.translate(x + shift, y);
        _tileMarks(canvas, stroke);
        canvas.restore();
      }
      row++;
    }
  }

  void _tileMarks(Canvas canvas, Paint paint) {
    _glyph(canvas, paint, const Offset(28, 30), 0.18, _play);
    _glyph(canvas, paint, const Offset(96, 22), -0.1, _film);
    _glyph(canvas, paint, const Offset(146, 52), 0.22, _note);
    _glyph(canvas, paint, const Offset(42, 90), 0, _download);
    _glyph(canvas, paint, const Offset(108, 80), 0.12, _heart);
    _glyph(canvas, paint, const Offset(154, 114), -0.2, _link);
    _glyph(canvas, paint, const Offset(34, 142), 0, _headphones);
    _glyph(canvas, paint, const Offset(100, 140), 0.06, _bubble);
  }

  void _glyph(
    Canvas canvas,
    Paint paint,
    Offset center,
    double turns,
    void Function(Canvas canvas, Paint paint) draw,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (turns != 0) {
      canvas.rotate(turns);
    }
    draw(canvas, paint);
    canvas.restore();
  }

  void _play(Canvas canvas, Paint paint) {
    canvas.drawCircle(Offset.zero, 8, paint);
    canvas.drawPath(
      Path()
        ..moveTo(-2.4, -4.4)
        ..lineTo(4.4, 0)
        ..lineTo(-2.4, 4.4)
        ..close(),
      paint,
    );
  }

  void _film(Canvas canvas, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-11, -8, 22, 16),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawLine(const Offset(-4, -8), const Offset(-4, 8), paint);
    canvas.drawLine(const Offset(4, -8), const Offset(4, 8), paint);
    for (final x in const [-8.0, -1.0, 6.0]) {
      canvas.drawLine(Offset(x, -8), Offset(x, -6.2), paint);
      canvas.drawLine(Offset(x, 8), Offset(x, 6.2), paint);
    }
  }

  void _note(Canvas canvas, Paint paint) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-3, 5), width: 8, height: 6),
      paint,
    );
    canvas.drawLine(const Offset(1, 4), const Offset(1, -8), paint);
    canvas.drawLine(const Offset(1, -8), const Offset(8, -5.5), paint);
  }

  void _download(Canvas canvas, Paint paint) {
    canvas.drawLine(const Offset(0, -8), const Offset(0, 2), paint);
    canvas.drawLine(const Offset(-4.5, -1.5), const Offset(0, 3.5), paint);
    canvas.drawLine(const Offset(4.5, -1.5), const Offset(0, 3.5), paint);
    canvas.drawLine(const Offset(-7, 8), const Offset(7, 8), paint);
    canvas.drawLine(const Offset(-7, 8), const Offset(-7, 5), paint);
    canvas.drawLine(const Offset(7, 8), const Offset(7, 5), paint);
  }

  void _heart(Canvas canvas, Paint paint) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 4.5)
        ..cubicTo(-9, -1.5, -3.2, -8.5, 0, -3.2)
        ..cubicTo(3.2, -8.5, 9, -1.5, 0, 4.5),
      paint,
    );
  }

  void _link(Canvas canvas, Paint paint) {
    canvas.save();
    canvas.rotate(-0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-8, -3, 13, 6),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.restore();
    canvas.save();
    canvas.rotate(0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-5, -3, 13, 6),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.restore();
  }

  void _headphones(Canvas canvas, Paint paint) {
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(0, 1), radius: 8),
      math.pi,
      math.pi,
      false,
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-10, -1, 4, 8),
        const Radius.circular(1.5),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6, -1, 4, 8),
        const Radius.circular(1.5),
      ),
      paint,
    );
  }

  void _bubble(Canvas canvas, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-9, -8, 18, 12),
        const Radius.circular(4),
      ),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-2, 4)
        ..lineTo(-6, 9)
        ..lineTo(3, 4),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SidebarDoodlePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
