import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:three_js/three_js.dart' as three;

/// Stable Phase 5 gameplay host compatible with three_js 0.2.x.
class Moba3DPhase5 extends StatefulWidget {
  const Moba3DPhase5({super.key});
  @override
  State<Moba3DPhase5> createState() => _Moba3DPhase5State();
}

class _Moba3DPhase5State extends State<Moba3DPhase5> {
  late final FocusNode _focus;
  late three.ThreeJS _threeJs;
  final Set<LogicalKeyboardKey> _keys = <LogicalKeyboardKey>{};
  final List<_Unit> _enemies = <_Unit>[];
  final List<_Unit> _minions = <_Unit>[];
  final List<_Tower> _towers = <_Tower>[];
  Timer? _uiTimer;
  late _Unit _player;
  late _Core _allyCore;
  late _Core _enemyCore;
  bool _started = false;
  bool _ended = false;
  bool _won = false;
  bool _attackHeld = false;
  int _wave = 0;
  int _kills = 0;
  int _deaths = 0;
  int _level = 1;
  double _hp = 1500;
  double _mana = 700;
  double _attackCooldown = 0;
  double _waveCooldown = 0;
  double _respawn = 0;

  final Map<String, LogicalKeyboardKey> _bind = <String, LogicalKeyboardKey>{
    'up': LogicalKeyboardKey.keyW,
    'down': LogicalKeyboardKey.keyS,
    'left': LogicalKeyboardKey.keyA,
    'right': LogicalKeyboardKey.keyD,
    'attack': LogicalKeyboardKey.keyJ,
  };

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _uiTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && _started) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _focus.dispose();
    if (_started) _threeJs.dispose();
    super.dispose();
  }

  void _start() {
    setState(() => _started = true);
    _threeJs = three.ThreeJS(
      onSetupComplete: () {
        if (mounted) setState(() {});
      },
      setup: _setup,
      settings: three.Settings(renderOptions: <String, dynamic>{
        'antialias': true,
        'powerPreference': 'high-performance',
      }),
    );
  }

  Future<void> _setup() async {
    _threeJs.camera = three.PerspectiveCamera(
      48,
      _threeJs.width / math.max(1.0, _threeJs.height),
      0.1,
      2200,
    );
    _threeJs.camera.position.setValues(-8, 58, 62);
    _threeJs.scene = three.Scene();
    _threeJs.scene.background = three.Color(0.08, 0.16, 0.24);
    _threeJs.scene.add(three.HemisphereLight(0xd7f5ff, 0x18251b, 1.7));
    final three.DirectionalLight sun = three.DirectionalLight(0xffffff, 2.5);
    sun.position.setValues(-80, 130, 50);
    _threeJs.scene.add(sun);
    _buildMap();
    _buildBasesAndTowers();
    _buildHeroes();
    _spawnWave();
    _threeJs.camera.lookAt(three.Vector3(0, 0, 0));
    _threeJs.addAnimationEvent(_tick);
  }

  three.Mesh _mesh(three.BufferGeometry geometry, int color, {double metal = 0.08}) {
    return three.Mesh(
      geometry,
      three.MeshStandardMaterial(<three.MaterialProperty, dynamic>{
        three.MaterialProperty.color: color,
        three.MaterialProperty.metalness: metal,
        three.MaterialProperty.roughness: 0.72,
      }),
    );
  }

  void _buildMap() {
    final three.Mesh ground = _mesh(three.BoxGeometry(180, 2, 120), 0x3d8a4b);
    ground.position.y = -1;
    _threeJs.scene.add(ground);
    for (final double z in <double>[-30, 0, 30]) {
      final three.Mesh lane = _mesh(three.BoxGeometry(170, 0.7, 14), 0x6d6960);
      lane.position.setValues(0, 0.15, z);
      _threeJs.scene.add(lane);
    }
    final three.Mesh river = _mesh(three.BoxGeometry(14, 0.35, 120), 0x238fb8, metal: 0.02);
    river.position.y = 0.2;
    _threeJs.scene.add(river);
    final math.Random random = math.Random(2030);
    for (int i = 0; i < 80; i++) {
      final double x = random.nextDouble() * 150 - 75;
      final double z = random.nextDouble() * 104 - 52;
      if (x.abs() < 20 || (z.abs() < 38 && x.abs() < 60)) continue;
      _tree(x, z, 0.7 + random.nextDouble() * 0.8);
    }
  }

  void _tree(double x, double z, double scale) {
    final three.Mesh trunk = _mesh(three.CylinderGeometry(0.7, 1.1, 5, 8), 0x684229);
    trunk.position.setValues(x, 2.5 * scale, z);
    trunk.scale.setValues(scale, scale, scale);
    _threeJs.scene.add(trunk);
    final three.Mesh crown = _mesh(three.IcosahedronGeometry(3.1, 1), 0x2d783f);
    crown.position.setValues(x, 6 * scale, z);
    crown.scale.setValues(scale, scale, scale);
    _threeJs.scene.add(crown);
  }

  void _buildBasesAndTowers() {
    _base(-80, 0x3f7cff);
    _base(80, 0xe34d59);
    _allyCore = _Core(three.Vector3(-80, 7, 0), true, 5000);
    _enemyCore = _Core(three.Vector3(80, 7, 0), false, 5000);
    _allyCore.mesh = _coreMesh(0x3f7cff);
    _enemyCore.mesh = _coreMesh(0xe34d59);
    _threeJs.scene.add(_allyCore.mesh!);
    _threeJs.scene.add(_enemyCore.mesh!);
    for (final double z in <double>[-30, 0, 30]) {
      for (int i = 0; i < 2; i++) {
        final _Tower tower = _Tower(three.Vector3(38 + i * 16, 4, z), false, z, 1800);
        tower.mesh = _towerMesh(0xe34d59);
        _towers.add(tower);
        _threeJs.scene.add(tower.mesh!);
      }
      for (int i = 0; i < 2; i++) {
        final _Tower tower = _Tower(three.Vector3(-38 - i * 16, 4, z), true, z, 1800);
        tower.mesh = _towerMesh(0x3f7cff);
        _towers.add(tower);
        _threeJs.scene.add(tower.mesh!);
      }
    }
  }

  void _base(double x, int color) {
    final three.Mesh base = _mesh(three.CylinderGeometry(11, 13, 1.5, 8), 0x313c45);
    base.position.setValues(x, 0.75, 0);
    _threeJs.scene.add(base);
    final three.Mesh ring = _mesh(three.TorusGeometry(10, 0.65, 12, 48), color, metal: 0.2);
    ring.rotation.x = math.pi / 2;
    ring.position.setValues(x, 1.8, 0);
    _threeJs.scene.add(ring);
  }

  three.Group _coreMesh(int color) {
    final three.Group group = three.Group();
    final three.Mesh crystal = _mesh(three.OctahedronGeometry(6.2, 1), color, metal: 0.25);
    crystal.position.y = 1;
    group.add(crystal);
    final three.Mesh ring = _mesh(three.TorusGeometry(8, 0.55, 12, 48), color, metal: 0.25);
    ring.rotation.x = math.pi / 2;
    ring.position.y = -5;
    group.add(ring);
    return group;
  }

  three.Group _towerMesh(int color) {
    final three.Group group = three.Group();
    final three.Mesh body = _mesh(three.CylinderGeometry(2.8, 3.5, 3.6, 8), 0x30373e, metal: 0.45);
    body.position.y = 1.8;
    group.add(body);
    final three.Mesh top = _mesh(three.OctahedronGeometry(2.25, 1), color, metal: 0.3);
    top.position.y = 5.5;
    group.add(top);
    return group;
  }

  void _buildHeroes() {
    _player = _Unit(three.Vector3(-55, 0, 0), true, _hp);
    _player.damage = 125;
    _player.speed = 11;
    _player.mesh = _heroMesh(0x3e8cff);
    _threeJs.scene.add(_player.mesh!);
    final List<three.Vector3> positions = <three.Vector3>[
      three.Vector3(55, 0, -30),
      three.Vector3(55, 0, 0),
      three.Vector3(55, 0, 30),
      three.Vector3(34, 0, -12),
      three.Vector3(34, 0, 12),
    ];
    for (final three.Vector3 position in positions) {
      final _Unit enemy = _Unit(position, false, 1050);
      enemy.damage = 65;
      enemy.speed = 4.4;
      enemy.lane = position.z;
      enemy.mesh = _heroMesh(0xe95461);
      _enemies.add(enemy);
      _threeJs.scene.add(enemy.mesh!);
    }
  }

  three.Group _heroMesh(int color) {
    final three.Group group = three.Group();
    final three.Mesh body = _mesh(
      three.CapsuleGeometry(radius: 1.5, length: 2.8, capSegments: 8, radialSegments: 12),
      color,
      metal: 0.18,
    );
    body.position.y = 3;
    group.add(body);
    final three.Mesh head = _mesh(three.SphereGeometry(1.15, 16, 12), 0xf0c4a0);
    head.position.y = 5.7;
    group.add(head);
    final three.Mesh armor = _mesh(three.BoxGeometry(3.7, 0.8, 1.9), 0x253344, metal: 0.5);
    armor.position.y = 3.9;
    group.add(armor);
    return group;
  }

  void _spawnWave() {
    if (_ended) return;
    _wave++;
    for (final double z in <double>[-30, 0, 30]) {
      for (int i = 0; i < 4; i++) {
        _spawnMinion(true, z, -66 - i * 3.0);
        _spawnMinion(false, z, 66 + i * 3.0);
      }
    }
  }

  void _spawnMinion(bool allied, double z, double x) {
    final double hp = 350 + _level * 20;
    final _Unit minion = _Unit(three.Vector3(x, 1.5, z), allied, hp);
    minion.damage = allied ? 55 : 62;
    minion.speed = allied ? 4.8 : 4.5;
    minion.lane = z;
    minion.mesh = _minionMesh(allied);
    _minions.add(minion);
    _threeJs.scene.add(minion.mesh!);
  }

  three.Group _minionMesh(bool allied) {
    final three.Group group = three.Group();
    final three.Mesh body = _mesh(three.CylinderGeometry(1, 1.2, 2.2, 8), allied ? 0x4d91ff : 0xe95661);
    body.position.y = 1.5;
    group.add(body);
    final three.Mesh head = _mesh(three.SphereGeometry(0.75, 12, 8), 0xf0c2a0);
    head.position.y = 3;
    group.add(head);
    return group;
  }

  void _tick(double dt) {
    if (_ended) return;
    _attackCooldown = math.max(0, _attackCooldown - dt).toDouble();
    _waveCooldown += dt;
    if (_waveCooldown > 24) {
      _waveCooldown = 0;
      _spawnWave();
    }
    _updatePlayer(dt);
    _updateEnemies(dt);
    _updateMinions(dt);
    if (!_player.alive) {
      _respawn -= dt;
      if (_respawn <= 0) _respawnPlayer();
    }
    if (_enemyCore.hp <= 0) _finish(true);
    if (_allyCore.hp <= 0) _finish(false);
  }

  void _updatePlayer(double dt) {
    if (!_player.alive) return;
    final double dx = _axis('right', 'left');
    final double dz = _axis('down', 'up');
    final double length = math.sqrt(dx * dx + dz * dz);
    if (length > 0.05) {
      _player.position.x += dx / math.max(1, length) * _player.speed * dt;
      _player.position.z += dz / math.max(1, length) * _player.speed * dt;
      _player.position.x = _player.position.x.clamp(-72.0, 72.0).toDouble();
      _player.position.z = _player.position.z.clamp(-52.0, 52.0).toDouble();
      _player.mesh?.position.setValues(_player.position.x, _player.position.y, _player.position.z);
    }
    _mana = math.min(700, _mana + 18 * dt).toDouble();
    if (_attackHeld || _keys.contains(_bind['attack'])) _attack();
  }

  double _axis(String positive, String negative) =>
      ((_keys.contains(_bind[positive]) ? 1 : 0) - (_keys.contains(_bind[negative]) ? 1 : 0)).toDouble();

  void _updateEnemies(double dt) {
    for (final _Unit enemy in _enemies) {
      if (!enemy.alive) {
        enemy.respawn -= dt;
        if (enemy.respawn <= 0) {
          enemy.alive = true;
          enemy.hp = enemy.maxHp;
          enemy.position.setValues(55, 0, enemy.lane);
          enemy.mesh?.position.setValues(enemy.position.x, enemy.position.y, enemy.position.z);
          enemy.mesh?.visible = true;
        }
        continue;
      }
      if (!_player.alive) continue;
      final double vx = _player.position.x - enemy.position.x;
      final double vz = _player.position.z - enemy.position.z;
      final double distance = math.sqrt(vx * vx + vz * vz);
      if (distance < 13) {
        enemy.attackTimer -= dt;
        if (enemy.attackTimer <= 0) {
          enemy.attackTimer = 1;
          _hurt(enemy.damage);
        }
      } else if (distance < 55) {
        enemy.position.x += vx / math.max(1, distance) * enemy.speed * dt;
        enemy.position.z += vz / math.max(1, distance) * enemy.speed * dt;
        enemy.mesh?.position.setValues(enemy.position.x, enemy.position.y, enemy.position.z);
      }
    }
  }

  void _updateMinions(double dt) {
    for (final _Unit minion in _minions) {
      if (!minion.alive) continue;
      final int direction = minion.allied ? 1 : -1;
      _Unit? target;
      double best = 7;
      for (final _Unit other in _minions) {
        if (!other.alive || other.allied == minion.allied || (other.lane - minion.lane).abs() > 4) continue;
        final double distance = _distance(minion.position, other.position);
        if (distance < best) {
          best = distance;
          target = other;
        }
      }
      if (target != null) {
        minion.attackTimer -= dt;
        if (minion.attackTimer <= 0) {
          minion.attackTimer = 0.8;
          target.hp -= minion.damage;
          if (target.hp <= 0) _killMinion(target);
        }
      } else {
        minion.position.x += direction * minion.speed * dt;
        minion.mesh?.position.setValues(minion.position.x, minion.position.y, minion.position.z);
      }
    }
  }

  void _attack() {
    if (!_player.alive || _attackCooldown > 0) return;
    _attackCooldown = 0.55;
    _Unit? target;
    double best = 9;
    for (final _Unit enemy in _enemies) {
      if (!enemy.alive) continue;
      final double distance = _distance(_player.position, enemy.position);
      if (distance < best) {
        best = distance;
        target = enemy;
      }
    }
    if (target != null) {
      target.hp -= _player.damage;
      if (target.hp <= 0) _killEnemy(target);
    }
  }

  void _hurt(double damage) {
    if (!_player.alive) return;
    _hp -= damage * 100 / 118;
    if (_hp <= 0) _killPlayer();
  }

  void _killPlayer() {
    if (!_player.alive) return;
    _player.alive = false;
    _deaths++;
    _respawn = 6;
    _hp = 0;
    _player.mesh?.visible = false;
    SystemSound.play(SystemSoundType.alert);
  }

  void _respawnPlayer() {
    _player.alive = true;
    _hp = 1500 + (_level - 1) * 100;
    _mana = 700;
    _player.position.setValues(-55, 0, 0);
    _player.mesh?.position.setValues(-55, 0, 0);
    _player.mesh?.visible = true;
  }

  void _killEnemy(_Unit enemy) {
    enemy.alive = false;
    enemy.hp = 0;
    enemy.respawn = 6;
    enemy.mesh?.visible = false;
    _kills++;
    if (_kills % 5 == 0) _level++;
  }

  void _killMinion(_Unit minion) {
    minion.alive = false;
    minion.hp = 0;
    minion.mesh?.visible = false;
  }

  double _distance(three.Vector3 a, three.Vector3 b) {
    final double dx = a.x - b.x;
    final double dz = a.z - b.z;
    return math.sqrt(dx * dx + dz * dz);
  }

  void _finish(bool victory) {
    if (_ended) return;
    _ended = true;
    _won = victory;
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return Scaffold(
        body: Center(
          child: FilledButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.sports_esports),
            label: const Text('ENTER PHASE 5 WAR'),
          ),
        ),
      );
    }
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: (_, KeyEvent event) {
        if (event is KeyDownEvent) {
          _keys.add(event.logicalKey);
          if (event.logicalKey == _bind['attack']) _attackHeld = true;
        } else if (event is KeyUpEvent) {
          _keys.remove(event.logicalKey);
          if (event.logicalKey == _bind['attack']) _attackHeld = false;
        }
        return KeyEventResult.handled;
      },
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            Positioned.fill(child: _threeJs.build()),
            Positioned(left: 12, top: 12, child: _hud()),
            if (_ended) Positioned.fill(child: _result()),
          ],
        ),
      ),
    );
  }

  Widget _hud() => Material(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            'WAVE $_wave  •  LV $_level  •  HP ${_hp.toInt()}  •  K/D $_kills/$_deaths',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );

  Widget _result() => ColoredBox(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: Text(
            _won ? 'VICTORY' : 'DEFEAT',
            style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900),
          ),
        ),
      );
}

class _Unit {
  _Unit(this.position, this.allied, this.maxHp) : hp = maxHp;
  final three.Vector3 position;
  final bool allied;
  final double maxHp;
  double hp;
  double damage = 50;
  double speed = 4;
  double lane = 0;
  double attackTimer = 0;
  double respawn = 0;
  bool alive = true;
  three.Group? mesh;
}

class _Tower {
  _Tower(this.position, this.allied, this.lane, this.hp);
  final three.Vector3 position;
  final bool allied;
  final double lane;
  double hp;
  three.Group? mesh;
}

class _Core {
  _Core(this.position, this.allied, this.hp);
  final three.Vector3 position;
  final bool allied;
  double hp;
  three.Group? mesh;
}
