import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'components/hero_player.dart';
import 'components/bot_enemy.dart';

class MOBAOfflineGame extends FlameGame with HasCollisionDetection {
  final bool initialPremiumStatus;
  bool isPremiumWeapon;
  
  int currentLevel = 1;
  int enemyKilled = 0;

  late HeroPlayerComponent player;
  late JoystickComponent joystick;
  late HudButtonComponent attackButton;

  MOBAOfflineGame({required this.initialPremiumStatus}) 
    : isPremiumWeapon = initialPremiumStatus;

  @override
  Color backgroundColor() => const Color(0xFF2E7D32); // Warna rumput MOBA

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. Setup Pemain & Kamera
    player = HeroPlayerComponent();
    world.add(player);
    camera.follow(player);

    // 2. Setup HUD Joystick (Kiri Bawah)
    final knobPaint = BasicPalette.white.withAlpha(200).paint();
    final backgroundPaint = BasicPalette.black.withAlpha(100).paint();
    
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 30, paint: knobPaint),
      background: CircleComponent(radius: 70, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    camera.viewport.add(joystick);

    // 3. Setup HUD Tombol Serang (Kanan Bawah)
    attackButton = HudButtonComponent(
      button: CircleComponent(radius: 40, paint: Paint()..color = Colors.redAccent.withOpacity(0.8)),
      margin: const EdgeInsets.only(right: 40, bottom: 40),
      onPressed: () => player.basicAttack(isPremiumWeapon),
    );
    camera.viewport.add(attackButton);

    // 4. Mulai Gelombang Pertama
    spawnWave();
  }

  void spawnWave() {
    final random = Random();
    int amountToSpawn = currentLevel * 3;

    for (int i = 0; i < amountToSpawn; i++) {
      // Spawn musuh secara acak di sekitar pemain (radius 300-600)
      double angle = random.nextDouble() * 2 * pi;
      double radius = 300 + random.nextDouble() * 300;
      Vector2 spawnPos = player.position + Vector2(cos(angle) * radius, sin(angle) * radius);
      
      world.add(BotEnemyComponent(spawnPos));
    }
  }

  void onEnemyKilled() {
    enemyKilled++;
    
    // Naik Level setiap membunuh kelipatan 5
    if (enemyKilled % 5 == 0) {
      currentLevel++;
      spawnWave(); // Panggil gelombang baru yang lebih kuat
    }
  }

  void triggerGameOver() {
    if (currentLevel >= 4 && !isPremiumWeapon) {
      // Tampilkan Pop-Up QRIS Monetisasi dari UI Flutter
      overlays.add('QRIS_PAYWALL');
    } else {
      // Logika restart normal jika masih level bawah
      overlays.add('GAME_OVER_NORMAL'); 
    }
  }
}
