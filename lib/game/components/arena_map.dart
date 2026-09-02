import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Stylized original MOBA battlefield. It uses familiar three-lane gameplay
/// readability without copying another game's artwork or assets.
class ArenaMapComponent extends Component {
  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      const Rect.fromLTWH(-3500, -1800, 7000, 3600),
      Paint()..color = const Color(0xff4b8b55),
    );

    final jungle = Paint()..color = const Color(0xff2f6b3b);
    const zones = [
      Rect.fromLTWH(-1550, -1050, 1050, 360),
      Rect.fromLTWH(500, -1050, 1050, 360),
      Rect.fromLTWH(-1550, 690, 1050, 360),
      Rect.fromLTWH(500, 690, 1050, 360),
    ];
    for (final zone in zones) {
      canvas.drawRRect(RRect.fromRectAndRadius(zone, const Radius.circular(110)), jungle);
    }

    // Central river.
    canvas.drawRect(
      const Rect.fromLTWH(-125, -1800, 250, 3600),
      Paint()..color = const Color(0xff39a6bd).withOpacity(.82),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-155, -1800, 30, 3600),
      Paint()..color = const Color(0xffa9e6cf).withOpacity(.55),
    );
    canvas.drawRect(
      const Rect.fromLTWH(125, -1800, 30, 3600),
      Paint()..color = const Color(0xffa9e6cf).withOpacity(.55),
    );

    // Three readable lanes.
    final shoulder = Paint()
      ..color = const Color(0xffd4b87a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 155
      ..strokeCap = StrokeCap.round;
    final road = Paint()
      ..color = const Color(0xffe8d39b)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 112
      ..strokeCap = StrokeCap.round;
    for (final y in [-560.0, 0.0, 560.0]) {
      canvas.drawLine(const Offset(-3000, y), const Offset(3000, y), shoulder);
      canvas.drawLine(const Offset(-3000, y), const Offset(3000, y), road);
    }

    final mark = Paint()
      ..color = Colors.white.withOpacity(.20)
      ..strokeWidth = 5;
    for (final y in [-560.0, 0.0, 560.0]) {
      for (double x = -2800; x < 2800; x += 260) {
        canvas.drawLine(Offset(x, y), Offset(x + 100, y), mark);
      }
    }
    for (final y in [-560.0, 560.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-180, y - 80, 360, 160),
          const Radius.circular(30),
        ),
        Paint()..color = const Color(0xff9f7a4b),
      );
    }

    _drawBase(canvas, -2700, true);
    _drawBase(canvas, 2700, false);

    final pad = Paint()..color = const Color(0xff244f31).withOpacity(.72);
    for (final center in [
      const Offset(-950, -300),
      const Offset(-950, 300),
      const Offset(950, -300),
      const Offset(950, 300),
      const Offset(0, -900),
      const Offset(0, 900),
    ]) {
      canvas.drawCircle(center, 135, pad);
      canvas.drawCircle(
        center,
        98,
        Paint()
          ..color = const Color(0xff8c7b5b)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9,
      );
    }

    // Stylized tree clusters.
    final trunk = Paint()..color = const Color(0xff215b32);
    final leaves = Paint()..color = const Color(0xff63a64d);
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 6; col++) {
        final x = -1450.0 + col * 105 + (row.isOdd ? 45 : 0);
        final y = -980.0 + row * 95;
        for (final p in [Offset(x, y), Offset(-x, y), Offset(x, -y), Offset(-x, -y)]) {
          canvas.drawRect(Rect.fromLTWH(p.dx - 5, p.dy + 18, 10, 28), trunk);
          canvas.drawCircle(Offset(p.dx, p.dy + 8), 25, leaves);
          canvas.drawCircle(Offset(p.dx - 15, p.dy + 18), 18, leaves);
          canvas.drawCircle(Offset(p.dx + 15, p.dy + 18), 18, leaves);
        }
      }
    }
  }

  void _drawBase(Canvas canvas, double x, bool allied) {
    final main = allied ? const Color(0xff2878d8) : const Color(0xffd13d4b);
    final glow = allied ? const Color(0xff8ee8ff) : const Color(0xffffa1b6);

    canvas.drawCircle(Offset(x, 0), 300, Paint()..color = Colors.black26);
    canvas.drawCircle(Offset(x, 0), 255, Paint()..color = main.withOpacity(.18));
    canvas.drawCircle(
      Offset(x, 0),
      210,
      Paint()
        ..color = main
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28,
    );

    final crystal = Path()
      ..moveTo(x, -180)
      ..lineTo(x + 115, -50)
      ..lineTo(x + 75, 155)
      ..lineTo(x, 205)
      ..lineTo(x - 75, 155)
      ..lineTo(x - 115, -50)
      ..close();
    canvas.drawPath(crystal, Paint()..color = glow.withOpacity(.82));
    canvas.drawPath(
      crystal,
      Paint()
        ..color = Colors.white.withOpacity(.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    for (final y in [-95.0, 0.0, 95.0]) {
      canvas.drawCircle(Offset(x + (allied ? 1 : -1) * 145, y), 26, Paint()..color = main);
    }
  }
}
