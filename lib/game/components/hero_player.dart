import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../moba_game.dart';
import 'bot_enemy.dart';
import 'jungle_monster.dart';
import 'minion.dart';
import 'turret.dart';

class HeroPlayerComponent extends PositionComponent
    with HasGameReference<MOBAOfflineGame> {
  HeroPlayerComponent({required this.name, required this.baseDamage});

  final String name;
  final double baseDamage;
  final double baseSkillDamage = 55;
  Vector2 facing = Vector2(1, 0);
  double hp = 1000;
  double mana = 500;
  double skillCooldown = 0;
  bool premium = false;
  bool isDead = false;

  @override
  void update(double dt) {
    super.update(dt);
    if (skillCooldown > 0) {
      skillCooldown = math.max(0, skillCooldown - dt);
    }
  }

  void attack() {
    if (isDead) {
      return;
    }

    dynamic target;
    double bestDistance = 330;

    for (final enemy in game.enemies) {
      if (enemy.isDead) {
        continue;
      }
      final d = enemy.position.distanceTo(position);
      if (d < bestDistance) {
        bestDistance = d;
        target = enemy;
      }
    }

    for (final minion in game.minions) {
      if (minion.isDead) {
        continue;
      }
      final d = minion.position.distanceTo(position);
      if (d < bestDistance) {
        bestDistance = d;
        target = minion;
      }
    }

    for (final monster in game.monsters) {
      if (monster.isDead) {
        continue;
      }
      final d = monster.position.distanceTo(position);
      if (d < bestDistance) {
        bestDistance = d;
        target = monster;
      }
    }

    for (final turret in game.turrets) {
      final d = turret.position.distanceTo(position);
      if (d < bestDistance && d < 330) {
        bestDistance = d;
        target = turret;
      }
    }

    final direction = target == null
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

    for (final enemy in List<BotEnemyComponent>.from(game.enemies)) {
      if (!enemy.isDead && enemy.position.distanceTo(position) < 240) {
        enemy.takeDamage(baseSkillDamage);
      }
    }

    for (final minion in List<MinionComponent>.from(game.minions)) {
      if (!minion.isDead && minion.position.distanceTo(position) < 240) {
        minion.takeDamage(baseSkillDamage);
      }
    }

    game.flashMessage('$name used skill!');
  }

  void takeDamage(double damage) {
    if (isDead) {
      return;
    }
    hp -= damage;
    if (hp <= 0) {
      hp = 0;
      isDead = true;
      game.flashMessage('$name has been defeated');
    }
  }
}
