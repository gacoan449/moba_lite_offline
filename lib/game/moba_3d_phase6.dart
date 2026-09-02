import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'moba_3d_phase5.dart';

enum HeroRole { tank, fighter, assassin, mage, marksman, support }
enum AiMode { farm, gank, retreat, switchLane, defendTower, ambush, objective }

class HeroSpec {
  const HeroSpec(this.name, this.role, this.color, this.attack, this.armor, this.mr, this.crit, this.range);
  final String name;
  final HeroRole role;
  final int color;
  final double attack;
  final double armor;
  final double mr;
  final double crit;
  final double range;
}

class Phase6Engine {
  static const List<HeroSpec> heroes = <HeroSpec>[
    HeroSpec('Aegis', HeroRole.tank, 0x4e8cff, 82, 38, 28, 0, 3),
    HeroSpec('Brakka', HeroRole.fighter, 0xd85a4a, 112, 25, 18, .12, 4),
    HeroSpec('Nyx', HeroRole.assassin, 0x9c5cff, 128, 15, 16, .28, 3),
    HeroSpec('Solara', HeroRole.mage, 0xf0b34a, 135, 14, 30, .08, 10),
    HeroSpec('Rook', HeroRole.marksman, 0x55c8ff, 118, 12, 14, .32, 14),
    HeroSpec('Mira', HeroRole.support, 0x62d88f, 70, 20, 32, 0, 8),
    HeroSpec('Vorn', HeroRole.tank, 0x7896a8, 76, 44, 24, 0, 3),
    HeroSpec('Kael', HeroRole.fighter, 0xe47748, 119, 27, 17, .16, 4),
    HeroSpec('Shade', HeroRole.assassin, 0x6d67c9, 142, 13, 15, .34, 3),
    HeroSpec('Iria', HeroRole.mage, 0xb96cff, 128, 16, 34, .06, 11),
    HeroSpec('Fenn', HeroRole.marksman, 0x58d1c2, 124, 13, 15, .30, 15),
    HeroSpec('Luma', HeroRole.support, 0xf18aa5, 66, 21, 35, 0, 9),
  ];

  double difficultyMultiplier(int difficulty) => 1 + difficulty.clamp(1, 100) * .02;

  double resolveDamage({
    required double attack,
    required double penetration,
    required double armor,
    required double mr,
    required bool magic,
    required double critChance,
    required math.Random rng,
  }) {
    final double defense = magic ? mr : math.max(0, armor - penetration).toDouble();
    final bool crit = rng.nextDouble() < critChance;
    return math.max(1, attack * (crit ? 1.65 : 1) * 100 / (100 + defense)).toDouble();
  }
}

class JungleCampSpec {
  const JungleCampSpec(this.name, this.maxHp, this.respawn, this.buff, this.boss);
  final String name;
  final String buff;
  final double maxHp;
  final double respawn;
  final bool boss;
}

class Phase6JungleDirector {
  static const List<JungleCampSpec> camps = <JungleCampSpec>[
    JungleCampSpec('Crimson Beast', 1800, 75, 'Attack +25%', false),
    JungleCampSpec('Azure Beast', 1650, 75, 'Mana + regen', false),
    JungleCampSpec('Stone Warden', 2400, 90, 'Armor +20', false),
    JungleCampSpec('Void Drake', 5200, 180, 'Team objective buff', true),
  ];

  double threat(int difficulty, double hpRatio) =>
      (difficulty / 100) * (1.3 - hpRatio.clamp(.2, 1.3)).toDouble();
}

class Phase6AiDirector {
  AiMode choose({
    required int difficulty,
    required bool lowHp,
    required bool enemyNear,
    required bool objectiveAlive,
    required bool towerThreat,
  }) {
    if (lowHp) return AiMode.retreat;
    if (difficulty >= 75 && objectiveAlive) return AiMode.objective;
    if (towerThreat) return AiMode.defendTower;
    if (difficulty >= 55 && enemyNear) return AiMode.ambush;
    if (difficulty >= 45 && enemyNear) return AiMode.gank;
    if (difficulty >= 30) return AiMode.switchLane;
    return AiMode.farm;
  }
}

