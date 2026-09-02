import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../moba_game.dart';

class JungleMonster extends PositionComponent with HasGameRef<MOBAOfflineGame> {
  final bool boss;
  double hp;
  double timer = 0;
  final double maxHp;

  JungleMonster({
    required Vector2 position,
    this.boss = false,
  })  : maxHp = boss ? 1800 : 450,
        hp = boss ? 1800 : 450,
        super(
          position: position,
          size: Vector2.all(boss ? 90 : 58),
          anchor: Anchor.center,
        );

  bool get dead => hp <= 0;

  void takeDamage(double damage) {
    if (dead) {
      return;
    }
    hp = math.max(0, hp - damage).toDouble();
    if (dead) {
      gameRef.onMonsterKilled(this);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (dead || gameRef.player.isDead) {
      return;
    }

    timer = math.max(0, timer - dt).toDouble();
    final distance = gameRef.player.position.distanceTo(position);
    if (distance < 280 && timer <= 0) {
      gameRef.player.takeDamage(boss ? 28 : 12);
      timer = boss ? 0.75 : 1.15;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final radius = size.x / 2;
    final center = Offset(radius, radius);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(radius, radius + size.y * .28),
        width: size.x * .8,
        height: size.y * .2,
      ),
      Paint()..color = Colors.black38,
    );

    final bodyPaint = Paint()
      ..color = boss ? const Color(0xff7b2cbf) : const Color(0xffc66b24);
    canvas.drawCircle(center, radius * .7, bodyPaint);
    canvas.drawCircle(
      Offset(radius - radius * .22, radius - radius * .18),
      radius * .12,
      Paint()..color = Colors.redAccent,
    );
    canvas.drawCircle(
      Offset(radius + radius * .22, radius - radius * .18),
      radius * .12,
      Paint()..color = Colors.redAccent,
    );

    canvas.drawRect(
      Rect.fromLTWH(4, 1, size.x - 8, 5),
      Paint()..color = Colors.black87,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        4,
        1,
        (size.x - 8) * math.max(0, hp / maxHp).toDouble(),
        5,
      ),
      Paint()..color = Colors.limeAccent,
    );

    if (boss) {
      canvas.drawCircle(
        center,
        radius * .88,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.amber,
      );
    }
  }
}
