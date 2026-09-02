import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Original high-density MOBA world layer.
///
/// Flame is a 2D renderer, so this layer uses procedural perspective cues,
/// layered terrain, shadows, water highlights and animated world lighting to
/// create a 3D-style battlefield without external textures.
class ArenaMapComponent extends Component {
  double worldTime = 0;

  @override
  void update(double dt) {
    super.update(dt);
    worldTime += dt;
  }

  @override
  void render(Canvas canvas) {
    final lightPulse = .5 + .5 * math.sin(worldTime * .35);
    canvas.drawRect(
      const Rect.fromLTWH(-3500, -1800, 7000, 3600),
      Paint()..color = const Color(0xff477f50),
    );

    // Low-poly terrain islands and darker depth edges.
    final jungle = Paint()..color = const Color(0xff2c6337);
    final jungleEdge = Paint()..color = const Color(0xff214d2b).withOpacity(.75);
    const zones = [
      Rect.fromLTWH(-1550, -1050, 1050, 360),
      Rect.fromLTWH(500, -1050, 1050, 360),
      Rect.fromLTWH(-1550, 690, 1050, 360),
      Rect.fromLTWH(500, 690, 1050, 360),
    ];
    for (final zone in zones) {
      final raised = zone.shift(const Offset(0, 18));
      canvas.drawRRect(RRect.fromRectAndRadius(raised, const Radius.circular(110)), jungleEdge);
      canvas.drawRRect(RRect.fromRectAndRadius(zone, const Radius.circular(110)), jungle);
    }

    // Central river with banks, depth gradient bands and animated specular light.
    canvas.drawRect(
      const Rect.fromLTWH(-125, -1800, 250, 3600),
      Paint()..color = const Color(0xff2f8fa8).withOpacity(.90),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-150, -1800, 25, 3600),
      Paint()..color = const Color(0xffb0ead5).withOpacity(.58),
    );
    canvas.drawRect(
      const Rect.fromLTWH(125, -1800, 25, 3600),
      Paint()..color = const Color(0xffb0ead5).withOpacity(.58),
    );
    for (double y = -1650; y < 1700; y += 260) {
      final drift = math.sin(worldTime * 1.2 + y * .01) * 18;
      canvas.drawLine(
        Offset(-80 + drift, y),
        Offset(80 + drift, y + 12),
        Paint()
          ..color = Colors.white.withOpacity(.08 + lightPulse * .08)
          ..strokeWidth = 4,
      );
    }