class TemporalSnapshot {
  const TemporalSnapshot(this.time, this.x, this.z, this.hp, this.mana);
  final double time;
  final double x;
  final double z;
  final double hp;
  final double mana;
}

class TemporalEngine {
  final List<TemporalSnapshot> _history = <TemporalSnapshot>[];
  final int maxFrames;
  TemporalEngine({this.maxFrames = 90});

  void record(double time, double x, double z, double hp, double mana) {
    _history.add(TemporalSnapshot(time, x, z, hp, mana));
    if (_history.length > maxFrames) _history.removeAt(0);
  }

  TemporalSnapshot? rewind(double seconds, double now) {
    for (final TemporalSnapshot snapshot in _history.reversed) {
      if (now - snapshot.time >= seconds) return snapshot;
    }
    return _history.isEmpty ? null : _history.first;
  }

  void clear() => _history.clear();
}

class Moba3DPhase6 extends StatefulWidget {
  const Moba3DPhase6({super.key});
  @override
  State<Moba3DPhase6> createState() => _Moba3DPhase6State();
}

class _Moba3DPhase6State extends State<Moba3DPhase6> {
  final Phase6Engine engine = Phase6Engine();
  final Phase6AiDirector ai = Phase6AiDirector();
  final Phase6JungleDirector jungle = Phase6JungleDirector();
  final TemporalEngine temporal = TemporalEngine();
  Timer? timer;
  int difficulty = 75;
  int selectedHero = 0;
  bool started = false;
  bool temporalOn = true;
  bool weather = true;
  bool dayNight = true;
  double temporalEnergy = 100;
  AiMode aiPreview = AiMode.objective;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void start() {
    setState(() => started = true);
    timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || !temporalOn) return;
      setState(() => temporalEnergy = math.max(0, temporalEnergy - .25).toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (started) {
      return Scaffold(
        body: Stack(
          children: <Widget>[
            const Positioned.fill(child: Moba3DPhase5()),
            Positioned.fill(
              child: IgnorePointer(
                child: _Phase6Overlay(
                  temporal: true,
                  energy: 100,
                  weather: true,
                  dayNight: true,
                ),
              ),
            ),
            Positioned(left: 12, top: 12, child: _hud()),
          ],
        ),
      );
    }

    final HeroSpec hero = Phase6Engine.heroes[selectedHero];
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xff08101f), Color(0xff17263b), Color(0xff07100e)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Row(
            children: <Widget>[
              Expanded(flex: 6, child: Padding(padding: const EdgeInsets.all(28), child: _heroPanel(hero))),
              Expanded(flex: 5, child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: _controlPanel())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroPanel(HeroSpec hero) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text('ARENA LEGENDS', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 4)),
          const Text('PHASE 6 • ENGINE WARFARE', style: TextStyle(fontSize: 16, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Container(
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Color(hero.color), width: 2),
              gradient: LinearGradient(colors: <Color>[
                Color(hero.color).withValues(alpha: .45),
                Colors.black.withValues(alpha: .35),
              ]),
            ),
            child: Center(child: Text(hero.name, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(height: 18),
          Text(
            '${hero.role.name.toUpperCase()} • ATK ${hero.attack.toInt()} • ARM ${hero.armor.toInt()} • MR ${hero.mr.toInt()} • CRIT ${(hero.crit * 100).toInt()}%',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: Phase6Engine.heroes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, int i) => InkWell(
                onTap: () => setState(() => selectedHero = i),
                child: Container(
                  width: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Color(Phase6Engine.heroes[i].color).withValues(alpha: i == selectedHero ? .8 : .25),
                    border: Border.all(color: i == selectedHero ? Colors.white : Colors.transparent),
                  ),
                  child: Center(child: Text(Phase6Engine.heroes[i].name, textAlign: TextAlign.center)),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _controlPanel() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('ENGINE DIRECTOR', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text('Difficulty $difficulty / 100'),
          Slider(value: difficulty.toDouble(), min: 1, max: 100, divisions: 99, onChanged: (double value) => setState(() => difficulty = value.round())),
          _card('HERO ENGINE', '12 original heroes • 6 roles • crit • armor/MR • range'),
          _card('JUNGLE ENGINE', 'Aggressive camps • respawn timers • buffs • Void Drake objective'),
          _card('AI ENGINE', 'Farm • gank • retreat • lane switch • tower defense • ambush • objective'),
          _card('3D WORLD ENGINE', 'Procedural terrain • river • structures • heroes • minion waves'),
          _card('TEMPORAL ENGINE', '90-frame history • rewind data model • temporal energy • VFX hooks'),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Temporal Warfare'), value: temporalOn, onChanged: (bool value) => setState(() => temporalOn = value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Dynamic Weather'), value: weather, onChanged: (bool value) => setState(() => weather = value)),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Day / Night'), value: dayNight, onChanged: (bool value) => setState(() => dayNight = value)),
          const SizedBox(height: 8),
          Text('AI preview: ${aiPreview.name} • jungle threat ${(jungle.threat(difficulty, .45) * 100).toInt()}%'),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, height: 58, child: FilledButton.icon(onPressed: start, icon: const Icon(Icons.rocket_launch), label: const Text('ENTER PHASE 6 WAR'))),
        ],
      );

  Widget _card(String title, String text) => Card(
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.cyanAccent)),
            const SizedBox(height: 4),
            Text(text),
          ]),
        ),
      );

  Widget _hud() => Material(
        color: Colors.black.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text('PHASE 6 • $difficulty • ${Phase6Engine.heroes[selectedHero].name} • TEMPORAL ${temporalEnergy.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
}

class _Phase6Overlay extends StatelessWidget {
  const _Phase6Overlay({required this.temporal, required this.energy, required this.weather, required this.dayNight});
  final bool temporal;
  final bool weather;
  final bool dayNight;
  final double energy;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _Phase6Painter(temporal: temporal, energy: energy, weather: weather, dayNight: dayNight));
}

