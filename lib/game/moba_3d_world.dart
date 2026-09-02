import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:three_js/three_js.dart' as three;

/// True 3D MOBA runtime.  The battlefield, heroes, minions and structures are
/// real 3D meshes rendered by three_js, not Canvas projections.
class Moba3DWorld extends StatefulWidget {
  const Moba3DWorld({super.key});

  @override
  State<Moba3DWorld> createState() => _Moba3DWorldState();
}

class _Moba3DWorldState extends State<Moba3DWorld> {
  late three.ThreeJS threeJs;
  final FocusNode keyboardFocus = FocusNode();
  final Set<LogicalKeyboardKey> keys = <LogicalKeyboardKey>{};

  final List<_Unit3D> enemies = <_Unit3D>[];
  final List<_Tower3D> towers = <_Tower3D>[];
  late _Unit3D player;
  three.Group? playerGroup;

  int level = 1;
  int gold = 0;
  int kills = 0;
  int enemyBaseHp = 1000;
  double playerHp = 1000;
  double playerMana = 500;
  double attackCooldown = 0;
  double skillCooldown = 0;
  double matchTime = 0;
  bool ended = false;
  bool victory = false;
  bool attackHeld = false;
  Offset joystick = Offset.zero;
  Timer? hudTimer;

  @override
  void initState() {
    super.initState();
    threeJs = three.ThreeJS(
      onSetupComplete: () => setState(() {}),
      setup: setup,
      settings: three.Settings(
        renderOptions: <String, dynamic>{
          'antialias': true,
          'powerPreference': 'high-performance',
        },
      ),
    );
    hudTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    hudTimer?.cancel();
    keyboardFocus.dispose();
    threeJs.dispose();
    super.dispose();
  }

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(
      48,
      threeJs.width / math.max(1, threeJs.height),
      0.1,
      2000,
    );
    threeJs.camera.position.setValues(0, 58, 62);
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color(0.38, 0.72, 0.94);

    final ambient = three.HemisphereLight(0xbde8ff, 0x23351e, 1.4);
    threeJs.scene.add(ambient);
    final sun = three.DirectionalLight(0xffffff, 2.4);
    sun.position.setValues(-80, 120, 50);
    threeJs.scene.add(sun);

    _buildWorld();
    _buildActors();
    _buildHudCamera();

