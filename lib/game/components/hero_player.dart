import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../moba_game.dart';
import 'bot_enemy.dart';
import 'jungle_monster.dart';
import 'minion.dart';
import 'turret.dart';

class HeroPlayerComponent extends PositionComponent
    with HasGameRef<MOBAOfflineGame> {
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
      : super(
          position: Vector2(-2350, 0),
          size: Vector2.all(72),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) {
      return;
    }

    attackCooldown = math.max(0, attackCooldown - dt).toDouble();
    skillCooldown = math.max(0, skillCooldown - dt).toDouble();
    mana = math.min(100, mana + dt * 5).toDouble();

    final input = gameRef.joystick.relativeDelta;
    if (input.length2 > .01) {
      facing = input.normalized();
      position += facing * speed * dt;
      position.x = position.x.clamp(-2850, 2850).toDouble();
      position.y = position.y.clamp(-1650, 1650).toDouble();
    }

    if (hp < maxHp) {
      hp = math.min(maxHp, hp + dt).toDouble();
    }
  }

  void basicAttack(bool premium) {
    if (isDead || attackCooldown > 0) {
      return;
    }

    attackCooldown = premium ? 0.22 : 0.45;
    dynamic target;
    double bestDistance = double.infinity;

    for (final enemy in gameRef.enemies) {
      if (!enemy.isDead) {
        final distance = enemy.position.distanceTo(position);
        if (distance < bestDistance && distance < 420) {
          bestDistance = distance;
          target = enemy;
        }
      }
    }

    for (final minion in gameRef.minions) {
      if (!minion.isRemoved && !minion.allied) {
        final distance = minion.position.distanceTo(position);
        if (distance < bestDistance && distance < 350) {
          bestDistance = distance;
          target = minion;
        }
      }
    }

    for (final monster in gameRef.monsters) {
      if (!monster.dead) {
        final distance = monster.position.distanceTo(position);
        if (distance < bestDistance && distance < 350) {
          bestDistance = distance;
          target = monster;
        }
      }
    }

    for (final turret in gameRef.turrets) {
      if (!turret.allied && !turret.destroyed) {
        final distance = turret.position.distanceTo(position);
        if (distance < bestDistance && distance < 330) {
          bestDistance = distance;
          target = turret;
        }
      }
    }

    final Vector2 direction = target == null
        ? facing
        : (target.position - position).normalized();
    facing = direction.clone();
    final damage = premium ? baseDamage * 1.45 : baseDamage;

    if (target is BotEnemyComponent) {
      target.takeDamage(damage);
    } else if (target is MinionComponent) {
      target.takeDamage(damage);
    } else if (target is JungleMonster) {
      target.takeDamage(damage);
    } else if (target is TurretComponent) {
      target.takeDamage(damage * .75);
    }
  }

  void useSkill() {
    if (isDead || skillCooldown > 0 || mana < 30) {
      return;
    }

    skillCooldown = 5;
    mana -= 30;

    for (final enemy in List<BotEnemyComponent>.from(gameRef.enemies)) {
      if (!enemy.isDead && enemy.position.distanceTo(position) < 240) {
        enemy.takeDamage(baseSkillDamage);
      }
    }
    for (final minion in List<MinionComponent>.from(gameRef.minions)) {
      if (!minion.isRemoved &&
          !minion.allied &&
          minion.position.distanceTo(position) < 240) {
        minion.takeDamage(baseSkillDamage * .8);
      }
    }
    for (final monster in List<JungleMonster>.from(gameRef.monsters)) {
      if (!monster.dead && monster.position.distanceTo(position) < 240) {
        monster.takeDamage(baseSkillDamage * .8);
      }
    }

    gameRef.flashMessage('${gameRef.selectedHero.name} • SKILL AREA!');
  }

  void takeDamage(double damage) {
    if (isDead) {
      return;
    }
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
    position = Vector2(-2350, 0);
    facing = Vector2(1, 0);
  }

  @override
  void render(Canvas canvas) {
    final scale = size.x / 72;
    final origin = Offset(size.x / 2, size.y / 2);
    final armor = gameRef.selectedHero.id == 'lyra'
        ? const Color(0xff9c6bff)
        : const Color(0xff39a9ff);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(origin.dx, origin.dy + 25 * scale),
        width: 50 * scale,
        height: 15 * scale,
      ),
      Paint()..color = Colors.black45,
    );

    canvas.drawPath(
      Path()
        ..moveTo(origin.dx - 19 * scale, origin.dy - scale)
        ..lineTo(origin.dx + 19 * scale, origin.dy - scale)
        ..lineTo(origin.dx + 14 * scale, origin.dy + 25 * scale)
        ..lineTo(origin.dx - 14 * scale, origin.dy + 25 * scale)
        ..close(),
      Paint()..color = const Color(0xff174f91),
    );

    canvas.drawCircle(
      Offset(origin.dx, origin.dy - 14 * scale),
      15 * scale,
      Paint()..color = armor,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(origin.dx, origin.dy - 14 * scale),
        radius: 16 * scale,
      ),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xff132d55),
    );
    canvas.drawCircle(
      Offset(origin.dx - 5 * scale, origin.dy - 16 * scale),
      2.5 * scale,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(origin.dx + 5 * scale, origin.dy - 16 * scale),
      2.5 * scale,
      Paint()..color = Colors.white,
    );

    final direction = facing.normalized();
    canvas.drawLine(
      Offset(
        origin.dx + direction.x * 13 * scale,
        origin.dy + direction.y * 13 * scale,
      ),
      Offset(
        origin.dx + direction.x * 34 * scale,
        origin.dy + direction.y * 34 * scale,
      ),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 5 * scale,
    );

    canvas.drawRect(
      Rect.fromLTWH(5, 1, size.x - 10, 6),
      Paint()..color = Colors.black87,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        5,
        1,
        (size.x - 10) * math.max(0, hp / maxHp).toDouble(),
        6,
      ),
      Paint()..color = Colors.limeAccent,
    );
  }
}
