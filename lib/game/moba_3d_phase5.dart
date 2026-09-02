import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lightweight native Flutter 2.5D MOBA battlefield.
/// No WebGL, ThreeJS or native renderer is required.
class Moba3DPhase5 extends StatefulWidget {
  const Moba3DPhase5({super.key});

  @override
  State<Moba3DPhase5> createState() => _Moba3DPhase5State();
}

class _Moba3DPhase5State extends State<Moba3DPhase5> {
  Timer? _ticker;
  final math.Random _rng = math.Random(7);

  Offset _player = const Offset(.22, .53);
  Offset _joy = Offset.zero;
  double _hp = 100;
  double _mana = 100;
  double _enemyHp = 100;
  int _kills = 0;
  int _level = 1;
  int _gold = 500;
  double _time = 0;
  double _attackCd = 0;
  double _skillCd = 0;
  bool _gameOver = false;

  final List<_Minion> _minions = <_Minion>[
    _Minion(.35, .42, true), _Minion(.39, .46, true),
    _Minion(.35, .60, true), _Minion(.65, .42, false),
    _Minion(.61, .46, false), _Minion(.65, .60, false),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 33), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted || _gameOver) return;
    const double dt = .033;
    _time += dt;
    _attackCd = math.max(0, _attackCd - dt).toDouble();
    _skillCd = math.max(0, _skillCd - dt).toDouble();
    _mana = math.min(100, _mana + 3.5 * dt).toDouble();

    if (_joy.distance > .05) {
      final Offset next = _player + _joy * dt * .18;
      _player = Offset(next.dx.clamp(.06, .94).toDouble(), next.dy.clamp(.13, .88).toDouble());
    }

    for (final _Minion m in _minions) {
      m.x += (m.ally ? 1 : -1) * dt * .018;
      if (m.x < .25 || m.x > .75) m.x = m.ally ? .25 : .75;
    }

    if (_rng.nextDouble() < .018 && _enemyHp > 0) {
      _hp = math.max(0, _hp - 1.4).toDouble();
    }
    if (_hp <= 0) _finish(false);
    setState(() {});
  }

  void _attack() {
    if (_attackCd > 0 || _gameOver) return;
    _attackCd = .55;
    final double dist = (_player - const Offset(.78, .52)).distance;
    if (dist < .32) {
      _enemyHp = math.max(0, _enemyHp - (7 + _level)).toDouble();
      _gold += 12;
      if (_enemyHp <= 0) {
        _kills++;
        _level++;
        _finish(true);
      }
    }
    setState(() {});
  }

  void _skill() {
    if (_skillCd > 0 || _mana < 25 || _gameOver) return;
    _skillCd = 5;
    _mana -= 25;
    final double dist = (_player - const Offset(.78, .52)).distance;
    if (dist < .48) {
      _enemyHp = math.max(0, _enemyHp - 18).toDouble();
      if (_enemyHp <= 0) {
        _kills++;
        _level++;
        _finish(true);
      }
    }
    setState(() {});
  }

  void _finish(bool win) {
    _gameOver = true;
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(win ? 'VICTORY!' : 'DEFEAT'),
          content: Text(win ? 'Enemy core destroyed.' : 'Your hero has fallen.'),
          actions: <Widget>[
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _player = const Offset(.22, .53);
                  _hp = 100;
                  _mana = 100;
                  _enemyHp = 100;
                  _gameOver = false;
                });
              },
              child: const Text('PLAY AGAIN'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101b20),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(
                painter: _BattlePainter(
                  player: _player,
                  minions: _minions,
                  enemyHp: _enemyHp,
                  time: _time,
                ),
              ),
            ),
            Positioned(left: 12, top: 10, child: _topHud()),
            Positioned(right: 12, top: 12, child: _minimap()),
            Positioned(left: 22, bottom: 20, child: _joystick()),
            Positioned(right: 22, bottom: 18, child: _skills()),
          ],
        ),
      ),
    );
  }

  Widget _topHud() => Row(
    children: <Widget>[
      _bar('HP', _hp / 100, const Color(0xff38c976), 155),
      const SizedBox(width: 8),
      _bar('MP', _mana / 100, const Color(0xff4f9fff), 120),
      const SizedBox(width: 10),
      Material(
        color: Colors.black.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Text('LV $_level   K $_kills   \$$_gold',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    ],
  );

  Widget _bar(String label, double value, Color color, double width) => Container(
    width: width,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontSize: 10)),
        const SizedBox(height: 3),
        LinearProgressIndicator(value: value.clamp(0, 1), color: color, minHeight: 7),
      ],
    ),
  );

  Widget _minimap() => Container(
    width: 108,
    height: 108,
    decoration: BoxDecoration(
      color: const Color(0xff173543).withValues(alpha: .92),
      border: Border.all(color: Colors.white24),
      borderRadius: BorderRadius.circular(54),
    ),
    child: const Center(child: Icon(Icons.map_outlined, size: 44, color: Colors.white70)),
  );

  Widget _joystick() => GestureDetector(
    onPanStart: (_) {},
    onPanUpdate: _updateJoy,
    onPanEnd: (_) => setState(() => _joy = Offset.zero),
    child: Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: .32)),
      child: Center(
        child: Transform.translate(
          offset: _joy * 42,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withValues(alpha: .55)),
          ),
        ),
      ),
    ),
  );

  void _updateJoy(DragUpdateDetails d) {
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Offset local = box.globalToLocal(d.globalPosition);
    // Use only direction; clamped so the simulation remains stable.
    final Size size = MediaQuery.of(context).size;
    final Offset center = Offset(86, size.height - 84);
    final Offset delta = local - center;
    setState(() => _joy = Offset(delta.dx / 64, delta.dy / 64));
    _joy = Offset(_joy.dx.clamp(-1, 1).toDouble(), _joy.dy.clamp(-1, 1).toDouble());
  }

  Widget _skills() => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      _roundButton(Icons.auto_fix_high, _skill, _skillCd > 0 ? _skillCd.ceil().toString() : 'SKILL'),
      const SizedBox(width: 12),
      _roundButton(Icons.gps_fixed, _attack, _attackCd > 0 ? '...' : 'ATK', big: true),
    ],
  );

  Widget _roundButton(IconData icon, VoidCallback onTap, String text, {bool big = false}) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: big ? 86 : 68,
      height: big ? 86 : 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: big ? const Color(0xffc34d35) : const Color(0xff5066b8),
        border: Border.all(color: Colors.white54, width: 2),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Icon(icon),
        Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
    ),
  );
}

