import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../moba_game.dart';
import 'bot_enemy.dart';
import 'projectile.dart';

class HeroPlayerComponent extends PositionComponent
    with CollisionCallbacks, HasGameRef<MOBAOfflineGame> {
  double maxHp = 320;
  double hp = 320;
  double mana = 100;
  double speed = 185;
  double baseDamage = 28;
  double baseSkillDamage = 75;
  double attackCooldown = 0;
  double skillCooldown = 0;
  bool isDead = false;
  Vector2 facing = Vector2(1, 0);

  HeroPlayerComponent()
      : super(position: Vector2.zero(), size: Vector2.all(58), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: 20));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;
    attackCooldown = math.max(0, attackCooldown - dt);
    skillCooldown = math.max(0, skillCooldown - dt);
    mana = math.min(100, mana + dt * 4);
    final input = gameRef.joystick.relativeDelta;
    if (input.length2 > 0.01) {
      final dir = input.normalized();
      facing = dir.clone();
      position += dir * speed * dt;
      position.x = position.x.clamp(-2800, 2800).toDouble();
      position.y = position.y.clamp(-2800, 2800).toDouble();
    }
    if (hp < maxHp) hp = math.min(maxHp, hp + dt * 0.8);
  }

  void basicAttack(bool premium) {
    if (isDead || attackCooldown > 0) return;
    attackCooldown = premium ? 0.22 : 0.42;
    BotEnemyComponent? target;
    double best = double.infinity;
    for (final enemy in gameRef.enemies) {
      final d = enemy.position.distanceTo(position);
      if (!enemy.isDead && d < 520 && d < best) {
        best = d;
        target = enemy;
      }
    }
    final direction = target == null ? facing.clone() : (target.position - position).normalized();
    facing = direction.clone();
    gameRef.world.add(Projectile(
      direction: direction,
      damage: (premium ? baseDamage * 1.7 : baseDamage),
      position: position + direction * 28,
      isPremium: premium,
    ));
  }

  void useSkill() {
    if (isDead || skillCooldown > 0 || mana < 30) return;
    skillCooldown = 5.0;
    mana -= 30;
    for (final enemy in List<BotEnemyComponent>.from(gameRef.enemies)) {
      if (!enemy.isDead && enemy.position.distanceTo(position) < 210) {
        enemy.takeDamage(baseSkillDamage);
      }
    }
    gameRef.flashMessage('SKILL: ${gameRef.selectedHero.name.toUpperCase()} • SHOCKWAVE!');
  }

  void takeDamage(double damage) {
    if (isDead) return;
    hp -= damage;
    if (hp <= 0) {
      hp = 0;
      isDead = true;
      gameRef.triggerGameOver();
    }
  }

  void reset() {
    isDead = false;
    hp = maxHp;
    mana = 100;
    attackCooldown = 0;
    skillCooldown = 0;
    position = Vector2.zero();
    facing = Vector2(1, 0);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final s = size.x / 58;
    final center = Offset(size.x / 2, size.y / 2);
    final body = Paint()..color = const Color(0xFF1769AA);
    final dark = Paint()..color = const Color(0xFF0D3B66);
    final armor = Paint()..color = gameRef.selectedHeroId == 'lyra' ? const Color(0xFF9C6BFF) : const Color(0xFF4FC3F7);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy + 16 * s), width: 42 * s, height: 13 * s), Paint()..color = Colors.black.withOpacity(.28));
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy + 7 * s), width: 30 * s, height: 25 * s), dark);
    canvas.drawPath(Path()
      ..moveTo(center.dx - 15 * s, center.dy + 1 * s)
      ..lineTo(center.dx + 15 * s, center.dy + 1 * s)
      ..lineTo(center.dx + 11 * s, center.dy + 17 * s)
      ..lineTo(center.dx - 11 * s, center.dy + 17 * s)
      ..close(), body);
    canvas.drawCircle(Offset(center.dx, center.dy - 11 * s), 11 * s, armor);
    canvas.drawCircle(Offset(center.dx - 3 * s, center.dy - 14 * s), 3 * s, Paint()..color = Colors.white.withOpacity(.8));
    final dir = facing.normalized();
    canvas.drawLine(Offset(center.dx + dir.x * 16 * s, center.dy + dir.y * 16 * s), Offset(center.dx + dir.x * 32 * s, center.dy + dir.y * 32 * s), Paint()..color = Colors.white..strokeWidth = 4 * s);
  }
}
