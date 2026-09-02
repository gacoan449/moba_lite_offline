import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../moba_game.dart';

class MinionComponent extends PositionComponent with HasGameRef<MOBAOfflineGame> {
  final bool allied;
  final bool ranged;
  double hp;
  double attackTimer = 0;

  MinionComponent({
    required Vector2 position,
    required this.allied,
    this.ranged = false,
  })  : hp = ranged ? 65 : 95,
        super(
          position: position,
          size: Vector2.all(42),
          anchor: Anchor.center,
        );

  void takeDamage(double damage) {
    hp -= damage;
    if (hp <= 0) {
      hp = 0;
      removeFromParent();
      gameRef.gold += 12;
      gameRef.xp += 8;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hp <= 0) {
      return;
    }

    attackTimer = math.max(0, attackTimer - dt).toDouble();
    final enemyMinions = gameRef.minions
        .where(
          (minion) =>
              minion.allied != allied &&
              !minion.isRemoved &&
              minion.position.distanceTo(position) < 80,
        )
        .toList();
    final enemyTurrets = gameRef.turrets
        .where(
          (turret) =>
              turret.allied != allied &&
              !turret.destroyed &&
              turret.position.distanceTo(position) < 95,
        )
        .toList();

    if (attackTimer <= 0) {
      if (enemyMinions.isNotEmpty) {
        enemyMinions.first.takeDamage(ranged ? 18 : 25);
        attackTimer = ranged ? 0.8 : 0.7;
      } else if (enemyTurrets.isNotEmpty) {
        enemyTurrets.first.takeDamage(ranged ? 13 : 19);
        attackTimer = 1;
      } else {
        position.x += (allied ? 95 : -95) * dt;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final origin = Offset(size.x / 2, size.y / 2);
    final primary = allied ? const Color(0xff2581dd) : const Color(0xffd83e4c);
    final secondary =
        allied ? const Color(0xff8ed8ff) : const Color(0xffff8b8b);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(origin.dx, origin.dy + 14),
        width: 32,
        height: 9,
      ),
      Paint()..color = Colors.black38,
    );
    canvas.drawCircle(
      Offset(origin.dx, origin.dy + 5),
      13,
      Paint()..color = primary,
    );
    canvas.drawCircle(
      Offset(origin.dx, origin.dy - 8),
      10,
      Paint()..color = secondary,
    );
    canvas.drawCircle(
      Offset(origin.dx - 4, origin.dy - 10),
      2.4,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(origin.dx + 4, origin.dy - 10),
      2.4,
      Paint()..color = Colors.white,
    );
    canvas.drawLine(
      Offset(origin.dx - 4, origin.dy - 2),
      Offset(origin.dx + 4, origin.dy - 2),
      Paint()
        ..color = Colors.black87
        ..strokeWidth = 2,
    );

    if (ranged) {
      canvas.drawCircle(
        Offset(origin.dx, origin.dy + 7),
        7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.amber,
      );
    }

    canvas.drawRect(
      const Rect.fromLTWH(5, 1, 32, 4),
      Paint()..color = Colors.black87,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        5,
        1,
        32 * math.max(0, hp / (ranged ? 65 : 95)).toDouble(),
        4,
      ),
      Paint()..color = Colors.limeAccent,
    );
  }
}
