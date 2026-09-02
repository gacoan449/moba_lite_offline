import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/arena_map.dart';
import 'components/bot_enemy.dart';
import 'components/hero_player.dart';
import 'components/jungle_monster.dart';
import 'components/minion.dart';
import 'components/turret.dart';
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

  String quest = 'Hancurkan turret musuh dan menangkan pertandingan';
  double messageTimer = 0;
  final ValueNotifier<int> hudTick = ValueNotifier(0);
  bool victory = false;

  late HeroPlayerComponent player;
  late JoystickComponent joystick;
  late HudButtonComponent attackButton;
  late HudButtonComponent skillButton;

  final List<BotEnemyComponent> enemies = [];
  final List<MinionComponent> minions = [];
  final List<TurretComponent> turrets = [];
  final List<JungleMonster> monsters = [];
  SharedPreferences? _prefs;

  MOBAOfflineGame({required this.initialPremiumStatus})
      : isPremiumWeapon = initialPremiumStatus;

  HeroDefinition get selectedHero =>
      heroCatalog.firstWhere((hero) => hero.id == selectedHeroId);

  @override
  Color backgroundColor() => const Color(0xff10251a);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _prefs = await SharedPreferences.getInstance();
    coins = _prefs?.getInt('moba_coins') ?? 0;
    selectedHeroId = _prefs?.getString('selected_hero') ?? 'astra';
    selectedSkinId = _prefs?.getString('selected_skin') ?? 'astra_default';
    ownedHeroes.addAll(_prefs?.getStringList('owned_heroes') ?? ['astra']);
    ownedSkins.addAll(_prefs?.getStringList('owned_skins') ?? ['astra_default']);

    // Original battlefield layer: three lanes, central river, jungle camps,
    // bases and decorative vegetation. Gameplay coordinates remain compatible
    // with the existing hero/minion/turret systems.
    world.add(ArenaMapComponent());

    player = HeroPlayerComponent();
    world.add(player);
    applyHeroStats();
    camera.follow(player);

    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 30,
        paint: BasicPalette.white.withAlpha(220).paint(),
      ),
      background: CircleComponent(
        radius: 78,
        paint: BasicPalette.black.withAlpha(150).paint(),
      ),
      margin: const EdgeInsets.only(left: 28, bottom: 30),
    );
    camera.viewport.add(joystick);

    attackButton = HudButtonComponent(
      button: CircleComponent(
        radius: 43,
        paint: Paint()..color = Colors.redAccent.withOpacity(.9),
      ),
      margin: const EdgeInsets.only(right: 28, bottom: 30),
      onPressed: () => player.basicAttack(isPremiumWeapon),
    );
    camera.viewport.add(attackButton);

    skillButton = HudButtonComponent(
      button: CircleComponent(
        radius: 32,
        paint: Paint()..color = Colors.deepPurpleAccent.withOpacity(.9),
      ),
      margin: const EdgeInsets.only(right: 115, bottom: 36),
      onPressed: player.useSkill,
    );
    camera.viewport.add(skillButton);

    buildBattlefield();
    overlays.add('HUD');
  }

  void applyHeroStats() {
    player.maxHp = selectedHero.hp.toDouble();
    player.hp = player.maxHp;
    player.speed = selectedHero.speed.toDouble();
    player.baseDamage = selectedHero.damage.toDouble();
    player.baseSkillDamage = selectedHero.skillDamage.toDouble();
  }

  void buildBattlefield() {
    for (final turret in List<TurretComponent>.from(turrets)) {
      turret.removeFromParent();
    }
    for (final monster in List<JungleMonster>.from(monsters)) {
      monster.removeFromParent();
    }
    for (final enemy in List<BotEnemyComponent>.from(enemies)) {
      enemy.removeFromParent();
    }
    for (final minion in List<MinionComponent>.from(minions)) {
      minion.removeFromParent();
    }

    turrets.clear();
    monsters.clear();
    enemies.clear();
    minions.clear();

    // Three lanes, each with two defensive structures per side.
    const lanes = [-560.0, 0.0, 560.0];
    for (final y in lanes) {
      for (final x in [-2050.0, -1250.0]) {
        final turret = TurretComponent(
          position: Vector2(x, y),
          allied: true,
          lane: 'lane',
        );
        turrets.add(turret);
        world.add(turret);
      }
      for (final x in [1250.0, 2050.0]) {
        final turret = TurretComponent(
          position: Vector2(x, y),
          allied: false,
          lane: 'lane',
        );
        turrets.add(turret);
        world.add(turret);
      }
    }

    // Jungle camps around the river, plus a central boss camp.
    final monsterPositions = <Vector2>[
      Vector2(-950.0, -300.0),
      Vector2(-950.0, 300.0),
      Vector2(0.0, -900.0),
      Vector2(0.0, 900.0),
    ];
    for (final position in monsterPositions) {
      final monster = JungleMonster(position: position);
      monsters.add(monster);
      world.add(monster);
    }

    final boss = JungleMonster(position: Vector2.zero(), boss: true);
    monsters.add(boss);
    world.add(boss);

    spawnWave();
    spawnEnemyHeroes();
  }

  void spawnEnemyHeroes() {
    final positions = <Vector2>[
      Vector2(1800.0, -560.0),
      Vector2(1800.0, 0.0),
      Vector2(1800.0, 560.0),
      Vector2(1800.0, -120.0),
      Vector2(1800.0, 120.0),
    ];
    for (final position in positions) {
      final enemy = BotEnemyComponent(position.clone());
      enemies.add(enemy);
      world.add(enemy);
    }
  }

  void spawnWave() {
    const lanes = [-560.0, 0.0, 560.0];
    for (final y in lanes) {
      for (int i = 0; i < 3; i++) {
        final alliedMinion = MinionComponent(
          position: Vector2(-2500.0 - i * 55.0, y),
          allied: true,
          ranged: i == 2,
        );
        final enemyMinion = MinionComponent(
          position: Vector2(2500.0 + i * 55.0, y),
          allied: false,
          ranged: i == 2,
        );
        minions.add(alliedMinion);
        minions.add(enemyMinion);
        world.add(alliedMinion);
        world.add(enemyMinion);
      }
    }
    quest = '3 LANE • MINION WAVE • HANCURKAN TURRET';
  }

  @override
  void update(double dt) {
    super.update(dt);
    enemies.removeWhere((enemy) => enemy.isRemoved);
    minions.removeWhere((minion) => minion.isRemoved);
    turrets.removeWhere((turret) => turret.isRemoved);
    monsters.removeWhere((monster) => monster.isRemoved);
    messageTimer = max(0, messageTimer - dt).toDouble();
    hudTick.value++;

    if (!victory &&
        turrets.where((turret) => !turret.allied && !turret.destroyed).isEmpty) {
      victory = true;
      quest = 'MENANG! SEMUA TURRET MUSUH HANCUR';
      overlays.add('GAME_OVER_NORMAL');
      pauseEngine();
    }
  }

  void onTurretDestroyed(TurretComponent turret) {
    gold += 180;
    xp += 120;
    flashMessage('TURRET MUSUH HANCUR! +180 GOLD');
  }

  void onMonsterKilled(JungleMonster monster) {
    gold += monster.boss ? 500 : 80;
    xp += monster.boss ? 350 : 70;
    flashMessage(
      monster.boss
          ? 'BOSS JUNGLE DIKALAHKAN! +500 GOLD'
          : 'MONSTER JUNGLE DIKALAHKAN! +80 GOLD',
    );
  }

  void onEnemyKilled() {
    enemyKilled++;
    gold += 25;
    xp += 30;
    if (enemyKilled % 5 == 0) {
      currentLevel++;
      heroRank = 1 + (xp ~/ 100);
      player.maxHp += 15;
      player.hp = player.maxHp;
      flashMessage('LEVEL $currentLevel • POWER NAIK');
    }
  }

  void flashMessage(String text) {
    quest = text;
    messageTimer = 2;
  }

  Future<void> selectHero(HeroDefinition hero) async {
    if (!ownedHeroes.contains(hero.id)) return;
    selectedHeroId = hero.id;
    await _prefs?.setString('selected_hero', hero.id);
    applyHeroStats();
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
    final hero = skin['hero']! as String;
    final price = skin['price']! as int;
    if (!ownedHeroes.contains(hero) || ownedSkins.contains(id) || coins < price) {
      return false;
    }
    coins -= price;
    ownedSkins.add(id);
    await equipSkin(skin);
    await _saveWallet();
    return true;
  }

  Future<void> equipSkin(Map<String, Object> skin) async {
    final id = skin['id']! as String;
    if (!ownedSkins.contains(id)) return;
    selectedSkinId = id;
    await _prefs?.setString('selected_skin', id);
    hudTick.value++;
  }

  Future<void> onRewardedAdCompleted() async {
    coins += 100;
    await _saveWallet();
    flashMessage('+100 COIN');
    hudTick.value++;
  }

  Future<void> _saveWallet() async {
    await _prefs?.setInt('moba_coins', coins);
    await _prefs?.setStringList('owned_heroes', ownedHeroes.toList());
    await _prefs?.setStringList('owned_skins', ownedSkins.toList());
  }

  void resetGame() {
    victory = false;
    currentLevel = 1;
    enemyKilled = 0;
    gold = 0;
    xp = 0;
    heroRank = 1;
    player.reset();
    overlays.remove('GAME_OVER_NORMAL');
    resumeEngine();
    buildBattlefield();
  }

  void triggerGameOver() {
    if (victory) return;
    overlays.add('GAME_OVER_NORMAL');
    pauseEngine();
  }

  @override
  void render(Canvas canvas) {
    // Neutral fallback background; ArenaMapComponent paints the complete
    // original battlefield above this layer.
    canvas.drawRect(
      const Rect.fromLTWH(-3500, -1800, 7000, 3600),
      Paint()..color = const Color(0xff294b31),
    );
    super.render(canvas);
  }
}
