import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:three_js/three_js.dart' as three;

/// Phase 2: a playable true-3D MOBA core.
///
/// The battlefield and combat actors are real 3D meshes. Canvas is used only
/// for HUD/minimap, never for the game world.
class Moba3DPhase2 extends StatefulWidget {
  const Moba3DPhase2({super.key});

  @override
  State<Moba3DPhase2> createState() => _Moba3DPhase2State();
}

class _Moba3DPhase2State extends State<Moba3DPhase2> {
  late three.ThreeJS threeJs;
  final FocusNode focusNode = FocusNode();
  final Set<LogicalKeyboardKey> keys = <LogicalKeyboardKey>{};
  final List<_Hero3D> enemies = <_Hero3D>[];
  final List<_Minion3D> minions = <_Minion3D>[];
  final List<_Tower3D> towers = <_Tower3D>[];
  final List<_Projectile3D> projectiles = <_Projectile3D>[];
  final List<_Camp3D> camps = <_Camp3D>[];

  late _Hero3D player;
  late _Core3D playerCore;
  late _Core3D enemyCore;

  Offset joystick = Offset.zero;
  bool attackHeld = false;
  bool ended = false;
  bool victory = false;
  bool shopOpen = false;
  bool settingsOpen = false;
  bool paused = false;

  int level = 1;
  int xp = 0;
  int gold = 600;
  int kills = 0;
  int deaths = 0;
  int wave = 0;
  int difficulty = 1;
  double matchTime = 0;
  double attackCooldown = 0;
  double skill1Cooldown = 0;
  double skill2Cooldown = 0;
  double ultimateCooldown = 0;
  double respawnTimer = 0;
  double waveTimer = 0;
  double playerMaxHp = 1200;
  double playerHp = 1200;
  double playerMaxMana = 600;
  double playerMana = 600;
  double attackDamage = 110;
  double armor = 12;
  double moveSpeed = 10;
  int skillPower = 0;

  final Map<String, LogicalKeyboardKey> bindings = <String, LogicalKeyboardKey>{
    'up': LogicalKeyboardKey.keyW,
    'down': LogicalKeyboardKey.keyS,
    'left': LogicalKeyboardKey.keyA,
    'right': LogicalKeyboardKey.keyD,
    'attack': LogicalKeyboardKey.keyJ,
    'skill1': LogicalKeyboardKey.keyK,
    'skill2': LogicalKeyboardKey.keyL,
    'ultimate': LogicalKeyboardKey.keyU,
    'shop': LogicalKeyboardKey.keyB,
  };
  String? waitingBinding;

  Timer? hudTimer;

  @override
  void initState() {
    super.initState();
    threeJs = three.ThreeJS(
      onSetupComplete: () => setState(() {}),
      setup: setup,
      settings: three.Settings(renderOptions: <String, dynamic>{
        'antialias': true,
        'powerPreference': 'high-performance',
      }),
    );
    hudTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    hudTimer?.cancel();
    focusNode.dispose();
    threeJs.dispose();
    super.dispose();
  }

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(
      48,
      threeJs.width / math.max(1.0, threeJs.height),
      0.1,
      2000,
    );
    threeJs.camera.position.setValues(-8, 58, 62);
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color(0.38, 0.72, 0.94);

    threeJs.scene.add(three.HemisphereLight(0xc9efff, 0x26351f, 1.6));
    final sun = three.DirectionalLight(0xffffff, 2.6);
    sun.position.setValues(-70, 120, 40);
    threeJs.scene.add(sun);

