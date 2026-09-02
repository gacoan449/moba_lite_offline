import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'components/hero_player.dart';
import 'components/bot_enemy.dart';

class MOBAOfflineGame extends FlameGame with HasCollisionDetection {
  final bool initialPremiumStatus;
  bool isPremiumWeapon;
  int currentLevel = 1;
  int enemyKilled = 0;
  int gold = 0;
  int xp = 0;
  int heroRank = 1;
  String quest = 'Kalahkan musuh untuk memulai petualangan';
  double messageTimer = 0;
  final ValueNotifier<int> hudTick = ValueNotifier(0);

  late HeroPlayerComponent player;
  late JoystickComponent joystick;
  late HudButtonComponent attackButton;
  late HudButtonComponent skillButton;
  final List<BotEnemyComponent> enemies = [];

  MOBAOfflineGame({required this.initialPremiumStatus}) : isPremiumWeapon = initialPremiumStatus;

  @override
  Color backgroundColor() => const Color(0xFF16251A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    player = HeroPlayerComponent();
    world.add(player);
    camera.follow(player);

    joystick = JoystickComponent(
      knob: CircleComponent(radius: 30, paint: BasicPalette.white.withAlpha(220).paint()),
      background: CircleComponent(radius: 78, paint: BasicPalette.black.withAlpha(130).paint()),
      margin: const EdgeInsets.only(left: 28, bottom: 30),
    );
    camera.viewport.add(joystick);

    attackButton = HudButtonComponent(
      button: CircleComponent(radius: 39, paint: Paint()..color = Colors.redAccent.withOpacity(.88)),
      margin: const EdgeInsets.only(right: 28, bottom: 30),
      onPressed: () => player.basicAttack(isPremiumWeapon),
    );
    camera.viewport.add(attackButton);

    skillButton = HudButtonComponent(
      button: CircleComponent(radius: 30, paint: Paint()..color = Colors.deepPurpleAccent.withOpacity(.9)),
      margin: const EdgeInsets.only(right: 105, bottom: 34),
      onPressed: player.useSkill,
    );
    camera.viewport.add(skillButton);
    spawnWave();
  }

  @override
  void update(double dt) {
    super.update(dt);
    enemies.removeWhere((e) => e.isRemoved);
    messageTimer = max(0, messageTimer - dt);
    hudTick.value++;
  }

  void spawnWave() {
    final random = Random();
    final count = min(3 + currentLevel, 10);
    for (int i = 0; i < count; i++) {
      final a = random.nextDouble() * 2 * pi;
      final r = 420 + random.nextDouble() * 420;
      final enemy = BotEnemyComponent(player.position + Vector2(cos(a) * r, sin(a) * r));
      enemies.add(enemy);
      world.add(enemy);
    }
    quest = 'Wave $currentLevel: kalahkan $count musuh';
  }

  void onEnemyKilled() {
    enemyKilled++;
    gold += 25 + currentLevel * 5;
    xp += 20 + currentLevel * 5;
    if (enemyKilled % 5 == 0) {
      currentLevel++;
      heroRank = 1 + (xp ~/ 100);
      player.maxHp += 12;
      player.hp = player.maxHp;
      player.speed += 2;
      quest = 'Level $currentLevel! Wave baru datang...';
      spawnWave();
    }
  }

  void flashMessage(String text) { quest = text; messageTimer = 2; }

  void resetGame() {
    for (final e in List<BotEnemyComponent>.from(enemies)) e.removeFromParent();
    enemies.clear();
    currentLevel = 1; enemyKilled = 0; gold = 0; xp = 0; heroRank = 1;
    player.reset();
    overlays.remove('GAME_OVER_NORMAL');
    overlays.remove('QRIS_PAYWALL');
    spawnWave();
  }

  void triggerGameOver() => overlays.add('GAME_OVER_NORMAL');

  @override
  void render(Canvas canvas) {
    canvas.drawRect(const Rect.fromLTWH(-4000, -4000, 8000, 8000), Paint()..color = const Color(0xFF274E2C));
    final grid = Paint()..color = const Color(0xFF315E35)..strokeWidth = 2;
    for (int x = -4000; x <= 4000; x += 160) canvas.drawLine(Offset(x.toDouble(), -4000), Offset(x.toDouble(), 4000), grid);
    for (int y = -4000; y <= 4000; y += 160) canvas.drawLine(Offset(-4000, y.toDouble()), Offset(4000, y.toDouble()), grid);
    canvas.drawRect(const Rect.fromLTWH(-90, -4000, 180, 8000), Paint()..color = const Color(0xFF285A7A).withOpacity(.75));
    super.render(canvas);
  }
}
