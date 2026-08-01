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
    // Tambahkan Hitbox agar bisa mendeteksi tabrakan
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Gerakkan peluru sesuai arah (direction)
    position += direction.normalized() * speed * dt;

    // Hancurkan peluru jika keluar terlalu jauh dari layar agar memori tidak bocor
    if (position.x.abs() > 2000 || position.y.abs() > 2000) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    // Jika peluru mengenai musuh
    if (other is BotEnemyComponent) {
      other.takeDamage(damage);
      // Peluru hancur setelah mengenai target (Kecuali laser tembus pandang)
      if (!isPremium) removeFromParent(); 
    }
  }
}