    _buildMap();
    _buildStructures();
    _buildHeroes();
    _buildCamps();
    _spawnWave();
    threeJs.camera.lookAt(three.Vector3(0, 0, 0));
    threeJs.addAnimationEvent(_tick);
  }

  three.Mesh _mesh(three.BufferGeometry geometry, int color,
      {double opacity = 1}) {
    final material = three.MeshStandardMaterial(<three.MaterialProperty, dynamic>{
      three.MaterialProperty.color: color,
      three.MaterialProperty.roughness: 0.72,
      three.MaterialProperty.metalness: 0.08,
      if (opacity < 1) three.MaterialProperty.opacity: opacity,
      if (opacity < 1) three.MaterialProperty.transparent: true,
    });
    return three.Mesh(geometry, material);
  }

  void _buildMap() {
    final ground = _mesh(three.BoxGeometry(180, 2, 120), 0x5da84d);
    ground.position.y = -1;
    threeJs.scene.add(ground);

    for (final z in <double>[-30, 0, 30]) {
      final shoulder = _mesh(three.BoxGeometry(170, 0.35, 15), 0x88847d);
      shoulder.position.setValues(0, -0.15, z);
      threeJs.scene.add(shoulder);
      final lane = _mesh(three.BoxGeometry(170, 0.8, 11), 0x686660);
      lane.position.setValues(0, 0.1, z);
      threeJs.scene.add(lane);
    }

    final river = _mesh(three.BoxGeometry(14, 0.25, 120), 0x2e9ed1);
    river.position.y = 0.2;
    threeJs.scene.add(river);
    for (final z in <double>[-42, -14, 14, 42]) {
      final bridge = _mesh(three.BoxGeometry(19, 1.0, 8), 0x9b7049);
      bridge.position.setValues(0, 0.6, z);
      threeJs.scene.add(bridge);
    }

    final random = math.Random(2030);
    for (int i = 0; i < 110; i++) {
      final x = random.nextDouble() * 155 - 77.5;
      final z = random.nextDouble() * 108 - 54;
      if (x.abs() < 20 || (z.abs() < 38 && x.abs() < 62)) continue;
      _tree(x, z, 0.8 + random.nextDouble() * 1.5);
    }
    for (int i = 0; i < 42; i++) {
      final x = random.nextDouble() * 150 - 75;
      final z = random.nextDouble() * 100 - 50;
      if (x.abs() < 20) continue;
      final rock = _mesh(three.IcosahedronGeometry(1.2 + random.nextDouble() * 2.5, 1), 0x68716d);
      rock.position.setValues(x, 1, z);
      threeJs.scene.add(rock);
    }
  }

  void _tree(double x, double z, double s) {
    final trunk = _mesh(three.CylinderGeometry(0.7, 1.1, 5, 8), 0x6b4329);
    trunk.position.setValues(x, 2.5 * s, z);
    trunk.scale.setValues(s, s, s);
    threeJs.scene.add(trunk);
    final crown = _mesh(three.IcosahedronGeometry(3.2, 1), 0x2e7e42);
    crown.position.setValues(x, 6.0 * s, z);
    crown.scale.setValues(s, s, s);
    threeJs.scene.add(crown);
  }

  void _base(double x, int color) {
    final pad = _mesh(three.CylinderGeometry(11, 13, 1.5, 8), 0x313c45);
    pad.position.setValues(x, 0.75, 0);
    threeJs.scene.add(pad);
    final ring = _mesh(three.TorusGeometry(10, 0.65, 12, 48), color);
    ring.position.setValues(x, 1.8, 0);
    ring.rotation.x = math.pi / 2;
    threeJs.scene.add(ring);
  }

  void _buildStructures() {
    _base(-80, 0x3f7cff);
    _base(80, 0xe34d59);
    playerCore = _Core3D(three.Vector3(-80, 7, 0), true, 3000);
    enemyCore = _Core3D(three.Vector3(80, 7, 0), false, 3000);
    playerCore.mesh = _coreMesh(0x3f7cff);
    enemyCore.mesh = _coreMesh(0xe34d59);
    threeJs.scene.add(playerCore.mesh!);
    threeJs.scene.add(enemyCore.mesh!);

    for (final z in <double>[-30, 0, 30]) {
      for (int i = 0; i < 2; i++) {
        final x = 38 + i * 16;
        final t = _Tower3D(three.Vector3(x, 4, z), false, z);
        t.mesh = _towerMesh(0xe34d59);
        threeJs.scene.add(t.mesh!);
        towers.add(t);
      }
      for (int i = 0; i < 2; i++) {
        final x = -38 - i * 16;
        final t = _Tower3D(three.Vector3(x, 4, z), true, z);
        t.mesh = _towerMesh(0x3f7cff);
        threeJs.scene.add(t.mesh!);
        towers.add(t);
      }
    }
  }

  three.Group _towerMesh(int color) {
    final g = three.Group();
    final base = _mesh(three.CylinderGeometry(2.8, 3.5, 3.6, 8), 0x30373e);
    base.position.y = 1.8;
    g.add(base);
    final core = _mesh(three.OctahedronGeometry(2.25, 1), color);
    core.position.y = 5.5;
    g.add(core);
    final ring = _mesh(three.TorusGeometry(3.0, 0.22, 8, 32), color);
    ring.rotation.x = math.pi / 2;
    ring.position.y = 3.0;
    g.add(ring);
    return g;
  }

  three.Group _coreMesh(int color) {
    final g = three.Group();
    final crystal = _mesh(three.OctahedronGeometry(6.2, 1), color);
    crystal.position.y = 1;
    crystal.scale.setValues(1, 1.25, 1);
    g.add(crystal);
    final ring = _mesh(three.TorusGeometry(8, 0.55, 12, 48), color);
    ring.rotation.x = math.pi / 2;
    ring.position.y = -5;
    g.add(ring);
    return g;
  }

  void _buildHeroes() {
    player = _Hero3D(three.Vector3(-55, 0, 0), true, 1200, 600);
    player.mesh = _heroMesh(0x3e8cff);
    threeJs.scene.add(player.mesh!);

    final positions = <three.Vector3>[
      three.Vector3(55, 0, -30),
      three.Vector3(55, 0, 0),
      three.Vector3(55, 0, 30),
      three.Vector3(30, 0, -8),
      three.Vector3(30, 0, 8),
    ];
    for (int i = 0; i < positions.length; i++) {
      final e = _Hero3D(positions[i], false, 800 + difficulty * 100, 450);
      e.mesh = _heroMesh(0xe95461);
      e.damage = 48 + difficulty * 8;
      e.speed = 4.0 + difficulty * 0.25;
      threeJs.scene.add(e.mesh!);
      enemies.add(e);
    }
  }

  three.Group _heroMesh(int color) {
    final g = three.Group();
    final body = _mesh(
      three.CapsuleGeometry(radius: 1.5, length: 2.8, capSegments: 8, radialSegments: 12),
      color,
    );
    body.position.y = 3;
    g.add(body);
    final head = _mesh(three.SphereGeometry(1.15, 16, 12), 0xf0c4a0);
    head.position.y = 5.7;
    g.add(head);
    final armor = _mesh(three.BoxGeometry(3.7, 0.8, 1.9), 0x253344);
    armor.position.y = 3.9;
    g.add(armor);
    final weapon = _mesh(three.CylinderGeometry(0.16, 0.16, 4.2, 8), 0xdceaff);
    weapon.rotation.z = math.pi / 2;
    weapon.position.setValues(2.0, 3.0, 0);
    g.add(weapon);
    final aura = _mesh(three.TorusGeometry(2.25, 0.12, 8, 40), color);
    aura.rotation.x = math.pi / 2;
    aura.position.y = 0.25;
    g.add(aura);
    return g;
  }

  void _buildCamps() {
    final spots = <three.Vector3>[
      three.Vector3(-28, 1, -16),
      three.Vector3(-28, 1, 16),
      three.Vector3(28, 1, -16),
      three.Vector3(28, 1, 16),
    ];
    for (final p in spots) {
      final camp = _Camp3D(p, 600 + difficulty * 100);
      camp.mesh = _campMesh();
      threeJs.scene.add(camp.mesh!);
      camps.add(camp);
    }
  }

  three.Group _campMesh() {
    final g = three.Group();
    final pad = _mesh(three.CylinderGeometry(3.4, 3.8, 0.5, 12), 0x3d4c43);
    pad.position.y = 0.25;
    g.add(pad);
    final monster = _mesh(three.IcosahedronGeometry(2.0, 1), 0xa06ad8);
    monster.position.y = 2.2;
    g.add(monster);
    return g;
  }

  void _spawnWave() {
    if (ended) return;
    wave++;
    for (final z in <double>[-30, 0, 30]) {
      for (int i = 0; i < 3; i++) {
        _spawnMinion(true, z, -66 - i * 3, i == 2);
        _spawnMinion(false, z, 66 + i * 3, i == 2);
      }
    }
  }

  void _spawnMinion(bool allied, double laneZ, double x, bool ranged) {
    final hp = (allied ? 360 : 330) + level * 18 + difficulty * 35;
    final m = _Minion3D(
      three.Vector3(x, 1.5, laneZ),
      allied,
      hp,
      ranged,
      laneZ,
    );
    m.damage = (ranged ? 38 : 52) + difficulty * 5;
    m.mesh = _minionMesh(allied, ranged);
    threeJs.scene.add(m.mesh!);
    minions.add(m);
  }

  three.Group _minionMesh(bool allied, bool ranged) {
    final color = allied ? 0x4d91ff : 0xe95661;
    final g = three.Group();
    final body = _mesh(three.CylinderGeometry(1.0, 1.2, 2.2, 8), color);
    body.position.y = 1.5;
    g.add(body);
    final head = _mesh(three.SphereGeometry(0.75, 12, 8), 0xf0c2a0);
    head.position.y = 3.0;
    g.add(head);
    if (ranged) {
      final orb = _mesh(three.SphereGeometry(0.35, 10, 8), 0xffd95a);
      orb.position.setValues(1.0, 2.1, 0);
      g.add(orb);
    } else {
      final shield = _mesh(three.BoxGeometry(1.5, 1.5, 0.35), 0x2d3744);
      shield.position.setValues(0, 1.8, 0.9);
      g.add(shield);
    }
    return g;
  }

  void _tick(double dt) {
    if (ended || paused) return;
    matchTime += dt;
    attackCooldown = math.max(0, attackCooldown - dt);
    skill1Cooldown = math.max(0, skill1Cooldown - dt);
    skill2Cooldown = math.max(0, skill2Cooldown - dt);
    ultimateCooldown = math.max(0, ultimateCooldown - dt);
    waveTimer += dt;

    if (waveTimer >= math.max(10.0, 28.0 - difficulty * 1.2)) {
      waveTimer = 0;
      _spawnWave();
    }

    _updatePlayer(dt);
    _updateEnemies(dt);
    _updateMinions(dt);
    _updateTowers(dt);
    _updateCamps(dt);
    _updateProjectiles(dt);
    _updateCore(dt);
    _cleanup();

    if (!player.alive) {
      respawnTimer -= dt;
      if (respawnTimer <= 0) _respawnPlayer();
    }
    if (enemyCore.hp <= 0) _finish(true);
    if (playerCore.hp <= 0) _finish(false);
  }

  void _updatePlayer(double dt) {
    if (!player.alive) return;
    final dx = _axis('right', 'left') + joystick.dx;
    final dz = _axis('down', 'up') + joystick.dy;
    final len = math.sqrt(dx * dx + dz * dz);
    if (len > 0.05) {
      player.position.x += dx / math.max(1.0, len) * moveSpeed * dt;
      player.position.z += dz / math.max(1.0, len) * moveSpeed * dt;
      player.position.x = player.position.x.clamp(-72.0, 72.0).toDouble();
      player.position.z = player.position.z.clamp(-52.0, 52.0).toDouble();
      player.mesh?.position.copy(player.position);
    }
    playerMana = math.min(playerMaxMana, playerMana + 18 * dt);
    if (attackHeld || keys.contains(bindings['attack'])) _basicAttack();
  }

  double _axis(String positive, String negative) {
    final p = keys.contains(bindings[positive]);
    final n = keys.contains(bindings[negative]);
    return (p ? 1.0 : 0.0) - (n ? 1.0 : 0.0);
  }

  void _updateEnemies(double dt) {
    for (final e in enemies) {
      if (!e.alive) {
        e.respawn -= dt;
        if (e.respawn <= 0) {
          e.alive = true;
          e.hp = e.maxHp;
          e.position.setValues(55, 0, e.laneZ);
          e.mesh?.position.copy(e.position);
          e.mesh?.visible = true;
        }
        continue;
      }
      final target = _nearestEnemyTarget(e);
      if (target == null) continue;
      final vx = target.position.x - e.position.x;
      final vz = target.position.z - e.position.z;
      final d = math.sqrt(vx * vx + vz * vz);
      if (d < 13) {
        e.attackTimer -= dt;
        if (e.attackTimer <= 0) {
          e.attackTimer = 1.0;
          if (target == player) {
            _damagePlayer(e.damage);
          } else {
            target.hp -= e.damage;
          }
        }
      } else if (d < 70) {
        e.position.x += vx / math.max(1.0, d) * e.speed * dt;
        e.position.z += vz / math.max(1.0, d) * e.speed * dt;
        e.mesh?.position.copy(e.position);
      }
    }
  }

  _Hero3D? _nearestEnemyTarget(_Hero3D e) {
    if (player.alive) {
      final d = _distance(e.position, player.position);
      if (d < 22) return player;
    }
    _Minion3D? best;
    var bestD = double.infinity;
    for (final m in minions) {
      if (!m.alive || m.allied == e.allied) continue;
      final d = _distance(e.position, m.position);
      if (d < bestD && d < 24) {
        best = m;
        bestD = d;
      }
    }
    return null;
  }

  void _updateMinions(double dt) {
    for (final m in minions) {
      if (!m.alive) continue;
      final dir = m.allied ? 1.0 : -1.0;
      _Minion3D? target;
      var best = double.infinity;
      for (final other in minions) {
        if (!other.alive || other.allied == m.allied || (other.laneZ - m.laneZ).abs() > 4) continue;
        final d = _distance(m.position, other.position);
        if (d < best && d < 7) {
          target = other;
          best = d;
        }
      }
      if (target != null) {
        m.attackTimer -= dt;
        if (m.attackTimer <= 0) {
          m.attackTimer = m.ranged ? 0.9 : 0.75;
          target.hp -= m.damage;
          if (target.hp <= 0) _killMinion(target);
        }
      } else {
        m.position.x += dir * (m.ranged ? 4.2 : 4.7) * dt;
        m.mesh?.position.copy(m.position);
      }
      final enemyTowers = towers.where((t) => !t.allied && !t.destroyed && (t.laneZ - m.laneZ).abs() < 4);
      final alliedTowers = towers.where((t) => t.allied && !t.destroyed && (t.laneZ - m.laneZ).abs() < 4);
      final targetTower = m.allied ? enemyTowers.fold<_Tower3D?>(null, _closestTower(m)) : alliedTowers.fold<_Tower3D?>(null, _closestTower(m));
      if (targetTower != null && _distance(m.position, targetTower.position) < 8) {
        targetTower.hp -= m.damage * dt;
        if (targetTower.hp <= 0) _destroyTower(targetTower);
      }
      if (m.allied && _distance(m.position, enemyCore.position) < 10 && _allEnemyTowersDown()) {
        enemyCore.hp -= m.damage * dt;
      }
      if (!m.allied && _distance(m.position, playerCore.position) < 10 && _allAlliedTowersDown()) {
        playerCore.hp -= m.damage * dt;
      }
    }
  }

  _Tower3D? Function(_Tower3D?, _Tower3D) _closestTower(_Minion3D m) {
    return (_Tower3D? current, _Tower3D candidate) {
      if (current == null) return candidate;
      return _distance(m.position, candidate.position) < _distance(m.position, current) ? candidate : current;
    };
  }

  void _updateTowers(double dt) {
    for (final t in towers) {
      if (t.destroyed) continue;
      t.attackTimer -= dt;
      if (t.attackTimer > 0) continue;
      _Minion3D? targetMinion;
      var best = 13.0;
      for (final m in minions) {
        if (!m.alive || m.allied == t.allied || (m.laneZ - t.laneZ).abs() > 5) continue;
        final d = _distance(t.position, m.position);
        if (d < best) {
          best = d;
          targetMinion = m;
        }
      }
      if (targetMinion != null) {
        t.attackTimer = 1.0;
        _fireProjectile(t.position, targetMinion.position, t.allied, 95 + difficulty * 8, targetMinion);
      } else if (!t.allied && player.alive && _distance(t.position, player.position) < 13) {
        t.attackTimer = 1.0;
        _fireProjectile(t.position, player.position, false, 120 + difficulty * 10, null);
      }
    }
  }

  void _updateCamps(double dt) {
    for (final c in camps) {
      if (!c.alive) {
        c.respawn -= dt;
        if (c.respawn <= 0) {
          c.alive = true;
          c.hp = c.maxHp;
          c.mesh?.visible = true;
        }
      }
    }
  }

  void _updateProjectiles(double dt) {
    for (final p in projectiles) {
      if (!p.alive) continue;
      final vx = p.target.x - p.position.x;
      final vz = p.target.z - p.position.z;
      final d = math.sqrt(vx * vx + (p.target.y - p.position.y) * (p.target.y - p.position.y) + vz * vz);
      if (d < 1.5) {
        p.alive = false;
        p.mesh?.visible = false;
        if (p.targetUnit != null && p.targetUnit!.alive) p.targetUnit!.hp -= p.damage;
        if (p.damagePlayer && player.alive) _damagePlayer(p.damage);
      } else {
        p.position.x += vx / math.max(1.0, d) * p.speed * dt;
        p.position.y += (p.target.y - p.position.y) / math.max(1.0, d) * p.speed * dt;
        p.position.z += vz / math.max(1.0, d) * p.speed * dt;
        p.mesh?.position.copy(p.position);
      }
    }
  }

  void _updateCore(double dt) {
    if (_allEnemyTowersDown() && player.alive && _distance(player.position, enemyCore.position) < 13 && keys.contains(bindings['attack'])) {
      enemyCore.hp -= attackDamage * dt;
    }
  }

  void _basicAttack() {
    if (attackCooldown > 0 || !player.alive || ended) return;
    attackCooldown = 0.42;
    _attackNearest(attackDamage, 16);
  }

  void _attackNearest(double damage, double range) {
    _Hero3D? hero;
    var best = double.infinity;
    for (final e in enemies) {
      if (!e.alive) continue;
      final d = _distance(player.position, e.position);
      if (d < best && d < range) {
        best = d;
        hero = e;
      }
    }
    if (hero != null) {
      _fireProjectile(player.position, hero.position, true, damage, null, heroTarget: hero);
      return;
    }
    _Tower3D? tower;
    for (final t in towers) {
      if (t.allied || t.destroyed) continue;
      final d = _distance(player.position, t.position);
      if (d < range && (tower == null || d < _distance(player.position, tower.position))) tower = t;
    }
    if (tower != null) {
      _fireProjectile(player.position, tower.position, true, damage, null, towerTarget: tower);
    } else if (_allEnemyTowersDown() && _distance(player.position, enemyCore.position) < range) {
      enemyCore.hp -= damage;
    }
  }

  void _skill1() {
    if (skill1Cooldown > 0 || playerMana < 80 || !player.alive || ended) return;
    skill1Cooldown = 4.0;
    playerMana -= 80;
    for (final e in enemies) {
      if (e.alive && _distance(player.position, e.position) < 13) {
        e.hp -= 250 + skillPower * 15;
        if (e.hp <= 0) _killEnemy(e);
      }
    }
    for (final t in towers) {
      if (!t.allied && !t.destroyed && _distance(player.position, t.position) < 11) {
        t.hp -= 180 + skillPower * 10;
        if (t.hp <= 0) _destroyTower(t);
      }
    }
  }

  void _skill2() {
    if (skill2Cooldown > 0 || playerMana < 100 || !player.alive || ended) return;
    skill2Cooldown = 7.0;
    playerMana -= 100;
    playerHp = math.min(playerMaxHp, playerHp + 260 + level * 30);
    for (final e in enemies) {
      if (e.alive && _distance(player.position, e.position) < 9) {
        e.hp -= 180 + skillPower * 12;
        e.position.x += (e.position.x - player.position.x) * 0.18;
        e.position.z += (e.position.z - player.position.z) * 0.18;
        e.mesh?.position.copy(e.position);
        if (e.hp <= 0) _killEnemy(e);
      }
    }
  }

  void _ultimate() {
    if (ultimateCooldown > 0 || playerMana < 180 || !player.alive || ended) return;
    ultimateCooldown = 22.0;
    playerMana -= 180;
    for (final e in enemies) {
      if (e.alive && _distance(player.position, e.position) < 20) {
        e.hp -= 650 + level * 45 + skillPower * 25;
        if (e.hp <= 0) _killEnemy(e);
      }
    }
    for (final t in towers) {
      if (!t.allied && !t.destroyed && _distance(player.position, t.position) < 16) {
        t.hp -= 400 + level * 20;
        if (t.hp <= 0) _destroyTower(t);
      }
    }
  }

  void _fireProjectile(three.Vector3 from, three.Vector3 target, bool allied, double damage, _Minion3D? targetUnit,
      { _Hero3D? heroTarget, _Tower3D? towerTarget}) {
    final p = _Projectile3D(three.Vector3(from.x, from.y + 3, from.z), three.Vector3(target.x, target.y + 2, target.z));
    p.damage = damage;
    p.targetUnit = targetUnit;
    p.heroTarget = heroTarget;
    p.towerTarget = towerTarget;
    p.damagePlayer = !allied && heroTarget == null && targetUnit == null && towerTarget == null;
    p.mesh = _mesh(three.SphereGeometry(0.35, 10, 8), allied ? 0x74d6ff : 0xff7b66);
    threeJs.scene.add(p.mesh!);
    projectiles.add(p);
  }

  void _damagePlayer(double raw) {
    if (!player.alive) return;
    final reduced = raw * (100 / (100 + armor * 5));
    playerHp -= reduced;
    if (playerHp <= 0) _killPlayer();
  }

  void _killPlayer() {
    if (!player.alive) return;
    player.alive = false;
    deaths++;
    respawnTimer = 5 + level * 0.8;
    player.mesh?.visible = false;
  }

  void _respawnPlayer() {
    player.alive = true;
    playerHp = playerMaxHp;
    playerMana = playerMaxMana;
    player.position.setValues(-55, 0, 0);
    player.mesh?.position.copy(player.position);
    player.mesh?.visible = true;
  }

  void _killEnemy(_Hero3D e) {
    if (!e.alive) return;
    e.alive = false;
    e.respawn = 7 + level * 0.4;
    e.mesh?.visible = false;
    kills++;
    gold += 180 + difficulty * 20;
    _gainXp(220);
  }

  void _killMinion(_Minion3D m) {
    if (!m.alive) return;
    m.alive = false;
    m.mesh?.visible = false;
    if (m.allied) return;
    gold += m.ranged ? 32 : 24;
    _gainXp(m.ranged ? 55 : 45);
  }

  void _destroyTower(_Tower3D t) {
    if (t.destroyed) return;
    t.destroyed = true;
    t.mesh?.visible = false;
    if (!t.allied) {
      gold += 220;
      _gainXp(180);
    }
  }

  void _gainXp(int amount) {
    xp += amount;
    while (level < 15 && xp >= _xpNeeded(level)) {
      xp -= _xpNeeded(level);
      level++;
      playerMaxHp += 95;
      playerMaxMana += 35;
      attackDamage += 13;
      armor += 2;
      skillPower += 2;
      playerHp = playerMaxHp;
      playerMana = playerMaxMana;
    }
  }

  int _xpNeeded(int currentLevel) => 500 + currentLevel * 180;

  bool _allEnemyTowersDown() => towers.where((t) => !t.allied && !t.destroyed).isEmpty;
  bool _allAlliedTowersDown() => towers.where((t) => t.allied && !t.destroyed).isEmpty;

  void _cleanup() {
    minions.removeWhere((m) => !m.alive && m.mesh == null);
    projectiles.removeWhere((p) => !p.alive);
  }

  double _distance(three.Vector3 a, three.Vector3 b) {
    final dx = a.x - b.x;
    final dz = a.z - b.z;
    return math.sqrt(dx * dx + dz * dz);
  }

  void _finish(bool win) {
    if (ended) return;
    ended = true;
    victory = win;
  }

  void _buy(String item) {
    final prices = <String, int>{'blade': 700, 'armor': 650, 'boots': 500, 'crystal': 800};
    final price = prices[item]!;
    if (gold < price) return;
    gold -= price;
    if (item == 'blade') attackDamage += 45;
    if (item == 'armor') armor += 12;
    if (item == 'boots') moveSpeed += 1.8;
    if (item == 'crystal') {
      skillPower += 12;
      playerMaxMana += 150;
      playerMana = playerMaxMana;
    }
  }

  void _reset() {
    setState(() {
      ended = false;
      victory = false;
      level = 1;
      xp = 0;
      gold = 600;
      kills = 0;
      deaths = 0;
      wave = 0;
      matchTime = 0;
      waveTimer = 0;
      playerMaxHp = 1200;
      playerHp = 1200;
      playerMaxMana = 600;
      playerMana = 600;
      attackDamage = 110;
      armor = 12;
      moveSpeed = 10;
      skillPower = 0;
      playerCore.hp = playerCore.maxHp;
      enemyCore.hp = enemyCore.maxHp;
      player.alive = true;
      player.position.setValues(-55, 0, 0);
      player.mesh?.position.copy(player.position);
      player.mesh?.visible = true;
      for (final e in enemies) {
        e.alive = true;
        e.hp = e.maxHp;
        e.position.setValues(55, 0, e.laneZ);
        e.mesh?.position.copy(e.position);
        e.mesh?.visible = true;
      }
      for (final t in towers) {
        t.destroyed = false;
        t.hp = t.maxHp;
        t.mesh?.visible = true;
      }
      for (final m in minions) {
        m.alive = false;
        m.mesh?.visible = false;
      }
      _spawnWave();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (waitingBinding != null) {
              setState(() {
                bindings[waitingBinding!] = event.logicalKey;
                waitingBinding = null;
              });
              return;
            }
            keys.add(event.logicalKey);
            if (event.logicalKey == bindings['skill1']) _skill1();
            if (event.logicalKey == bindings['skill2']) _skill2();
            if (event.logicalKey == bindings['ultimate']) _ultimate();
            if (event.logicalKey == bindings['shop']) setState(() => shopOpen = !shopOpen);
          }
          if (event is KeyUpEvent) keys.remove(event.logicalKey);
        },
        child: Stack(children: [
          Positioned.fill(child: threeJs.build()),
          _hud(),
          _miniMap(),
          _controls(),
          if (shopOpen) _shop(),
          if (settingsOpen) _settings(),
          if (ended) _result(),
          if (respawnTimer > 0 && !ended) _respawnOverlay(),
        ]),
      ),
    );
  }

  Widget _hud() => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(color: Colors.black.withOpacity(.72), borderRadius: BorderRadius.circular(18)),
            child: Text(
              'ARENA LEGENDS 3D  •  LV.$level  •  ❤️ ${playerHp.ceil()}/${playerMaxHp.ceil()}  •  💧 ${playerMana.ceil()}  •  🪙 $gold  •  ⚔ $kills  •  ☠ $deaths  •  WAVE $wave',
              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      );

  Widget _miniMap() => Positioned(
        top: 12,
        right: 12,
        child: SafeArea(
          child: Container(
            width: 150,
            height: 94,
            decoration: BoxDecoration(color: const Color(0xff16301d).withOpacity(.94), border: Border.all(color: Colors.white70), borderRadius: BorderRadius.circular(12)),
            child: CustomPaint(painter: _MiniMapPainter()),
          ),
        ),
      );

  Widget _controls() => Positioned.fill(
        child: Stack(children: [
          Positioned(left: 20, bottom: 20, child: _TouchJoystick(onChanged: (v) => setState(() => joystick = v), onEnd: () => setState(() => joystick = Offset.zero))),
          Positioned(
            right: 20,
            bottom: 20,
            child: Row(children: [
              _ActionButton(label: 'ULT', size: 60, onTap: _ultimate, cooldown: ultimateCooldown),
              const SizedBox(width: 10),
              _ActionButton(label: 'S2', size: 60, onTap: _skill2, cooldown: skill2Cooldown),
              const SizedBox(width: 10),
              _ActionButton(label: 'S1', size: 60, onTap: _skill1, cooldown: skill1Cooldown),
              const SizedBox(width: 10),
              GestureDetector(
                onTapDown: (_) => setState(() => attackHeld = true),
                onTapUp: (_) => setState(() => attackHeld = false),
                onTapCancel: () => setState(() => attackHeld = false),
                child: _ActionButton(label: 'ATTACK', size: 86, onTap: _basicAttack, cooldown: attackCooldown),
              ),
            ]),
          ),
          Positioned(left: 12, top: 86, child: Row(children: [
            _smallButton('SHOP', () => setState(() => shopOpen = !shopOpen)),
            const SizedBox(width: 6),
            _smallButton('KEYS', () => setState(() => settingsOpen = !settingsOpen)),
            const SizedBox(width: 6),
            _smallButton(paused ? 'PLAY' : 'PAUSE', () => setState(() => paused = !paused)),
          ])),
        ]),
      );

  Widget _smallButton(String text, VoidCallback onTap) => FilledButton.tonal(onPressed: onTap, child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)));

  Widget _shop() => Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.black.withOpacity(.94), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('ITEM SHOP', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            Text('Gold: $gold'),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _item('BLADE', 700, '+45 ATK', 'blade'),
              _item('ARMOR', 650, '+12 ARMOR', 'armor'),
              _item('BOOTS', 500, '+1.8 SPEED', 'boots'),
              _item('CRYSTAL', 800, '+12 POWER', 'crystal'),
            ]),
            const SizedBox(height: 8),
            TextButton(onPressed: () => setState(() => shopOpen = false), child: const Text('TUTUP')),
          ]),
        ),
      );

  Widget _item(String name, int price, String effect, String id) => SizedBox(
        width: 185,
        child: FilledButton.tonal(onPressed: gold >= price ? () => setState(() => _buy(id)) : null, child: Text('$name\n$price gold • $effect', textAlign: TextAlign.center)),
      );

  Widget _settings() => Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.black.withOpacity(.95), borderRadius: BorderRadius.circular(18)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('KEYBOARD SETTINGS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Tekan tombol pengganti, lalu tekan key baru.'),
            const SizedBox(height: 12),
            ...bindings.entries.map((e) => ListTile(
                  dense: true,
                  title: Text(e.key.toUpperCase()),
                  trailing: OutlinedButton(onPressed: () => setState(() => waitingBinding = e.key), child: Text(waitingBinding == e.key ? 'PRESS KEY' : e.value.keyLabel.toUpperCase())),
                )),
            TextButton(onPressed: () => setState(() { settingsOpen = false; waitingBinding = null; }), child: const Text('SELESAI')),
          ]),
        ),
      );

  Widget _respawnOverlay() => Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), decoration: BoxDecoration(color: Colors.black.withOpacity(.72), borderRadius: BorderRadius.circular(16)), child: Text('HERO TUMBANG • RESPAWN ${respawnTimer.ceil()}s', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))));

  Widget _result() => Center(child: Card(color: Colors.black.withOpacity(.93), child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(victory ? '🏆 VICTORY' : '💀 DEFEAT', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(victory ? 'Enemy core hancur. Medan perang dimenangkan.' : 'Core tim kamu hancur. Musuh memenangkan perang.'), const SizedBox(height: 18), FilledButton(onPressed: _reset, child: const Text('MAIN LAGI'))]))));
}

