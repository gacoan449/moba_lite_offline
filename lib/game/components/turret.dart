import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../moba_game.dart';

/// Original fantasy-crystal turret: MOBA silhouette, but artwork is unique.
class TurretComponent extends PositionComponent with HasGameRef<MOBAOfflineGame> {
  final bool allied;
  final String lane;
  double hp = 900;
  double timer = 0;

  TurretComponent({
    required Vector2 position,
    required this.allied,
    required this.lane,
  }) : super(position: position, size: Vector2(92, 112), anchor: Anchor.center);

  bool get destroyed => hp <= 0;

  void takeDamage(double damage) {
    if (destroyed) return;
    hp = math.max(0.0, hp - damage).toDouble();
    if (destroyed) {
      gameRef.onTurretDestroyed(this);
      removeFromParent();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (destroyed) return;
    timer = math.max(0.0, timer - dt).toDouble();
    if (timer > 0) return;
    if (allied) {
      for (final enemy in gameRef.enemies) {
        if (!enemy.isDead && enemy.position.distanceTo(position) < 430) {
          enemy.takeDamage(35);
          timer = 0.9;
          break;
        }
      }
    } else if (!gameRef.player.isDead && gameRef.player.position.distanceTo(position) < 430) {
      gameRef.player.takeDamage(18);
      timer = 0.9;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final primary = allied ? const Color(0xff2b91e8) : const Color(0xffdf5262);
    final dark = allied ? const Color(0xff123b78) : const Color(0xff6d2035);
    final crystal = allied ? const Color(0xff8ee8ff) : const Color(0xffffa0b7);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(46, 98), width: 76, height: 22),
      Paint()..color = Colors.black38,
    );

    final pedestal = Path()
      ..moveTo(17, 82)
      ..lineTo(25, 47)
      ..lineTo(67, 47)
      ..lineTo(75, 82)
      ..close();
    canvas.drawPath(pedestal, Paint()..color = dark);
    canvas.drawPath(pedestal, Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);

    for (final dx in [18.0, 46.0, 74.0]) {
      final fin = Path()
        ..moveTo(dx, 78)
        ..lineTo(dx - 7, 52)
        ..lineTo(dx, 43)
        ..lineTo(dx + 7, 52)
        ..close();
      canvas.drawPath(fin, Paint()..color = primary);
    }

    final core = Path()
      ..moveTo(46, 8)
      ..lineTo(61, 31)
      ..lineTo(53, 49)
      ..lineTo(39, 49)
      ..lineTo(31, 31)
      ..close();
    canvas.drawPath(core, Paint()..color = crystal);
    canvas.drawPath(core, Paint()
      ..color = Colors.white.withOpacity(.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    canvas.drawLine(
      const Offset(46, 10),
      const Offset(46, 0),
      Paint()
        ..color = crystal
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(8, 88, 76, 7), const Radius.circular(4)),
      Paint()..color = Colors.black87,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 88, 76 * math.max(0.0, hp / 900.0), 7),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.limeAccent,
    );
  }
}