    threeJs.addAnimationEvent(_tick);
  }

  void _buildHudCamera() {
    threeJs.camera.lookAt(three.Vector3(0, 0, 0));
  }

  three.Mesh _mesh(three.BufferGeometry geometry, int color, {double opacity = 1}) {
    final material = three.MeshStandardMaterial(<three.MaterialProperty, dynamic>{
      three.MaterialProperty.color: color,
      three.MaterialProperty.roughness: 0.72,
      three.MaterialProperty.metalness: 0.08,
      if (opacity < 1) three.MaterialProperty.opacity: opacity,
      if (opacity < 1) three.MaterialProperty.transparent: true,
    });
    return three.Mesh(geometry, material);
  }

  void _buildWorld() {
    final ground = _mesh(three.BoxGeometry(180, 2, 120), 0x5aa34d);
    ground.position.y = -1;
    threeJs.scene.add(ground);

    // Three broad raised lanes.
    for (final z in <double>[-30, 0, 30]) {
      final lane = _mesh(three.BoxGeometry(170, 0.8, 12), 0x6d6a66);
      lane.position.setValues(0, 0.1, z);
      threeJs.scene.add(lane);
      final shoulder = _mesh(three.BoxGeometry(170, 0.35, 15), 0x8d8981);
      shoulder.position.setValues(0, -0.15, z);
      threeJs.scene.add(shoulder);
    }

    // Central river crossing the map.
    final river = _mesh(three.BoxGeometry(14, 0.25, 120), 0x2d9fd4);
    river.position.y = 0.15;
    threeJs.scene.add(river);
    for (final z in <double>[-42, -14, 14, 42]) {
      final bridge = _mesh(three.BoxGeometry(18, 1.0, 8), 0x9c734c);
      bridge.position.setValues(0, 0.55, z);
      threeJs.scene.add(bridge);
    }

    _base(-78, 0x315fc7);
    _base(78, 0xe04a4a);

    // Stylized jungle with actual 3D trunks, foliage and rocks.
    final random = math.Random(2030);
    for (int i = 0; i < 90; i++) {
      final x = (random.nextDouble() * 155) - 77.5;
      final z = (random.nextDouble() * 108) - 54;
      if (x.abs() < 18 || (z.abs() < 38 && x.abs() < 65)) continue;
      _tree(x, z, 1.0 + random.nextDouble() * 1.8);
    }
    for (int i = 0; i < 34; i++) {
      final x = (random.nextDouble() * 150) - 75;
      final z = (random.nextDouble() * 100) - 50;
      if (x.abs() < 20) continue;
      final rock = _mesh(three.IcosahedronGeometry(1.5 + random.nextDouble() * 2.5, 1), 0x68706d);
      rock.position.setValues(x, 1, z);
      rock.rotation.y = random.nextDouble() * math.pi;
      threeJs.scene.add(rock);
    }
  }

  void _base(double x, int color) {
    final pad = _mesh(three.CylinderGeometry(10, 12, 1.5, 8), 0x34414a);
    pad.position.setValues(x, 0.7, 0);
    threeJs.scene.add(pad);
    final core = _mesh(three.OctahedronGeometry(7, 1), color);
    core.position.setValues(x, 8, 0);
    core.scale.setValues(1, 1.25, 1);
    threeJs.scene.add(core);
    final ring = _mesh(three.TorusGeometry(10, 0.7, 12, 48), color);
    ring.position.setValues(x, 1.7, 0);
    ring.rotation.x = math.pi / 2;
    threeJs.scene.add(ring);
  }

  void _tree(double x, double z, double scale) {
    final trunk = _mesh(three.CylinderGeometry(0.8, 1.15, 5, 8), 0x6c4329);
    trunk.position.setValues(x, 2.5, z);
    trunk.scale.setValues(scale, scale, scale);
    threeJs.scene.add(trunk);
    final crown = _mesh(three.IcosahedronGeometry(3.2, 1), 0x2e7d42);
    crown.position.setValues(x, 6.4 * scale, z);
    crown.scale.setValues(scale, scale, scale);
    threeJs.scene.add(crown);
  }

  void _buildActors() {
    player = _Unit3D(three.Vector3(-55, 2.0, 0), true, level);
    playerGroup = _heroMesh(0x3e8cff);
    playerGroup!.position.copy(player.position);
    threeJs.scene.add(playerGroup!);

    for (final z in <double>[-30, 0, 30]) {
      for (int i = 0; i < 2; i++) {
        final tower = _Tower3D(three.Vector3(38 + i * 16, 4, z), false);
        tower.mesh = _towerMesh(0xe64c5a);
        threeJs.scene.add(tower.mesh!);
        towers.add(tower);
      }
    }
    for (final z in <double>[-30, 0, 30]) {
      for (int i = 0; i < 2; i++) {
        final tower = _Tower3D(three.Vector3(-38 - i * 16, 4, z), true);
        tower.mesh = _towerMesh(0x3f7cff);
        threeJs.scene.add(tower.mesh!);
        towers.add(tower);
      }
    }

    final enemyPositions = <three.Vector3>[
      three.Vector3(50, 2, -30),
      three.Vector3(50, 2, 0),
      three.Vector3(50, 2, 30),
      three.Vector3(28, 2, -6),
      three.Vector3(28, 2, 6),
    ];
    for (final p in enemyPositions) {
      final unit = _Unit3D(p, false, level);
      unit.mesh = _heroMesh(0xef5362);
      threeJs.scene.add(unit.mesh!);
      enemies.add(unit);
    }
  }

  three.Group _heroMesh(int color) {
    final group = three.Group();
    final body = _mesh(three.CapsuleGeometry(1.5, 2.8, 8, 12), color);
    body.position.y = 3;
    group.add(body);
    final head = _mesh(three.SphereGeometry(1.15, 16, 12), 0xf2c7a5);
    head.position.y = 5.7;
    group.add(head);
    final armor = _mesh(three.BoxGeometry(3.6, 0.75, 1.8), 0x243447);
    armor.position.y = 3.9;
    group.add(armor);
    final weapon = _mesh(three.CylinderGeometry(0.16, 0.16, 4.0, 8), 0xdde9ff);
    weapon.rotation.z = math.pi / 2;
    weapon.position.setValues(2.0, 3.1, 0);
    group.add(weapon);
    final aura = _mesh(three.TorusGeometry(2.2, 0.12, 8, 40), color);
    aura.rotation.x = math.pi / 2;
    aura.position.y = 0.25;
    group.add(aura);
    return group;
  }

  three.Group _towerMesh(int color) {
    final group = three.Group();
    final base = _mesh(three.CylinderGeometry(2.7, 3.4, 3.5, 8), 0x303841);
    base.position.y = 1.75;
    group.add(base);
    final core = _mesh(three.OctahedronGeometry(2.2, 1), color);
    core.position.y = 5.5;
    group.add(core);
    final ring = _mesh(three.TorusGeometry(3.0, 0.2, 8, 32), color);
    ring.rotation.x = math.pi / 2;
    ring.position.y = 2.8;
    group.add(ring);
    return group;
  }

  void _tick(double dt) {
    if (ended) return;
    matchTime += dt;
    attackCooldown = math.max(0, attackCooldown - dt);
    skillCooldown = math.max(0, skillCooldown - dt);

    final dx = ((keys.contains(LogicalKeyboardKey.keyD) || keys.contains(LogicalKeyboardKey.arrowRight)) ? 1 : 0) -
        ((keys.contains(LogicalKeyboardKey.keyA) || keys.contains(LogicalKeyboardKey.arrowLeft)) ? 1 : 0) + joystick.dx;
    final dz = ((keys.contains(LogicalKeyboardKey.keyS) || keys.contains(LogicalKeyboardKey.arrowDown)) ? 1 : 0) -
        ((keys.contains(LogicalKeyboardKey.keyW) || keys.contains(LogicalKeyboardKey.arrowUp)) ? 1 : 0) + joystick.dy;
    final len = math.sqrt(dx * dx + dz * dz);
    if (len > 0.05) {
      final speed = 10.0 * dt;
      player.position.x += dx / math.max(1, len) * speed;
      player.position.z += dz / math.max(1, len) * speed;
      player.position.x = player.position.x.clamp(-72.0, 72.0);
      player.position.z = player.position.z.clamp(-52.0, 52.0);
      playerGroup?.position.copy(player.position);
    }

    for (final enemy in enemies) {
      if (enemy.dead) continue;
      final vx = player.position.x - enemy.position.x;
      final vz = player.position.z - enemy.position.z;
      final d = math.sqrt(vx * vx + vz * vz);
      if (d < 14) {
        playerHp -= (7 + level * 0.8) * dt;
      } else if (d < 60) {
        enemy.position.x += vx / math.max(1, d) * dt * (4.0 + level * .08);
        enemy.position.z += vz / math.max(1, d) * dt * (4.0 + level * .08);
        enemy.mesh?.position.copy(enemy.position);
      }
    }

    if (attackHeld) _attack();
    if (playerHp <= 0) _finish(false);
    if (towers.where((t) => !t.allied && !t.destroyed).isEmpty) _finish(true);
  }

  void _attack() {
    if (attackCooldown > 0 || ended) return;
    attackCooldown = .42;
    _damageNearest(90 + level * 8, 16);
  }

  void _skill() {
    if (skillCooldown > 0 || ended || playerMana < 80) return;
    skillCooldown = 5;
    playerMana -= 80;
    for (final enemy in enemies) {
      if (enemy.dead) continue;
      final d = _distance(player.position, enemy.position);
      if (d < 12) {
        enemy.hp -= 260 + level * 25;
        if (enemy.hp <= 0) _killEnemy(enemy);
      }
    }
    for (final tower in towers) {
      if (tower.allied || tower.destroyed) continue;
      if (_distance(player.position, tower.position) < 11) {
        tower.hp -= 170 + level * 10;
        if (tower.hp <= 0) {
          tower.destroyed = true;
          tower.mesh?.visible = false;
          gold += 180;
        }
      }
    }
  }

  void _damageNearest(double damage, double range) {
    _Unit3D? target;
    double best = double.infinity;
    for (final enemy in enemies) {
      if (enemy.dead) continue;
      final d = _distance(player.position, enemy.position);
      if (d < range && d < best) {
        best = d;
        target = enemy;
      }
    }
    if (target != null) {
      target!.hp -= damage;
      if (target.hp <= 0) _killEnemy(target);
      return;
    }
    for (final tower in towers) {
      if (tower.allied || tower.destroyed) continue;
      if (_distance(player.position, tower.position) < range) {
        tower.hp -= damage;
        if (tower.hp <= 0) {
          tower.destroyed = true;
          tower.mesh?.visible = false;
          gold += 180;
        }
        break;
      }
    }
  }

  void _killEnemy(_Unit3D enemy) {
    enemy.dead = true;
    enemy.mesh?.visible = false;
    kills++;
    gold += 30;
    if (kills % 5 == 0) {
      level++;
      playerHp = math.min(1000 + level * 80, playerHp + 300);
      playerMana = 500 + level * 20;
    }
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
    if (win) enemyBaseHp = 0;
  }

  void _reset() {
    setState(() {
      ended = false;
      victory = false;
      level = 1;
      gold = 0;
      kills = 0;
      playerHp = 1000;
      playerMana = 500;
      for (final enemy in enemies) {
        enemy.dead = false;
        enemy.hp = 700 + level * 40;
        enemy.mesh?.visible = true;
      }
      for (final tower in towers) {
        tower.destroyed = false;
        tower.hp = 1000;
        tower.mesh?.visible = true;
      }
      player.position.setValues(-55, 2, 0);
      playerGroup?.position.copy(player.position);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: keyboardFocus,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) keys.add(event.logicalKey);
          if (event is KeyUpEvent) keys.remove(event.logicalKey);
          if (event.logicalKey == LogicalKeyboardKey.space && event is KeyDownEvent) _skill();
        },
        child: Stack(
          children: [
            Positioned.fill(child: threeJs.build()),
            _topHud(),
            _miniMap(),
            _controls(),
            if (ended) _resultDialog(),
          ],
        ),
      ),
    );
  }

  Widget _topHud() => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.72),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'ARENA LEGENDS 3D  •  LV.$level  •  ❤️ ${playerHp.ceil()}  •  💧 ${playerMana.ceil()}  •  🪙 $gold  •  ☠ $kills',
              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ),
      );

  Widget _miniMap() => Positioned(
        top: 12,
        right: 12,
        child: SafeArea(
          child: Container(
            width: 118,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xff16301d).withOpacity(.92),
              border: Border.all(color: Colors.white70),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(painter: _MiniMapPainter()),
          ),
        ),
      );

  Widget _controls() => Positioned.fill(
        child: Stack(
          children: [
            Positioned(
              left: 22,
              bottom: 22,
              child: _TouchJoystick(
                onChanged: (v) => setState(() => joystick = v),
                onEnd: () => setState(() => joystick = Offset.zero),
              ),
            ),
            Positioned(
              right: 28,
              bottom: 22,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ActionButton(label: 'SKILL', size: 64, onTap: _skill),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTapDown: (_) => setState(() => attackHeld = true),
                    onTapUp: (_) => setState(() => attackHeld = false),
                    onTapCancel: () => setState(() => attackHeld = false),
                    child: _ActionButton(label: 'ATTACK', size: 86, onTap: _attack),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 12,
              top: 90,
              child: Text(
                'WASD / ARROW = GERAK   •   SPACE = SKILL   •   KLIK/TAHAN = ATTACK',
                style: TextStyle(color: Colors.white.withOpacity(.85), fontSize: 10),
              ),
            ),
          ],
        ),
      );

  Widget _resultDialog() => Center(
        child: Card(
          color: Colors.black.withOpacity(.9),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(victory ? '🏆 VICTORY' : '💀 DEFEAT', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(victory ? 'Semua turret musuh berhasil dihancurkan.' : 'Hero kamu tumbang di medan perang.'),
                const SizedBox(height: 18),
                FilledButton(onPressed: _reset, child: const Text('MAIN LAGI')),
              ],
            ),
          ),
        ),
      );
}

