import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../moba_game.dart';

class BotEnemyComponent extends PositionComponent
    with CollisionCallbacks, HasGameRef<MOBAOfflineGame> {
  double maxHp;
  double currentHp;
  final double speed;
  final double attackDamage;
  double attackTimer = 0;
  bool isDead = false;

  BotEnemyComponent(Vector2 spawnPosition)
      : maxHp = 65 + 18 * spawnPosition.length / 800,
        currentHp = 65 + 18 * spawnPosition.length / 800,
        speed = 55,
        attackDamage = 8,
        super(position: spawnPosition, size: Vector2.all(52), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: 18));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead || gameRef.player.isDead) return;
    attackTimer = math.max(0, attackTimer - dt);
    final delta = gameRef.player.position - position;
    final distance = delta.length;
    final aggro = 700 + gameRef.currentLevel * 30;
    if (distance < aggro && distance > 52) {
      position += delta.normalized() * (speed + gameRef.currentLevel * 5) * dt;
    }
    if (distance <= 58 && attackTimer <= 0) {
      gameRef.player.takeDamage(attackDamage + gameRef.currentLevel * 1.5);
      attackTimer = .65;
    }
  }

  void takeDamage(double damage) {
    if (isDead) return;
    currentHp -= damage;
    if (currentHp <= 0) {
      isDead = true;
      removeFromParent();
      gameRef.onEnemyKilled();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final c = Offset(size.x / 2, size.y / 2);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx, c.dy + 15), width: 38, height: 12),
      Paint()..color = Colors.black.withOpacity(.28),
    );
    canvas.drawCircle(Offset(c.dx, c.dy + 4), 17, Paint()..color = const Color(0xFF8E2430));
    canvas.drawCircle(Offset(c.dx, c.dy - 12), 12, Paint()..color = const Color(0xFFD94A54));
    canvas.drawCircle(Offset(c.dx - 4, c.dy - 15), 3, Paint()..color = Colors.white.withOpacity(.7));
    canvas.drawRect(Rect.fromLTWH(6, 0, 40, 5), Paint()..color = Colors.black87);
    canvas.drawRect(
      Rect.fromLTWH(6, 0, 40 * math.max(0, currentHp / maxHp), 5),
      Paint()..color = Colors.limeAccent,
    );
  }
}
