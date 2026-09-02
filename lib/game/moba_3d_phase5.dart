import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:three_js/three_js.dart' as three;

/// Phase 5: standalone 3D MOBA core.
/// The campaign difficulty is injected directly into combat, AI, waves,
/// towers, jungle and objectives. Artwork is original fantasy-styled.
class Moba3DPhase5 extends StatefulWidget {
  const Moba3DPhase5({super.key});
  @override State<Moba3DPhase5> createState() => _Moba3DPhase5State();
}

class _Moba3DPhase5State extends State<Moba3DPhase5> {
  late three.ThreeJS threeJs;
  final FocusNode focus = FocusNode();
  final Set<LogicalKeyboardKey> keys = <LogicalKeyboardKey>{};
  final List<_FUnit> enemies = <_FUnit>[];
  final List<_FUnit> minions = <_FUnit>[];
  final List<_FTower> towers = <_FTower>[];
  final List<_FShot> shots = <_FShot>[];
  final List<_FCamp> camps = <_FCamp>[];
  late _FUnit player;
  late _FCore enemyCore;
  late _FCore allyCore;
  Timer? uiTimer;
  Offset stick = Offset.zero;
  int difficulty = 75;
  int level = 1, xp = 0, gold = 600, kills = 0, deaths = 0, wave = 0;
  double hp = 1500, mana = 700, maxHp = 1500, maxMana = 700, atk = 125, armor = 18, speed = 11;
  double attackCd = 0, skill1Cd = 0, skill2Cd = 0, ultCd = 0, waveCd = 0, respawn = 0;
  bool started = false, paused = false, ended = false, won = false, shop = false, settings = false;
  bool attackHeld = false, temporal = true, sound = true;
  String? remap;
  final Map<String, LogicalKeyboardKey> bind = <String, LogicalKeyboardKey>{
    'up': LogicalKeyboardKey.keyW, 'down': LogicalKeyboardKey.keyS,
    'left': LogicalKeyboardKey.keyA, 'right': LogicalKeyboardKey.keyD,
    'attack': LogicalKeyboardKey.keyJ, 'skill1': LogicalKeyboardKey.keyK,
    'skill2': LogicalKeyboardKey.keyL, 'ultimate': LogicalKeyboardKey.keyU,
    'shop': LogicalKeyboardKey.keyB,
  };

  double get enemyHpScale => 1 + difficulty * .035;
  double get enemyDamageScale => 1 + difficulty * .022;
  double get enemySpeedScale => 1 + difficulty * .006;
  double get waveScale => 1 + difficulty * .018;
  String get rank => difficulty >= 90 ? 'NIGHTMARE' : difficulty >= 70 ? 'HELL' : difficulty >= 40 ? 'BRUTAL' : 'HARD';

