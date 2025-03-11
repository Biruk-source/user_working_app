import 'package:flutter/material.dart';
import 'dart:math' as math;

class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    const numberOfCircles = 20;
    final random = math.Random(42);

    for (var i = 0; i < numberOfCircles; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 30 + 10;

      canvas.drawCircle(Offset(x.toDouble(), y.toDouble()), radius.toDouble(), paint);
    }

    // Draw diagonal lines
    paint.strokeWidth = 1;
    paint.style = PaintingStyle.stroke;

    for (double i = 0; i < size.width + size.height; i += 40) {
      canvas.drawLine(
        Offset((-size.height + i).toDouble(), size.height.toDouble()),
        Offset(i.toDouble(), 0.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(BackgroundPatternPainter oldDelegate) => false;
}
