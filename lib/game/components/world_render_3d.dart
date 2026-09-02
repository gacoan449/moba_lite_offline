import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lightweight procedural 3D-style renderer for Flame's 2D Canvas.
///
/// It creates depth using extrusion, perspective offsets, highlights and
/// contact shadows without shipping large texture assets. This keeps the
/// offline game fast while giving characters a more dimensional silhouette.
class WorldRender3D {
  static void shadow(Canvas canvas, Offset center, double width, double height) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: width, height: height),
      Paint()..color = Colors.black.withOpacity(.30),
    );
  }

  static void crystal(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    double phase = 0,
  }) {
    final depth = radius * .20;
    final p = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius * .62, center.dy - radius * .12)
      ..lineTo(center.dx + radius * .42, center.dy + radius)
      ..lineTo(center.dx - radius * .42, center.dy + radius)
      ..lineTo(center.dx - radius * .62, center.dy - radius * .12)
      ..close();

    final side = Path()
      ..moveTo(center.dx + radius * .62, center.dy - radius * .12)
      ..lineTo(center.dx + radius * .42, center.dy + radius)
      ..lineTo(center.dx + radius * .42 + depth, center.dy + radius + depth)
      ..lineTo(center.dx + radius * .62 + depth, center.dy - radius * .12 + depth)
      ..close();

    canvas.drawPath(side, Paint()..color = color.withOpacity(.48));
    canvas.drawPath(p, Paint()..color = color);

    final highlight = Paint()
      ..color = Colors.white.withOpacity(.36 + .08 * math.sin(phase))
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, radius * .08);
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * .78),
      Offset(center.dx - radius * .22, center.dy + radius * .55),
      highlight,
    );
  }

  static void armoredBody(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required Color primary,
    required Color secondary,
    double phase = 0,
  }) {
    final d = width * .12;
    final body = Path()
      ..moveTo(center.dx - width * .38, center.dy - height * .28)
      ..lineTo(center.dx + width * .38, center.dy - height * .28)
      ..lineTo(center.dx + width * .48, center.dy + height * .34)
      ..lineTo(center.dx + width * .24, center.dy + height * .50)
      ..lineTo(center.dx - width * .24, center.dy + height * .50)
      ..lineTo(center.dx - width * .48, center.dy + height * .34)
      ..close();

    final extruded = Path()
      ..moveTo(center.dx + width * .38, center.dy - height * .28)
      ..lineTo(center.dx + width * .48, center.dy + height * .34)
      ..lineTo(center.dx + width * .24, center.dy + height * .50)
      ..lineTo(center.dx + width * .24 + d, center.dy + height * .50 + d)
      ..lineTo(center.dx + width * .48 + d, center.dy + height * .34 + d)
      ..lineTo(center.dx + width * .38 + d, center.dy - height * .28 + d)
      ..close();

    canvas.drawPath(extruded, Paint()..color = primary.withOpacity(.48));
    canvas.drawPath(body, Paint()..color = primary);

    canvas.drawPath(
      Path()
        ..moveTo(center.dx - width * .38, center.dy - height * .28)
        ..lineTo(center.dx, center.dy - height * .43)
        ..lineTo(center.dx + width * .38, center.dy - height * .28)
        ..lineTo(center.dx, center.dy - height * .10)
        ..close(),
      Paint()..color = secondary.withOpacity(.82),
    );

    canvas.drawLine(
      Offset(center.dx - width * .28, center.dy + height * .20),
      Offset(center.dx + width * .26, center.dy + height * .20),
      Paint()
        ..color = Colors.white.withOpacity(.18 + .05 * math.sin(phase))
        ..strokeWidth = math.max(1.0, width * .035),
    );
  }

  static void hpBar(
    Canvas canvas, {
    required double x,
    required double y,
    required double width,
    required double hp,
    required double maxHp,
  }) {
    final ratio = (hp / maxHp).clamp(0.0, 1.0).toDouble();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, width, 6),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.black87,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, width * ratio, 6),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.limeAccent,
    );
  }
}
