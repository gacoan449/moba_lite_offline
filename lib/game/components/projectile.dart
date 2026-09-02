import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'bot_enemy.dart';

class Projectile extends CircleComponent with CollisionCallbacks {
  final Vector2 direction;
  final double damage;
  final double speed = 400.0;
  final bool isPremium;

  Projectile({
    required this.direction,
    required this.damage,
    required Vector2 position,
    this.isPremium = false,
  }) : super(
          radius: isPremium ? 12.0 : 6.0,
          position: position,
          anchor: Anchor.center,
          paint: Paint()..color = isPremium ? Colors.cyanAccent : Colors.orange,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direction.normalized() * speed * dt;
    if (position.x.abs() > 2000 || position.y.abs() > 2000) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is BotEnemyComponent) {
      other.takeDamage(damage);
      if (!isPremium) removeFromParent();
    }
  }
}