  @override
  void initState() {
    super.initState();
    uiTimer = Timer.periodic(const Duration(milliseconds: 80), (_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    uiTimer?.cancel();
    focus.dispose();
    if (started) threeJs.dispose();
    super.dispose();
  }

  void _start() {
    setState(() => started = true);
    if (sound) SystemSound.play(SystemSoundType.click);
    threeJs = three.ThreeJS(
      onSetupComplete: () => setState(() {}), setup: _setup,
      settings: three.Settings(renderOptions: <String, dynamic>{'antialias': true, 'powerPreference': 'high-performance'}),
    );
  }

  Future<void> _setup() async {
    threeJs.camera = three.PerspectiveCamera(48, threeJs.width / math.max(1.0, threeJs.height), .1, 2200);
    threeJs.camera.position.setValues(-8, 58, 62);
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color(0.32, 0.62, 0.84);
    threeJs.scene.add(three.HemisphereLight(0xd7f5ff, 0x1c2b1d, 1.7));
    final sun = three.DirectionalLight(0xffffff, 2.8); sun.position.setValues(-80, 130, 50); threeJs.scene.add(sun);
    _map(); _structures(); _heroes(); _jungle(); _spawnWave();
    threeJs.camera.lookAt(three.Vector3(0, 0, 0));
    threeJs.addAnimationEvent(_tick);
  }

  three.Mesh _mesh(three.BufferGeometry geometry, int color, {double metal = .08, double rough = .72}) =>
      three.Mesh(geometry, three.MeshStandardMaterial(<three.MaterialProperty, dynamic>{
        three.MaterialProperty.color: color,
        three.MaterialProperty.metalness: metal,
        three.MaterialProperty.roughness: rough,
      }));

  void _map() {
    final ground = _mesh(three.BoxGeometry(180, 2, 120), 0x63ad52); ground.position.y = -1; threeJs.scene.add(ground);
    for (final z in <double>[-30, 0, 30]) {
      final lane = _mesh(three.BoxGeometry(170, .7, 13), 0x6c6963); lane.position.setValues(0, .15, z); threeJs.scene.add(lane);
      final edge = _mesh(three.BoxGeometry(170, .25, 15), 0xb39c72); edge.position.setValues(0, .5, z); threeJs.scene.add(edge);
    }
    final river = _mesh(three.BoxGeometry(14, .35, 120), 0x2e9ed1, metal: .05, rough: .25); river.position.y = .2; threeJs.scene.add(river);
    for (final z in <double>[-42, -14, 14, 42]) { final bridge = _mesh(three.BoxGeometry(19, 1.2, 8), 0x8c6848, rough: .9); bridge.position.setValues(0, .65, z); threeJs.scene.add(bridge); }
    final rnd = math.Random(2030);
    for (int i = 0; i < 125; i++) { final x = rnd.nextDouble() * 155 - 77.5, z = rnd.nextDouble() * 108 - 54; if (x.abs() < 19 || (z.abs() < 37 && x.abs() < 61)) continue; _tree(x, z, .75 + rnd.nextDouble() * 1.45); }
  }

  void _tree(double x, double z, double s) {
    final trunk = _mesh(three.CylinderGeometry(.7, 1.1, 5, 8), 0x6b4329); trunk.position.setValues(x, 2.5 * s, z); trunk.scale.setValues(s, s, s); threeJs.scene.add(trunk);
    final crown = _mesh(three.IcosahedronGeometry(3.1, 1), 0x2e7e42); crown.position.setValues(x, 6 * s, z); crown.scale.setValues(s, s, s); threeJs.scene.add(crown);
  }

  void _structures() {
    _base(-80, 0x3f7cff); _base(80, 0xe34d59);
    allyCore = _FCore(three.Vector3(-80, 7, 0), true, 5000); enemyCore = _FCore(three.Vector3(80, 7, 0), false, 5000);
    allyCore.mesh = _coreMesh(0x3f7cff); enemyCore.mesh = _coreMesh(0xe34d59); threeJs.scene.add(allyCore.mesh!); threeJs.scene.add(enemyCore.mesh!);
    for (final z in <double>[-30, 0, 30]) {
      for (int i = 0; i < 2; i++) { final t = _FTower(three.Vector3(38 + i * 16, 4, z), false, z, 1800 * enemyHpScale); t.mesh = _tower(0xe34d59); towers.add(t); threeJs.scene.add(t.mesh!); }
      for (int i = 0; i < 2; i++) { final t = _FTower(three.Vector3(-38 - i * 16, 4, z), true, z, 1800); t.mesh = _tower(0x3f7cff); towers.add(t); threeJs.scene.add(t.mesh!); }
    }
  }

  void _base(double x, int c) { final p = _mesh(three.CylinderGeometry(11, 13, 1.5, 8), 0x313c45); p.position.setValues(x, .75, 0); threeJs.scene.add(p); final r = _mesh(three.TorusGeometry(10, .65, 12, 48), c, metal: .2); r.rotation.x = math.pi / 2; r.position.setValues(x, 1.8, 0); threeJs.scene.add(r); }
  three.Group _coreMesh(int c) { final g = three.Group(); final a = _mesh(three.OctahedronGeometry(6.2, 1), c, metal: .25, rough: .35); a.position.y = 1; g.add(a); final r = _mesh(three.TorusGeometry(8, .55, 12, 48), c, metal: .25, rough: .3); r.rotation.x = math.pi / 2; r.position.y = -5; g.add(r); return g; }
  three.Group _tower(int c) { final g = three.Group(); final b = _mesh(three.CylinderGeometry(2.8, 3.5, 3.6, 8), 0x30373e, metal: .45); b.position.y = 1.8; g.add(b); final x = _mesh(three.OctahedronGeometry(2.25, 1), c, metal: .3, rough: .35); x.position.y = 5.5; g.add(x); final r = _mesh(three.TorusGeometry(3, .22, 8, 32), c, metal: .2); r.rotation.x = math.pi / 2; r.position.y = 3; g.add(r); return g; }

  void _heroes() {
    player = _FUnit(three.Vector3(-55, 0, 0), true, maxHp); player.damage = atk; player.speed = speed; player.mesh = _hero(0x3e8cff); threeJs.scene.add(player.mesh!);
    final positions = <three.Vector3>[three.Vector3(55, 0, -30), three.Vector3(55, 0, 0), three.Vector3(55, 0, 30), three.Vector3(34, 0, -12), three.Vector3(34, 0, 12)];
    for (final p in positions) { final e = _FUnit(p, false, 950 * enemyHpScale); e.maxHp = e.hp; e.damage = 55 * enemyDamageScale; e.speed = 4.3 * enemySpeedScale; e.lane = p.z; e.mesh = _hero(0xe95461); threeJs.scene.add(e.mesh!); enemies.add(e); }
  }

  three.Group _hero(int c) { final g = three.Group(); final body = _mesh(three.CapsuleGeometry(radius: 1.5, length: 2.8, capSegments: 8, radialSegments: 12), c, metal: .18, rough: .48); body.position.y = 3; g.add(body); final head = _mesh(three.SphereGeometry(1.15, 16, 12), 0xf0c4a0); head.position.y = 5.7; g.add(head); final armor = _mesh(three.BoxGeometry(3.7, .8, 1.9), 0x253344, metal: .5, rough: .4); armor.position.y = 3.9; g.add(armor); final weapon = _mesh(three.CylinderGeometry(.16, .16, 4.2, 8), 0xdceaff, metal: .7, rough: .2); weapon.rotation.z = math.pi / 2; weapon.position.setValues(2, 3, 0); g.add(weapon); return g; }

  void _jungle() { for (final p in <three.Vector3>[three.Vector3(-28, 1, -16), three.Vector3(-28, 1, 16), three.Vector3(28, 1, -16), three.Vector3(28, 1, 16)]) { final c = _FCamp(p, 900 * enemyHpScale); final g = three.Group(); final pad = _mesh(three.CylinderGeometry(3.4, 3.8, .5, 12), 0x3d4c43); pad.position.y = .25; g.add(pad); final monster = _mesh(three.IcosahedronGeometry(2, 1), 0xa06ad8, metal: .2); monster.position.y = 2.2; g.add(monster); c.mesh = g; camps.add(c); threeJs.scene.add(g); } }

  void _spawnWave() { if (ended) return; wave++; final count = math.min(6, 3 + difficulty ~/ 35); for (final z in <double>[-30, 0, 30]) { for (int i = 0; i < count; i++) { _minion(true, z, -66 - i * 3.0, i == count - 1); _minion(false, z, 66 + i * 3.0, i == count - 1); } } }
  void _minion(bool ally, double z, double x, bool ranged) { final hp0 = (330 + level * 22) * (ally ? 1 : waveScale); final m = _FUnit(three.Vector3(x, 1.5, z), ally, hp0); m.maxHp = hp0; m.lane = z; m.damage = ((ranged ? 42 : 58) * (ally ? 1 : waveScale)); m.ranged = ranged; m.speed = ranged ? 4.2 : 4.7; m.mesh = _minionMesh(ally, ranged); threeJs.scene.add(m.mesh!); minions.add(m); }
  three.Group _minionMesh(bool ally, bool ranged) { final g = three.Group(); final b = _mesh(three.CylinderGeometry(1, 1.2, 2.2, 8), ally ? 0x4d91ff : 0xe95661); b.position.y = 1.5; g.add(b); final h = _mesh(three.SphereGeometry(.75, 12, 8), 0xf0c2a0); h.position.y = 3; g.add(h); if (ranged) { final orb = _mesh(three.SphereGeometry(.35, 10, 8), 0xffd95a, metal: .1, rough: .3); orb.position.setValues(1, 2.1, 0); g.add(orb); } return g; }

  void _tick(double dt) {
    if (ended || paused) return;
    attackCd = math.max(0, attackCd - dt); skill1Cd = math.max(0, skill1Cd - dt); skill2Cd = math.max(0, skill2Cd - dt); ultCd = math.max(0, ultCd - dt); waveCd += dt;
    if (waveCd > math.max(7, 28 - difficulty * .16)) { waveCd = 0; _spawnWave(); }
    _player(dt); _ai(dt); _minions(dt); _towers(dt); _shots(dt); _cores(dt);
    if (!player.alive) { respawn -= dt; if (respawn <= 0) _respawn(); }
    if (enemyCore.hp <= 0) _finish(true); if (allyCore.hp <= 0) _finish(false);
  }

  void _player(double dt) { if (!player.alive) return; final dx = _axis('right', 'left') + stick.dx, dz = _axis('down', 'up') + stick.dy, len = math.sqrt(dx * dx + dz * dz); if (len > .05) { player.position.x += dx / math.max(1, len) * speed * dt; player.position.z += dz / math.max(1, len) * speed * dt; player.position.x = player.position.x.clamp(-72.0, 72.0).toDouble(); player.position.z = player.position.z.clamp(-52.0, 52.0).toDouble(); player.mesh?.position.copy(player.position); } mana = math.min(maxMana, mana + 20 * dt); if (attackHeld || keys.contains(bind['attack'])) _attack(); if (keys.contains(bind['skill1'])) _skill1(); if (keys.contains(bind['skill2'])) _skill2(); if (keys.contains(bind['ultimate'])) _ult(); }
  double _axis(String a, String b) => ((keys.contains(bind[a]) ? 1 : 0) - (keys.contains(bind[b]) ? 1 : 0)).toDouble();

  void _ai(double dt) { for (final e in enemies) { if (!e.alive) { e.respawn -= dt; if (e.respawn <= 0) { e.alive = true; e.hp = e.maxHp; e.position.setValues(55, 0, e.lane); e.mesh?.position.copy(e.position); e.mesh?.visible = true; } continue; } if (!player.alive) continue; final vx = player.position.x - e.position.x, vz = player.position.z - e.position.z, d = math.sqrt(vx * vx + vz * vz); final aggro = 42 + difficulty * .35; if (d < 13) { e.attackTimer -= dt; if (e.attackTimer <= 0) { e.attackTimer = math.max(.45, 1.05 - difficulty * .005); _hurt(e.damage); } } else if (d < aggro) { e.position.x += vx / math.max(1, d) * e.speed * dt; e.position.z += vz / math.max(1, d) * e.speed * dt; e.mesh?.position.copy(e.position); } else { e.position.x -= e.speed * .45 * dt; e.mesh?.position.copy(e.position); } } }

  void _minions(double dt) { for (final m in minions) { if (!m.alive) continue; final dir = m.allied ? 1 : -1; _FUnit? target; double best = 7; for (final o in minions) { if (!o.alive || o.allied == m.allied || (o.lane - m.lane).abs() > 4) continue; final d = _dist(m.position, o.position); if (d < best) { best = d; target = o; } } if (target != null) { m.attackTimer -= dt; if (m.attackTimer <= 0) { m.attackTimer = m.ranged ? .9 : .75; target.hp -= m.damage; if (target.hp <= 0) _killMinion(target); } } else { m.position.x += dir * m.speed * dt; m.mesh?.position.copy(m.position); } final t = _towerFor(m); if (t != null && _dist(m.position, t.position) < 8) { t.hp -= m.damage * dt; if (t.hp <= 0) _destroy(t); } if (m.allied && _allEnemyDown() && _dist(m.position, enemyCore.position) < 10) enemyCore.hp -= m.damage * dt; if (!m.allied && _allAllyDown() && _dist(m.position, allyCore.position) < 10) allyCore.hp -= m.damage * dt; } }
  _FTower? _towerFor(_FUnit m) { _FTower? best; double d0 = 8; for (final t in towers) { if (t.destroyed || t.allied == m.allied || (t.lane - m.lane).abs() > 4) continue; final d = _dist(m.position, t.position); if (d < d0) { d0 = d; best = t; } } return best; }

  void _towers(double dt) { for (final t in towers) { if (t.destroyed) continue; t.attackTimer -= dt; if (t.attackTimer > 0) continue; _FUnit? target; double d0 = 14; for (final m in minions) { if (!m.alive || m.allied == t.allied || (m.lane - t.lane).abs() > 5) continue; final d = _dist(t.position, m.position); if (d < d0) { d0 = d; target = m; } } if (target != null) { t.attackTimer = math.max(.55, 1.1 - difficulty * .004); _shot(t.position, target.position, 115 * (t.allied ? 1 : enemyDamageScale), target: target); } else if (!t.allied && player.alive && _dist(t.position, player.position) < 14) { t.attackTimer = 1; _shot(t.position, player.position, 155 * enemyDamageScale, hero: player); } } }

  void _shots(double dt) { for (final s in shots) { if (!s.alive) continue; final vx = s.target.x - s.pos.x, vy = s.target.y - s.pos.y, vz = s.target.z - s.pos.z, d = math.sqrt(vx * vx + vy * vy + vz * vz); if (d < 1.5) { s.alive = false; s.mesh?.visible = false; if (s.unit != null && s.unit!.alive) { s.unit!.hp -= s.damage; if (s.unit!.hp <= 0) _killMinion(s.unit!); } if (s.hero != null && s.hero!.alive) { if (s.hero == player) _hurt(s.damage); else { s.hero!.hp -= s.damage; if (s.hero!.hp <= 0) _killEnemy(s.hero!); } } } else { final step = math.min(d, 30 * dt); s.pos.x += vx / d * step; s.pos.y += vy / d * step; s.pos.z += vz / d * step; s.mesh?.position.copy(s.pos); } } shots.removeWhere((s) => !s.alive); }
  void _shot(three.Vector3 from, three.Vector3 to, double damage, {_FUnit? target, _FUnit? hero}) { final s = _FShot(from.clone(), to.clone(), damage, unit: target, hero: hero); final orb = _mesh(three.SphereGeometry(.35, 8, 8), 0xffd95a, metal: .2, rough: .25); orb.position.copy(from); s.mesh = orb; threeJs.scene.add(orb); shots.add(s); }

  void _cores(double dt) { if (_allEnemyDown() && player.alive && _dist(player.position, enemyCore.position) < 14 && keys.contains(bind['attack'])) enemyCore.hp -= atk * dt; if (_allAllyDown() && _dist(player.position, allyCore.position) < 10) allyCore.hp = math.max(1, allyCore.hp); }
  bool _allEnemyDown() => towers.where((t) => !t.allied && !t.destroyed).isEmpty;
  bool _allAllyDown() => towers.where((t) => t.allied && !t.destroyed).isEmpty;

  void _attack() { if (!player.alive || attackCd > 0) return; attackCd = .55; _FUnit? target; double d0 = 9; for (final e in enemies) { if (!e.alive) continue; final d = _dist(player.position, e.position); if (d < d0) { d0 = d; target = e; } } if (target != null) { target.hp -= atk; if (target.hp <= 0) _killEnemy(target); return; } for (final t in towers) { if (!t.destroyed && !t.allied && _dist(player.position, t.position) < 9) { t.hp -= atk; if (t.hp <= 0) _destroy(t); return; } } }
  void _skill1() { if (skill1Cd > 0 || mana < 90 || !player.alive) return; skill1Cd = 5; mana -= 90; for (final e in enemies) { if (e.alive && _dist(player.position, e.position) < 12) { e.hp -= 180 + level * 30; if (e.hp <= 0) _killEnemy(e); } } }
  void _skill2() { if (skill2Cd > 0 || mana < 110 || !player.alive) return; skill2Cd = 8; mana -= 110; hp = math.min(maxHp, hp + 260 + level * 25); for (final e in enemies) { if (e.alive && _dist(player.position, e.position) < 8) { e.hp -= 120; if (e.hp <= 0) _killEnemy(e); } } }
  void _ult() { if (ultCd > 0 || mana < 220 || !player.alive) return; ultCd = 35; mana -= 220; for (final e in enemies) { if (e.alive && _dist(player.position, e.position) < 17) { e.hp -= 420 + level * 70; if (e.hp <= 0) _killEnemy(e); } } if (temporal) _timePulse(); }
  void _timePulse() { final ring = _mesh(three.TorusGeometry(15, .22, 8, 64), 0x9d63ff, metal: .15, rough: .3); ring.position.copy(player.position); ring.rotation.x = math.pi / 2; threeJs.scene.add(ring); Timer(const Duration(milliseconds: 650), () { ring.visible = false; }); }

  void _hurt(double damage) { if (!player.alive) return; final actual = damage * 100 / (100 + armor); hp -= actual; if (hp <= 0) _killPlayer(); }
  void _killPlayer() { if (!player.alive) return; player.alive = false; deaths++; respawn = 6 + difficulty * .04; hp = 0; player.mesh?.visible = false; if (sound) SystemSound.play(SystemSoundType.alert); }
  void _respawn() { player.alive = true; hp = maxHp; mana = maxMana; player.position.setValues(-55, 0, 0); player.mesh?.position.copy(player.position); player.mesh?.visible = true; }
  void _killEnemy(_FUnit e) { e.alive = false; e.hp = 0; e.respawn = 6 + difficulty * .03; e.mesh?.visible = false; kills++; gold += 180; _gainXp(120); }
  void _killMinion(_FUnit m) { m.alive = false; m.hp = 0; m.mesh?.visible = false; gold += m.allied ? 0 : 25; if (!m.allied) _gainXp(22); }
  void _gainXp(int amount) { xp += amount; while (xp >= level * 420 && level < 15) { xp -= level * 420; level++; maxHp += 120; maxMana += 55; atk += 14; armor += 2; hp = maxHp; mana = maxMana; } }
  void _destroy(_FTower t) { if (t.destroyed) return; t.destroyed = true; t.hp = 0; t.mesh?.visible = false; gold += 120; _gainXp(90); }
  void _finish(bool victory) { if (ended) return; ended = true; won = victory; if (sound) SystemSound.play(victory ? SystemSoundType.click : SystemSoundType.alert); }
  double _dist(three.Vector3 a, three.Vector3 b) { final dx = a.x - b.x, dz = a.z - b.z; return math.sqrt(dx * dx + dz * dz); }

  @override
  Widget build(BuildContext context) {
    if (!started) return _menu();
    return Focus(
      focusNode: focus, autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) { if (remap != null) { bind[remap!] = event.logicalKey; remap = null; return KeyEventResult.handled; } keys.add(event.logicalKey); if (event.logicalKey == bind['shop']) setState(() => shop = !shop); return KeyEventResult.handled; }
        if (event is KeyUpEvent) keys.remove(event.logicalKey);
        return KeyEventResult.handled;
      },
      child: Scaffold(body: Stack(children: [
        Positioned.fill(child: threeJs.build()),
        _hud(),
        if (temporal) const IgnorePointer(child: _TemporalFX()),
        if (shop) _shop(),
        if (settings) _keysPanel(),
        if (ended) _result(),
      ])),
    );
  }