class _Phase6Painter extends CustomPainter {
  const _Phase6Painter({required this.temporal, required this.energy, required this.weather, required this.dayNight});
  final bool temporal;
  final bool weather;
  final bool dayNight;
  final double energy;

  @override
  void paint(Canvas canvas, Size size) {
    final double time = DateTime.now().millisecondsSinceEpoch / 900;
    if (temporal) {
      final Paint paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2;
      for (int i = 0; i < 4; i++) {
        final double radius = (i + 1) * 65 + math.sin(time + i) * 12;
        canvas.drawCircle(Offset(size.width * .5, size.height * .52), radius, paint);
      }
    }
    if (weather) {
      final Paint paint = Paint()..strokeWidth = 1;
      for (int i = 0; i < 55; i++) {
        final double x = (i * 97.0 + time * 35) % size.width;
        final double y = (i * 53.0 + time * 80) % size.height;
        canvas.drawLine(Offset(x, y), Offset(x - 5, y + 12), paint);
      }
    }
    if (dayNight) {
      final Paint shade = Paint()..color = Colors.black.withValues(alpha: .08 + .06 * math.sin(time).abs());
      canvas.drawRect(Offset.zero & size, shade);
    }
    if (energy > 0 && temporal) {
      final Paint paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 3;
      canvas.drawArc(Rect.fromLTWH(size.width - 125, 20, 90, 90), -math.pi / 2, math.pi * 2 * energy / 100, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _Phase6Painter oldDelegate) => true;
}
