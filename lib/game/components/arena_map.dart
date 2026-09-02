import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Procedural MOBA arena layer for the Flame UI/runtime.
class ArenaMapComponent extends Component {
  double worldTime = 0;

  @override
  void update(double dt) {
    super.update(dt);
    worldTime += dt;
  }

  @override
  void render(Canvas canvas) {
    final double pulse = .5 + .5 * math.sin(worldTime * .35);
    canvas.drawRect(
      const Rect.fromLTWH(-3500, -1800, 7000, 3600),
      Paint()..color = const Color(0xff477f50),
    );

    final Paint jungle = Paint()..color = const Color(0xff2c6337);
    final Paint jungleEdge = Paint()..color = const Color(0xff214d2b).withValues(alpha: .75);
    final List<Rect> zones = <Rect>[
      const Rect.fromLTWH(-1550, -1050, 1050, 360),
      const Rect.fromLTWH(500, -1050, 1050, 360),
      const Rect.fromLTWH(-1550, 690, 1050, 360),
      const Rect.fromLTWH(500, 690, 1050, 360),
    ];
    for (final Rect zone in zones) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(zone.shift(const Offset(0, 18)), const Radius.circular(110)),
        jungleEdge,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(zone, const Radius.circular(110)),
        jungle,
      );
    }

    canvas.drawRect(
      const Rect.fromLTWH(-125, -1800, 250, 3600),
      Paint()..color = const Color(0xff2f8fa8).withValues(alpha: .90),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-150, -1800, 25, 3600),
      Paint()..color = const Color(0xffb0ead5).withValues(alpha: .58),
    );
    canvas.drawRect(
      const Rect.fromLTWH(125, -1800, 25, 3600),
      Paint()..color = const Color(0xffb0ead5).withValues(alpha: .58),
    );

    for (double y = -1650; y < 1700; y += 260) {
      final double drift = math.sin(worldTime * 1.2 + y * .01) * 18;
      final Paint water = Paint()
        ..color = Colors.white.withValues(alpha: .08 + pulse * .08)
        ..strokeWidth = 4;
      canvas.drawLine(Offset(-80 + drift, y), Offset(80 + drift, y + 12), water);
    }

    final Paint shoulderShadow = Paint()
      ..color = Colors.black.withValues(alpha: .20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 180
      ..strokeCap = StrokeCap.round;
    final Paint shoulder = Paint()
      ..color = const Color(0xffc8a96f)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 164
      ..strokeCap = StrokeCap.round;
    final Paint road = Paint()
      ..color = const Color(0xffe2ca92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 116
      ..strokeCap = StrokeCap.round;

    for (final double y in <double>[-560, 0, 560]) {
      canvas.drawLine(const Offset(-3000, 0), const Offset(3000, 0), Paint());
      canvas.drawLine(Offset(-3000, y + 16), Offset(3000, y + 16), shoulderShadow);
      canvas.drawLine(Offset(-3000, y), Offset(3000, y), shoulder);
      canvas.drawLine(Offset(-3000, y), Offset(3000, y), road);
    }

    final Paint mark = Paint()
      ..color = Colors.white.withValues(alpha: .18)
      ..strokeWidth = 5;
    for (final double y in <double>[-560, 0, 560]) {
      for (double x = -2800; x < 2800; x += 260) {
        canvas.drawLine(Offset(x, y), Offset(x + 100, y), mark);
      }
    }

    for (final double y in <double>[-560, 560]) {
      final Rect bridge = Rect.fromLTWH(-180, y - 80, 360, 160);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bridge.shift(const Offset(0, 12)), const Radius.circular(30)),
        Paint()..color = Colors.black26,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bridge, const Radius.circular(30)),
        Paint()..color = const Color(0xff9f7a4b),
      );
      final Paint rail = Paint()..color = Colors.white24..strokeWidth = 6;
      canvas.drawLine(Offset(-145, y - 48), Offset(145, y - 48), rail);
    }

    _drawBase(canvas, -2700, true);
    _drawBase(canvas, 2700, false);

    final Paint pad = Paint()..color = const Color(0xff244f31).withValues(alpha: .72);
    final List<Offset> centers = <Offset>[
      const Offset(-950, -300),
      const Offset(-950, 300),
      const Offset(950, -300),
      const Offset(950, 300),
      const Offset(0, -900),
      const Offset(0, 900),
    ];
    for (final Offset center in centers) {
      canvas.drawCircle(center + const Offset(0, 14), 135, Paint()..color = Colors.black26);
      canvas.drawCircle(center, 135, pad);
      final Paint ring = Paint()
        ..color = const Color(0xff8c7b5b)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9;
      canvas.drawCircle(center, 98, ring);
    }

    final Paint trunk = Paint()..color = const Color(0xff215b32);
    final Paint leaves = Paint()..color = const Color(0xff5d9e4a);
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 6; col++) {
        final double x = -1450.0 + col * 105 + (row.isOdd ? 45 : 0);
        final double y = -980.0 + row * 95;
        final List<Offset> points = <Offset>[
          Offset(x, y), Offset(-x, y), Offset(x, -y), Offset(-x, -y),
        ];
        for (final Offset point in points) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(point.dx, point.dy + 31), width: 48, height: 14),
            Paint()..color = Colors.black26,
          );
          canvas.drawRect(Rect.fromLTWH(point.dx - 5, point.dy + 18, 10, 28), trunk);
          canvas.drawCircle(Offset(point.dx, point.dy + 8), 25, leaves);
          canvas.drawCircle(Offset(point.dx - 15, point.dy + 18), 18, leaves);
          canvas.drawCircle(Offset(point.dx + 15, point.dy + 18), 18, leaves);
        }
      }
    }
  }

  void _drawBase(Canvas canvas, double x, bool allied) {
    final Color main = allied ? const Color(0xff2878d8) : const Color(0xffd13d4b);
    final Color glow = allied ? const Color(0xff8ee8ff) : const Color(0xffffa1b6);
    canvas.drawCircle(Offset(x, 18), 305, Paint()..color = Colors.black26);
    canvas.drawCircle(Offset(x, 0), 255, Paint()..color = main.withValues(alpha: .18));
    final Paint ring = Paint()
      ..color = main
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28;
    canvas.drawCircle(Offset(x, 0), 210, ring);
    final Path crystal = Path()
      ..moveTo(x, -180)
      ..lineTo(x + 115, -50)
      ..lineTo(x + 75, 155)
      ..lineTo(x, 205)
      ..lineTo(x - 75, 155)
      ..lineTo(x - 115, -50)
      ..close();
    canvas.drawPath(crystal.shift(const Offset(0, 18)), Paint()..color = Colors.black26);
    canvas.drawPath(crystal, Paint()..color = glow.withValues(alpha: .82));
    final Paint edge = Paint()
      ..color = Colors.white.withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawPath(crystal, edge);
  }
}
