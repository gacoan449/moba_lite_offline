import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/hero_player.dart';
import 'components/bot_enemy.dart';
import 'components/minion.dart';
import 'data/hero_catalog.dart';

class MOBAOfflineGame extends FlameGame with HasCollisionDetection {
  final bool initialPremiumStatus;
  bool isPremiumWeapon;
  int currentLevel = 1;
  int enemyKilled = 0;
  int gold = 0;
  int xp = 0;
  int heroRank = 1;
  int coins = 0;
  String selectedHeroId = 'astra';
  String selectedSkinId = 'astra_default';
  final Set<String> ownedHeroes = {'astra'};
  final Set<String> ownedSkins = {'astra_default'};
  String quest = 'Kalahkan musuh untuk memulai petualangan';
  double messageTimer = 0;
  final ValueNotifier<int> hudTick = ValueNotifier(0);

  late HeroPlayerComponent player;
  late JoystickComponent joystick;
  late HudButtonComponent attackButton;
  late HudButtonComponent skillButton;
  final List<BotEnemyComponent> enemies = [];
  final List<MinionComponent> minions = [];
  SharedPreferences? _prefs;

  MOBAOfflineGame({required this.initialPremiumStatus}) : isPremiumWeapon = initialPremiumStatus;

  HeroDefinition get selectedHero => heroCatalog.firstWhere((h) => h.id == selectedHeroId);

  @override
  Color backgroundColor() => const Color(0xFF101A16);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _prefs = await SharedPreferences.getInstance();
    coins = _prefs?.getInt('moba_coins') ?? 0;
    selectedHeroId = _prefs?.getString('selected_hero') ?? 'astra';
    selectedSkinId = _prefs?.getString('selected_skin') ?? 'astra_default';
    final savedHeroes = _prefs?.getStringList('owned_heroes') ?? ['astra'];
    ownedHeroes.addAll(savedHeroes);
    final savedSkins = _prefs?.getStringList('owned_skins') ?? ['astra_default'];
    ownedSkins.addAll(savedSkins);

    player = HeroPlayerComponent();
    world.add(player);
    applyHeroStats();
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
    spawnMinionWave();
    overlays.add('HUD');
  }

  void applyHeroStats() {
    player.maxHp = selectedHero.hp.toDouble();
    player.hp = player.maxHp;
    player.speed = selectedHero.speed;
    player.baseDamage = selectedHero.damage.toDouble();
    player.baseSkillDamage = selectedHero.skillDamage.toDouble();
  }

  Future<void> selectHero(HeroDefinition hero) async {
    if (!ownedHeroes.contains(hero.id)) return;
    selectedHeroId = hero.id;
    await _prefs?.setString('selected_hero', hero.id);
    applyHeroStats();
    flashMessage('${hero.name} siap bertempur!');
    hudTick.value++;
  }

  Future<bool> buyHero(HeroDefinition hero) async {
    if (ownedHeroes.contains(hero.id)) return true;
    if (coins < hero.price) return false;
    coins -= hero.price;
    ownedHeroes.add(hero.id);
    await _saveWallet();
    await selectHero(hero);
    return true;
  }

  Future<bool> buySkin(Map<String, Object> skin) async {
    final id = skin['id']! as String;
    final price = skin['price']! as int;
    final hero = skin['hero']! as String;
    if (!ownedHeroes.contains(hero) || ownedSkins.contains(id) || coins < price) return false;
    coins -= price;
    ownedSkins.add(id);
    selectedSkinId = id;
    await _saveWallet();
    await _prefs?.setString('selected_skin', id);
    flashMessage('Skin ${skin['name']} dipakai!');
    hudTick.value++;
    return true;
  }

  /// Hook untuk callback Google AdMob Rewarded Ad.
  /// Panggil method ini hanya setelah SDK AdMob benar-benar memberi reward.
  Future<void> onRewardedAdCompleted() async {
    coins += 100;
    await _saveWallet();
    flashMessage('+100 COIN dari Rewarded Ad');
    hudTick.value++;
  }

  Future<void> _saveWallet() async {
    await _prefs?.setInt('moba_coins', coins);
    await _prefs?.setStringList('owned_heroes', ownedHeroes.toList());
    await _prefs?.setStringList('owned_skins', ownedSkins.toList());
  }

  @override
  void update(double dt) {
    super.update(dt);
    enemies.removeWhere((e) => e.isRemoved);
    minions.removeWhere((e) => e.isRemoved);
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

  void spawnMinionWave() {
    for (int i = 0; i < 3; i++) {
      final ally = MinionComponent(position: Vector2(-900, -90 + i * 80), allied: true, ranged: i == 2);
      final enemy = MinionComponent(position: Vector2(900, -90 + i * 80), allied: false, ranged: i == 2);
      minions.addAll([ally, enemy]);
      world.add(ally);
      world.add(enemy);
    }
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
      spawnMinionWave();
    }
  }

  void flashMessage(String text) {
    quest = text;
    messageTimer = 2;
  }

  void resetGame() {
    for (final e in List<BotEnemyComponent>.from(enemies)) {
      e.removeFromParent();
    }
    for (final m in List<MinionComponent>.from(minions)) {
      m.removeFromParent();
    }
    enemies.clear();
    minions.clear();
    currentLevel = 1;
    enemyKilled = 0;
    gold = 0;
    xp = 0;
    heroRank = 1;
    applyHeroStats();
    player.reset();
    overlays.remove('GAME_OVER_NORMAL');
    overlays.remove('QRIS_PAYWALL');
    spawnWave();
    spawnMinionWave();
    resumeEngine();
  }

  void triggerGameOver() {
    overlays.add('GAME_OVER_NORMAL');
    pauseEngine();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(const Rect.fromLTWH(-4000, -4000, 8000, 8000), Paint()..color = const Color(0xFF263E2C));
    final grid = Paint()..color = const Color(0xFF355B3B)..strokeWidth = 2;
    for (int x = -4000; x <= 4000; x += 160) {
      canvas.drawLine(Offset(x.toDouble(), -4000), Offset(x.toDouble(), 4000), grid);
    }
    for (int y = -4000; y <= 4000; y += 160) {
      canvas.drawLine(Offset(-4000, y.toDouble()), Offset(4000, y.toDouble()), grid);
    }
    canvas.drawRect(const Rect.fromLTWH(-120, -4000, 240, 8000), Paint()..color = const Color(0xFF285A7A).withOpacity(.72));
    super.render(canvas);
  }
}
