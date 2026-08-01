import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../moba_game.dart';

class BotEnemyComponent extends CircleComponent with HasGameRef<MOBAOfflineGame> {
  late double maxHp;
  late double currentHp;
  late double speed;
  late double attackDamage;

  late RectangleComponent hpBar;

  BotEnemyComponent(Vector2 spawnPosition) : super(
    radius: 20,
    position: spawnPosition,
    anchor: Anchor.center,
    paint: Paint()..color = Colors.redAccent,
  );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());

    // DYNAMIC DIFFICULTY (Dinding Frustrasi Psikologis)
    if (gameRef.currentLevel <= 3) {
      maxHp = 50.0;
      speed = 60.0;
      attackDamage = 5.0; // Geli-geli
    } else {
      maxHp = 1000.0; // Sangat tebal
      speed = 190.0; // Lebih cepat dari player
      attackDamage = 45.0; // Sekali senggol kritis
      paint.color = Colors.purple; // Ganti warna jadi ungu tanda bahaya
    }
    currentHp = maxHp;

    // Visual HP Bar Musuh
    hpBar = RectangleComponent(
      size: Vector2(40, 5),
      position: Vector2(-20, -30),
      paint: Paint()..color = Colors.red,
    );
    add(hpBar);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.player.isDead) return; // Berhenti ngejar kalau player mati

    Vector2 playerPos = gameRef.player.position;
    Vector2 directionToPlayer = playerPos - position;
    double distance = directionToPlayer.length;

    // AI LOGIC: Kejar Pemain
    if (gameRef.currentLevel >= 4) {
      // Level 4 ke atas: Jarak pandang luas (500) dan sangat agresif
      if (distance < 500 && distance > 30) {
        position += directionToPlayer.normalized() * speed * dt;
        angle = directionToPlayer.screenAngle();
      }
    } else {
      // Level 1-3: Jarak pandang pendek (250)
      if (distance < 250 && distance > 30) {
        position += directionToPlayer.normalized() * speed * dt;
      }
    }

    // AI LOGIC: Menyerang (Tabrakan Jarak Dekat)
    if (distance <= 40) {
      gameRef.player.takeDamage(attackDamage * dt); // Drain HP Player per frame
    }
  }

  void takeDamage(double damage) {
    currentHp -= damage;
    hpBar.size.x = 40 * (currentHp / maxHp); // Update bar darah

    if (currentHp <= 0) {
      removeFromParent();
      gameRef.onEnemyKilled();
    }
  }
}
