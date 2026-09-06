import 'dart:math' as math;
import 'package:flame/components.dart';

enum AbilityTargeting { self, nearestEnemy, area, directional }
enum DamageType { physical, magic, trueDamage }

class AbilityLevelData {
  const AbilityLevelData({
    required this.damage,
    required this.cooldown,
    required this.cost,
    this.attackRatio = 0,
    this.magicRatio = 0,
  });
  final double damage, cooldown, cost, attackRatio, magicRatio;
}

class AbilityData {
  const AbilityData({
    required this.id,
    required this.name,
    required this.targeting,
    required this.damageType,
    required this.levels,
    this.range = 240,
    this.radius = 100,
  });
  final String id, name;
  final AbilityTargeting targeting;
  final DamageType damageType;
  final List<AbilityLevelData> levels;
  final double range, radius;
  AbilityLevelData level(int n) => levels[(n - 1).clamp(0, levels.length - 1)];
}

class AbilityContext {
  const AbilityContext({
    required this.caster,
    required this.origin,
    required this.aim,
    required this.attack,
    required this.magicPower,
    required this.level,
  });
  final PositionComponent caster;
  final Vector2 origin, aim;
  final double attack, magicPower;
  final int level;
}

class AbilityBinding {
  const AbilityBinding(this.data, this.executor);
  final AbilityData data;
  final AbilityExecutor executor;
  AbilityContext context(PositionComponent caster, Vector2 aim, {required double attack, required double magicPower, required int level}) => AbilityContext(caster: caster, origin: caster.position.clone(), aim: aim, attack: attack, magicPower: magicPower, level: level);
}

abstract class AbilityExecutor {
  bool cast(AbilityContext context, AbilityData data);
  double damage(AbilityContext c, AbilityLevelData l) =>
      l.damage + c.attack * l.attackRatio + c.magicPower * l.magicRatio;
}

class CooldownState {
  final Map<String, double> remaining = {};
  bool ready(String id) => (remaining[id] ?? 0) <= 0;
  void start(String id, double seconds) => remaining[id] = seconds;
  void tick(double dt) {
    for (final key in remaining.keys.toList()) {
      remaining[key] = math.max(0, (remaining[key] ?? 0) - dt);
    }
  }
}

class AoEDamageExecutor extends AbilityExecutor {
  AoEDamageExecutor(this.queryTargets);
  final Iterable<dynamic> Function(Vector2 center, double radius) queryTargets;

  @override
  bool cast(AbilityContext c, AbilityData data) {
    final l = data.level(c.level);
    final center = c.origin.distanceTo(c.aim) <= data.range
        ? c.aim.clone()
        : c.origin + (c.aim - c.origin).normalized() * data.range;
    final amount = damage(c, l);
    for (final target in queryTargets(center, data.radius)) {
      target.takeDamage(amount, data.damageType);
    }
    return true;
  }
}