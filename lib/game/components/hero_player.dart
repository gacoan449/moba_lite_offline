import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../moba_game.dart';
import 'bot_enemy.dart';
import 'jungle_monster.dart';
import 'minion.dart';
import 'turret.dart';
import 'world_render_3d.dart';

class HeroPlayerComponent extends PositionComponent with HasGameReference<MOBAOfflineGame> {
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
  double _visualTime = 0;

  HeroPlayerComponent() : super(position: Vector2(-2350, 0), size: Vector2.all(92), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;
    _visualTime += dt;
    attackCooldown = math.max(0, attackCooldown - dt).toDouble();
    skillCooldown = math.max(0, skillCooldown - dt).toDouble();
    mana = math.min(100, mana + dt * 5).toDouble();
    final input = game.joystick.relativeDelta;
    if (input.length2 > .01) {
      facing = input.normalized();
      position += facing * speed * dt;
      position.x = position.x.clamp(-2850, 2850).toDouble();
      position.y = position.y.clamp(-1650, 1650).toDouble();
    }
    if (hp < maxHp) hp = math.min(maxHp, hp + dt).toDouble();
  }

  void basicAttack(bool premium) {
    if (isDead || attackCooldown > 0) return;
    attackCooldown = premium ? 0.22 : 0.45;
    dynamic target;
    double bestDistance = double.infinity;
    for (final enemy in game.enemies) {
      if (!enemy.isDead) {
        final d = enemy.position.distanceTo(position);
        if (d < bestDistance && d < 420) {
          bestDistance = d;
          target = enemy;
        }
      }
    }
    for (final minion in game.minions) {
      if (!minion.isRemoved && !minion.allied) {
        final d = minion.position.distanceTo(position);
        if (d < bestDistance && d < 350) {
          bestDistance = d;
          target = minion;
        }
      }
    }
    for (final monster in game.monsters) {
      if (!monster.dead) {
        final d = monster.position.distanceTo(position);
        if (d < bestDistance && d < 350) {
          bestDistance = d;
          target = monster;
        }
      }
    }
    for (final turret in game.turrets) {
      if (!turret.allied && !turret.destroyed) {
        final d = turret.position.distanceTo(position);
        if (d < bestDistance && d < 330) {
          bestDistance = d;
          target = turret;
        }
      }
    }
    final direction = target == null ? facing : (target.position - position).normalized();
    facing = direction.clone();
    final damage = premium ? baseDamage * 1.45 : baseDamage;
    if (target is BotEnemyComponent) target.takeDamage(damage);
    else if (target is MinionComponent) target.takeDamage(damage);
    else if (target is JungleMonster) target.takeDamage(damage);
    else if (target is TurretComponent) target.takeDamage(damage * .75);
  }

  void useSkill() {
    if (isDead || skillCooldown > 0 || mana < 30) return;
    skillCooldown = 5;
    mana -= 30;
    for (final enemy in List<BotEnemyComponent>.from(game.enemies)) {
      if (!enemy.isDead && enemy.position.distanceTo(position) < 240) enemy.takeDamage(baseSkillDamage);
    }
    for (final minion in List<MinionComponent>.from(game.minions)) {
      if (!minion.isRemoved && !minion.allied && minion.position.distanceTo(position) < 240) {
        minion.takeDamage(baseSkillDamage * .8);
      }
    }
    for (final monster in List<JungleMonster>.from(game.monsters)) {
      if (!monster.dead && monster.position.distanceTo(position) < 240) monster.takeDamage(baseSkillDamage * .8);
    }
    game.flashMessage('${game.selectedHero.name} • SKILL AREA!');
  }

  void takeDamage(double damage) {
    if (isDead) return;
    hp -= damage;
    if (hp <= 0) {
      hp = 0;
      isDead = true;
      game.triggerGameOver();
    }
  }

  void reset() {
    isDead = false;
    hp = maxHp;
    mana = 100;
    attackCooldown = 0;
    skillCooldown = 0;
    position = Vector2(-2350, 0);
    facing = Vector2(1, 0);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final origin = Offset(size.x / 2, size.y / 2);
    final pulse = math.sin(_visualTime * 5);
    final armor = game.selectedHero.id == 'lyra' ? const Color(0xff9c6bff) : const Color(0xff39a9ff);
    WorldRender3D.shadow(canvas, Offset(origin.dx, origin.dy + 31), 58, 17);
    canvas.drawOval(Rect.fromCenter(center: Offset(origin.dx, origin.dy + 24), width: 48, height: 15), Paint()
      ..style = PaintingStyle.stroke ..strokeWidth = 2 ..color = armor.withValues(alpha: .45 + pulse * .08));
    WorldRender3D.armoredBody(canvas, center: Offset(origin.dx, origin.dy + 4), width: 58, height: 58,
      primary: const Color(0xff174f91), secondary: armor, phase: _visualTime);
    canvas.drawCircle(Offset(origin.dx, origin.dy - 21), 17, Paint()..color = armor);
    canvas.drawPath(Path()..moveTo(origin.dx - 17, origin.dy - 22)..lineTo(origin.dx, origin.dy - 34)..lineTo(origin.dx + 17, origin.dy - 22)..lineTo(origin.dx + 12, origin.dy - 13)..lineTo(origin.dx - 12, origin.dy - 13)..close(), Paint()..color = const Color(0xff10213b));
    canvas.drawOval(Rect.fromCenter(center: Offset(origin.dx, origin.dy - 19), width: 21, height: 7), Paint()..color = Colors.white.withValues(alpha: .78));
    canvas.drawCircle(Offset(origin.dx, origin.dy + 3), 5 + pulse * .7, Paint()..color = Colors.cyanAccent.withValues(alpha: .8));
    for (final dx in [-25.0, 25.0]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(origin.dx + dx, origin.dy + 3), width: 18, height: 12), Paint()..color = armor.withValues(alpha: .92));
    }
    final direction = facing.normalized();
    final weaponStart = Offset(origin.dx + direction.x * 17, origin.dy + direction.y * 17);
    final weaponEnd = Offset(origin.dx + direction.x * 39, origin.dy + direction.y * 39);
    canvas.drawLine(weaponStart, weaponEnd, Paint()..color = Colors.white..strokeWidth = 6);
    canvas.drawCircle(weaponEnd, 4 + pulse.abs(), Paint()..color = Colors.cyanAccent.withValues(alpha: .7));
    WorldRender3D.hpBar(canvas, x: 7, y: 2, width: size.x - 14, hp: hp, maxHp: maxHp);
  }
}
