import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../moba_game.dart';
import 'world_render_3d.dart';

class BotEnemyComponent extends PositionComponent
    with CollisionCallbacks, HasGameRef<MOBAOfflineGame> {
  double maxHp;
  double currentHp;
  final double speed;
  final double attackDamage;
  double attackTimer = 0;
  double visualTime = 0;
  bool isDead = false;

  BotEnemyComponent(Vector2 spawnPosition)
      : maxHp = 65 + 18 * spawnPosition.length / 800,
        currentHp = 65 + 18 * spawnPosition.length / 800,
        speed = 55,
        attackDamage = 8,
        super(position: spawnPosition, size: Vector2.all(66), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: 22));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead || gameRef.player.isDead) return;
    visualTime += dt;
    attackTimer = math.max(0, attackTimer - dt);
    final delta = gameRef.player.position - position;
    final distance = delta.length;
    final aggro = 700 + gameRef.currentLevel * 30;
    if (distance < aggro && distance > 52) position += delta.normalized() * (speed + gameRef.currentLevel * 5) * dt;
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
    final pulse = math.sin(visualTime * 6);
    WorldRender3D.shadow(canvas, Offset(c.dx, c.dy + 23), 43, 13);
    WorldRender3D.armoredBody(
      canvas,
      center: Offset(c.dx, c.dy + 5),
      width: 43,
      height: 43,
      primary: const Color(0xff7b1f2a),
      secondary: const Color(0xffe4545e),
      phase: visualTime,
    );
    canvas.drawCircle(Offset(c.dx, c.dy - 18), 13, Paint()..color = const Color(0xffd94a54));
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 12, c.dy - 18)
        ..lineTo(c.dx, c.dy - 28)
        ..lineTo(c.dx + 12, c.dy - 18)
        ..lineTo(c.dx + 7, c.dy - 11)
        ..lineTo(c.dx - 7, c.dy - 11)
        ..close(),
      Paint()..color = const Color(0xff45121a),
    );
    canvas.drawCircle(Offset(c.dx - 4, c.dy - 17), 2.4, Paint()..color = Colors.white.withOpacity(.8));
    canvas.drawCircle(Offset(c.dx + 4, c.dy - 17), 2.4, Paint()..color = Colors.white.withOpacity(.8));
    canvas.drawCircle(Offset(c.dx, c.dy + 7), 4 + pulse.abs() * .6, Paint()..color = Colors.redAccent.withOpacity(.8));
    WorldRender3D.hpBar(canvas, x: 6, y: 1, width: size.x - 12, hp: currentHp, maxHp: maxHp);
  }
}