class _Hero3D {
  _Hero3D(this.position, this.allied, this.maxHp, this.maxMana);
  final three.Vector3 position;
  final bool allied;
  final double maxHp;
  final double maxMana;
  double hp;
  double damage = 60;
  double speed = 4.5;
  double attackTimer = 0;
  double respawn = 0;
  double laneZ = 0;
  bool alive = true;
  three.Group? mesh;
}

class _Minion3D {
  _Minion3D(this.position, this.allied, this.maxHp, this.ranged, this.laneZ) : hp = maxHp;
  final three.Vector3 position;
  final bool allied;
  final double maxHp;
  final bool ranged;
  final double laneZ;
  double hp;
  double damage = 40;
  double attackTimer = 0;
  bool alive = true;
  three.Group? mesh;
}

class _Tower3D {
  _Tower3D(this.position, this.allied, this.laneZ);
  final three.Vector3 position;
  final bool allied;
  final double laneZ;
  final double maxHp = 1800;
  double hp = 1800;
  double attackTimer = 0;
  bool destroyed = false;
  three.Group? mesh;
}

class _Core3D {
  _Core3D(this.position, this.allied, this.maxHp) : hp = maxHp;
  final three.Vector3 position;
  final bool allied;
  final double maxHp;
  double hp;
  three.Group? mesh;
}