class _Unit3D {
  _Unit3D(this.position, this.allied, int level)
      : hp = allied ? 1000 : 700 + level * 40;
  final three.Vector3 position;
  final bool allied;
  double hp;
  bool dead = false;
  three.Group? mesh;
}

class _Tower3D {
  _Tower3D(this.position, this.allied);
  final three.Vector3 position;
  final bool allied;
  double hp = 1000;
  bool destroyed = false;
  three.Group? mesh;
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (d) {
        final v = d.localPosition - const Offset(70, 70);
        final length = v.distance;
        value = length > 48 ? v / length * 48 : v;
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
        child: Center(
          child: Transform.translate(
            offset: value,
            child: Container(width: 58, height: 58, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white54)),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.size, required this.onTap});
  final String label;
  final double size;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.deepPurple.withOpacity(.8), border: Border.all(color: Colors.white54, width: 2), boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black54)]),
          alignment: Alignment.center,
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
        ),
      );
}

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..strokeWidth = 5..style = PaintingStyle.stroke;
    p.color = Colors.blueAccent.withOpacity(.7);
    canvas.drawLine(Offset(size.width * .1, size.height * .1), Offset(size.width * .9, size.height * .9), p);
    p.color = Colors.redAccent.withOpacity(.7);
    canvas.drawLine(Offset(size.width * .9, size.height * .1), Offset(size.width * .1, size.height * .9), p);
    p.style = PaintingStyle.fill;
    p.color = Colors.white;
    canvas.drawCircle(Offset(size.width * .25, size.height * .5), 4, p);
    p.color = Colors.yellow;
    canvas.drawCircle(Offset(size.width * .5, size.height * .5), 3, p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