    // Three lanes: raised stone shoulders + road surface + center light.
    final shoulder = Paint()
      ..color = const Color(0xffc8a96f)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 164
      ..strokeCap = StrokeCap.round;
    final shoulderShadow = Paint()
      ..color = Colors.black.withOpacity(.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 180
      ..strokeCap = StrokeCap.round;
    final road = Paint()
      ..color = const Color(0xffe2ca92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 116
      ..strokeCap = StrokeCap.round;
    for (final y in [-560.0, 0.0, 560.0]) {
      canvas.drawLine(const Offset(-3000, y + 16), const Offset(3000, y + 16), shoulderShadow);
      canvas.drawLine(const Offset(-3000, y), const Offset(3000, y), shoulder);
      canvas.drawLine(const Offset(-3000, y), const Offset(3000, y), road);
      canvas.drawLine(
        const Offset(-3000, y - 3),
        const Offset(3000, y - 3),
        Paint()
          ..color = Colors.white.withOpacity(.13 + lightPulse * .05)
          ..strokeWidth = 5,
      );
    }

    final mark = Paint()
      ..color = Colors.white.withOpacity(.18)
      ..strokeWidth = 5;
    for (final y in [-560.0, 0.0, 560.0]) {
      for (double x = -2800; x < 2800; x += 260) {
        canvas.drawLine(Offset(x, y), Offset(x + 100, y), mark);
      }
    }
    for (final y in [-560.0, 560.0]) {
      final bridge = Rect.fromLTWH(-180, y - 80, 360, 160);
      canvas.drawRRect(RRect.fromRectAndRadius(bridge.shift(const Offset(0, 12)), const Radius.circular(30)), Paint()..color = Colors.black26);
      canvas.drawRRect(RRect.fromRectAndRadius(bridge, const Radius.circular(30)), Paint()..color = const Color(0xff9f7a4b));
      canvas.drawLine(Offset(-145, y - 48), Offset(145, y - 48), Paint()..color = Colors.white24..strokeWidth = 6);
    }

    _drawBase(canvas, -2700, true);
    _drawBase(canvas, 2700, false);

    final pad = Paint()..color = const Color(0xff244f31).withOpacity(.72);
    for (final center in [
      const Offset(-950, -300), const Offset(-950, 300),
      const Offset(950, -300), const Offset(950, 300),
      const Offset(0, -900), const Offset(0, 900),
    ]) {
      canvas.drawCircle(center + const Offset(0, 14), 135, Paint()..color = Colors.black26);
      canvas.drawCircle(center, 135, pad);
      canvas.drawCircle(center, 98, Paint()..color = const Color(0xff8c7b5b)..style = PaintingStyle.stroke..strokeWidth = 9);
    }

    // Procedural tree clusters with a separate canopy shadow for depth.
    final trunk = Paint()..color = const Color(0xff215b32);
    final leaves = Paint()..color = const Color(0xff5d9e4a);
    final leafHighlight = Paint()..color = const Color(0xff86c96c).withOpacity(.65);
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 6; col++) {
        final x = -1450.0 + col * 105 + (row.isOdd ? 45 : 0);
        final y = -980.0 + row * 95;
        for (final p in [Offset(x, y), Offset(-x, y), Offset(x, -y), Offset(-x, -y)]) {
          canvas.drawOval(Rect.fromCenter(center: Offset(p.dx, p.dy + 31), width: 48, height: 14), Paint()..color = Colors.black24);
          canvas.drawRect(Rect.fromLTWH(p.dx - 5, p.dy + 18, 10, 28), trunk);
          canvas.drawCircle(Offset(p.dx, p.dy + 8), 25, leaves);
          canvas.drawCircle(Offset(p.dx - 15, p.dy + 18), 18, leaves);
          canvas.drawCircle(Offset(p.dx + 15, p.dy + 18), 18, leaves);
          canvas.drawCircle(Offset(p.dx - 8, p.dy - 1), 9, leafHighlight);
        }
      }
    }

    // Global atmospheric glint: a lightweight 'temporal' layer. This is not
    // literal fourth-dimensional space; it is a time-dependent visual axis.
    final glint = Paint()..color = Colors.white.withOpacity(.025 + lightPulse * .025);
    canvas.drawRect(const Rect.fromLTWH(-3500, -1800, 7000, 3600), glint);
  }

  void _drawBase(Canvas canvas, double x, bool allied) {
    final main = allied ? const Color(0xff2878d8) : const Color(0xffd13d4b);
    final glow = allied ? const Color(0xff8ee8ff) : const Color(0xffffa1b6);

    canvas.drawCircle(Offset(x, 18), 305, Paint()..color = Colors.black26);
    canvas.drawCircle(Offset(x, 0), 255, Paint()..color = main.withOpacity(.18));
    canvas.drawCircle(Offset(x, 0), 210, Paint()..color = main..style = PaintingStyle.stroke..strokeWidth = 28);

    final crystal = Path()
      ..moveTo(x, -180)..lineTo(x + 115, -50)..lineTo(x + 75, 155)
      ..lineTo(x, 205)..lineTo(x - 75, 155)..lineTo(x - 115, -50)..close();
    canvas.drawPath(crystal.shift(const Offset(0, 18)), Paint()..color = Colors.black26);
    canvas.drawPath(crystal, Paint()..color = glow.withOpacity(.82));
    canvas.drawPath(crystal, Paint()..color = Colors.white.withOpacity(.55)..style = PaintingStyle.stroke..strokeWidth = 8);

    for (final y in [-95.0, 0.0, 95.0]) {
      canvas.drawCircle(Offset(x + (allied ? 1 : -1) * 145, y), 26, Paint()..color = main);
    }
  }
}