  Widget _menu() => Scaffold(body: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xff07152a), Color(0xff241046), Color(0xff08131b)])), child: SafeArea(child: Center(child: SingleChildScrollView(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 820), child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [const Text('ARENA LEGENDS', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: 3)), const Text('PHASE 5 • CORE ENGINE', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, letterSpacing: 2)), const SizedBox(height: 20), Card(color: Colors.black54, child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [Row(children: [const Text('BRUTALITY', style: TextStyle(fontWeight: FontWeight.w900)), const Spacer(), Text('$difficulty / 100', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900))]), Slider(value: difficulty.toDouble(), min: 1, max: 100, divisions: 99, onChanged: (v) => setState(() => difficulty = v.round())), Align(alignment: Alignment.centerLeft, child: Text(rank, style: const TextStyle(fontSize: 24, color: Colors.redAccent, fontWeight: FontWeight.w900))), const SizedBox(height: 8), const Text('Difficulty now directly scales enemy HP/damage/speed, wave size, spawn pressure, tower durability, jungle HP and respawn pressure.'),])), const SizedBox(height: 12), Card(color: Colors.black54, child: Column(children: [SwitchListTile(title: const Text('TEMPORAL WARFARE'), subtitle: const Text('4D-inspired gameplay layer: time pulse/temporal VFX.'), value: temporal, onChanged: (v) => setState(() => temporal = v)), SwitchListTile(title: const Text('SYSTEM BATTLE SFX'), subtitle: const Text('System feedback for combat events; authored music/SFX assets can be added later.'), value: sound, onChanged: (v) => setState(() => sound = v))])), const SizedBox(height: 18), SizedBox(width: double.infinity, height: 62, child: FilledButton.icon(onPressed: _start, icon: const Icon(Icons.sports_martial_arts), label: Text('START $rank WAR', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)))), const SizedBox(height: 12), const Text('TRUE 3D • 3 LANES • JUNGLE • TURRETS • CORE WAR • DEATH/RESPAWN • LEVEL 1–15 • REMAPPABLE KEYBOARD', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, fontSize: 11)), ]))))))));

  Widget _hud() => Positioned.fill(child: Stack(children: [Positioned(top: 8, left: 8, child: SafeArea(child: DecoratedBox(decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(9), child: Text('LV $level  HP ${hp.ceil()}/${maxHp.ceil()}  MP ${mana.ceil()}  K/D $kills/$deaths  GOLD $gold  WAVE $wave', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900))))), Positioned(top: 8, right: 8, child: SafeArea(child: Row(children: [IconButton(onPressed: () => setState(() => paused = !paused), icon: Icon(paused ? Icons.play_arrow : Icons.pause)), IconButton(onPressed: () => setState(() => settings = !settings), icon: const Icon(Icons.settings))]))), Positioned(bottom: 14, left: 14, child: GestureDetector(onPanUpdate: (d) { stick += d.delta / 45; final l = stick.distance; if (l > 1) stick /= l; }, onPanEnd: (_) => setState(() => stick = Offset.zero), child: Container(width: 125, height: 125, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black45, border: Border.all(color: Colors.white30, width: 2)), child: const Center(child: Icon(Icons.control_camera, size: 38, color: Colors.white70))))), Positioned(bottom: 18, right: 18, child: Row(children: [_button('ATK', bind['attack']!, () => setState(() => attackHeld = !attackHeld)), _button('S1', bind['skill1']!, _skill1), _button('S2', bind['skill2']!, _skill2), _button('ULT', bind['ultimate']!, _ult)])), Positioned(bottom: 5, left: 150, child: SafeArea(child: Text('TURRETS → CORE • $rank', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70))))]));
  Widget _button(String title, LogicalKeyboardKey key, VoidCallback action) => Padding(padding: const EdgeInsets.all(5), child: GestureDetector(onTap: action, child: Container(width: 66, height: 66, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(.72), border: Border.all(color: Colors.white30, width: 2)), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(key.keyLabel, style: const TextStyle(fontSize: 9, color: Colors.white54))])))));
  Widget _shop() => Center(child: Card(color: Colors.black.withOpacity(.92), child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('WAR FORGE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), _buy('BLADE +25 ATK', 220, () => setState(() => atk += 25)), _buy('ARMOR +10', 220, () => setState(() => armor += 10)), _buy('BOOTS +2 SPEED', 180, () => setState(() => speed += 2)), _buy('CRYSTAL +180 MAX MP', 260, () => setState(() { maxMana += 180; mana = maxMana; })), TextButton(onPressed: () => setState(() => shop = false), child: const Text('CLOSE'))])));
  Widget _buy(String text, int cost, VoidCallback effect) => ListTile(title: Text(text), trailing: FilledButton(onPressed: gold >= cost ? () { gold -= cost; effect(); } : null, child: Text('$cost')));
  Widget _keysPanel() => Center(child: Card(color: Colors.black.withOpacity(.94), child: Padding(padding: const EdgeInsets.all(18), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('KEYBOARD CONTROL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)), ...bind.keys.map((k) => ListTile(title: Text(k.toUpperCase()), trailing: TextButton(onPressed: () => setState(() => remap = k), child: Text(remap == k ? 'PRESS KEY' : bind[k]!.keyLabel)))), TextButton(onPressed: () => setState(() => settings = false), child: const Text('CLOSE'))])));
  Widget _result() => Center(child: Container(color: Colors.black87, padding: const EdgeInsets.all(30), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(won ? 'VICTORY' : 'DEFEAT', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: won ? Colors.greenAccent : Colors.redAccent)), const SizedBox(height: 8), Text(won ? 'Enemy core destroyed.' : 'Your core has fallen.'), const SizedBox(height: 18), FilledButton(onPressed: () => setState(() { ended = false; won = false; }), child: const Text('RETURN'))])));
}

class _FUnit { _FUnit(this.position, this.allied, this.hp); three.Vector3 position; final bool allied; double hp; double maxHp; double damage = 0; double speed = 4; double lane = 0; double attackTimer = 0; double respawn = 0; bool alive = true; bool ranged = false; three.Group? mesh; }
class _FTower { _FTower(this.position, this.allied, this.lane, this.hp); final three.Vector3 position; final bool allied; final double lane; double hp; double attackTimer = 0; bool destroyed = false; three.Group? mesh; }
class _FCore { _FCore(this.position, this.allied, this.hp); final three.Vector3 position; final bool allied; double hp; three.Group? mesh; }
class _FCamp { _FCamp(this.position, this.hp); final three.Vector3 position; double hp; three.Group? mesh; }
class _FShot { _FShot(this.pos, this.target, this.damage, {this.unit, this.hero}); three.Vector3 pos; final three.Vector3 target; final double damage; final _FUnit? unit; final _FUnit? hero; bool alive = true; three.Mesh? mesh; }

class _TemporalFX extends StatefulWidget { const _TemporalFX(); @override State<_TemporalFX> createState() => _TemporalFXState(); }
class _TemporalFXState extends State<_TemporalFX> { double phase = 0; Timer? timer; @override void initState() { super.initState(); timer = Timer.periodic(const Duration(milliseconds: 70), (_) { if (mounted) setState(() => phase += .05); }); } @override void dispose() { timer?.cancel(); super.dispose(); } @override Widget build(BuildContext context) => CustomPaint(painter: _TemporalPainter(phase)); }
class _TemporalPainter extends CustomPainter { const _TemporalPainter(this.phase); final double phase; @override void paint(Canvas canvas, Size size) { final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = Colors.cyanAccent.withOpacity(.015 + math.sin(phase).abs() * .018); for (int i = 0; i < 6; i++) { final w = size.width * (.35 + i * .11), h = size.height * (.18 + i * .04); canvas.drawOval(Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: w, height: h), p); } } @override bool shouldRepaint(covariant _TemporalPainter oldDelegate) => oldDelegate.phase != phase; }