class _Camp3D {
  _Camp3D(this.position, this.maxHp) : hp = maxHp;
  final three.Vector3 position;
  final double maxHp;
  double hp;
  double respawn = 45;
  bool alive = true;
  three.Group? mesh;
}

class _Projectile3D {
  _Projectile3D(this.position, this.target);
  final three.Vector3 position;
  final three.Vector3 target;
  double damage = 0;
  double speed = 26;
  bool alive = true;
  bool damagePlayer = false;
  _Minion3D? targetUnit;
  _Hero3D? heroTarget;
  _Tower3D? towerTarget;
  three.Mesh? mesh;
}

class _TouchJoystick extends StatefulWidget {
  const _TouchJoystick({required this.onChanged, required this.onEnd});
  final ValueChanged<Offset> onChanged;
  final VoidCallback onEnd;
  @override
  State<_TouchJoystick> createState() => _TouchJoystickState();
}

class _TouchJoystickState extends State<_TouchJoystick> {
  Offset value = Offset.zero;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onPanUpdate: (d) {
          final v = d.localPosition - const Offset(70, 70);
          final len = v.distance;
          value = len > 48 ? v / len * 48 : v;
          widget.onChanged(value / 48);
          setState(() {});
        },
        onPanEnd: (_) {
          value = Offset.zero;
          widget.onEnd();
          setState(() {});
        },
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(.35), border: Border.all(color: Colors.white24, width: 2)),
          child: Center(child: Transform.translate(offset: value, child: Container(width: 58, height: 58, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white54)))),
        ),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.size, required this.onTap, required this.cooldown});
  final String label;
  final double size;
  final VoidCallback onTap;
  final double cooldown;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: cooldown > 0 ? Colors.grey.shade800 : Colors.deepPurple.withOpacity(.86), border: Border.all(color: Colors.white54, width: 2), boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black54)]),
          alignment: Alignment.center,
          child: Text(cooldown > 0 ? cooldown.toStringAsFixed(1) : label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
        ),
      );
}

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..strokeWidth = 5..style = PaintingStyle.stroke;
    p.color = Colors.blueAccent.withOpacity(.7);
    canvas.drawLine(Offset(size.width * .1, size.height * .9), Offset(size.width * .9, size.height * .1), p);
    p.color = Colors.redAccent.withOpacity(.7);
    canvas.drawLine(Offset(size.width * .1, size.height * .1), Offset(size.width * .9, size.height * .9), p);
    p.color = Colors.lightBlueAccent.withOpacity(.55);
    canvas.drawLine(Offset(size.width * .5, 0), Offset(size.width * .5, size.height), p);
    p.style = PaintingStyle.fill;
    p.color = Colors.white;
    canvas.drawCircle(Offset(size.width * .22, size.height * .5), 4, p);
    p.color = Colors.yellow;
    canvas.drawCircle(Offset(size.width * .78, size.height * .5), 4, p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