class _Minion {
  _Minion(this.x, this.y, this.ally);
  double x;
  final double y;
  final bool ally;
}

class _BattlePainter extends CustomPainter {
  const _BattlePainter({required this.player, required this.minions, required this.enemyHp, required this.time});
  final Offset player;
  final List<_Minion> minions;
  final double enemyHp;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint();
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xff285e46));

    // Three-lane MOBA battlefield.
    for (final double y in <double>[.30, .50, .70]) {
      final Path lane = Path()
        ..moveTo(0, size.height * y)
        ..quadraticBezierTo(size.width * .5, size.height * (y + .04), size.width, size.height * y);
      canvas.drawPath(lane, Paint()..color = const Color(0xff7b7465)..style = PaintingStyle.stroke..strokeWidth = size.height * .055);
    }

    canvas.drawRect(Rect.fromLTWH(size.width * .47, 0, size.width * .06, size.height), Paint()..color = const Color(0xff327b9b));
    p.color = const Color(0xff183e2b);
    for (int i = 0; i < 30; i++) {
      final double x = ((i * 79.0) + math.sin(time + i) * 20) % size.width;
      final double y = ((i * 47.0) + 60) % size.height;
      canvas.drawCircle(Offset(x, y), 10 + (i % 3) * 6, p);
    }

    _tower(canvas, size, .16, .50, const Color(0xff438cff));
    _tower(canvas, size, .84, .50, const Color(0xffe5525c));
    for (final _Minion m in minions) {
      p.color = m.ally ? const Color(0xff69a9ff) : const Color(0xffff6b72);
      canvas.drawCircle(Offset(size.width * m.x, size.height * m.y), 9, p);
    }

    final Offset hero = Offset(size.width * player.dx, size.height * player.dy);
    canvas.drawCircle(hero, 24, Paint()..color = const Color(0xff69b7ff));
    canvas.drawCircle(hero.translate(0, -2), 14, Paint()..color = const Color(0xffd8e6ef));

    final Offset enemy = Offset(size.width * .78, size.height * .52);
    canvas.drawCircle(enemy, 27, Paint()..color = const Color(0xffd85b68));
    final Rect hp = Rect.fromCenter(center: enemy.translate(0, -40), width: 70, height: 6);
    canvas.drawRect(hp, Paint()..color = Colors.black54);
    canvas.drawRect(Rect.fromLTWH(hp.left, hp.top, hp.width * (enemyHp / 100), hp.height), Paint()..color = const Color(0xff4bd16d));
  }

  void _tower(Canvas canvas, Size size, double x, double y, Color color) {
    final Offset c = Offset(size.width * x, size.height * y);
    canvas.drawCircle(c, 25, Paint()..color = const Color(0xff3d4149));
    canvas.drawCircle(c, 14, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BattlePainter old) => true;
}
