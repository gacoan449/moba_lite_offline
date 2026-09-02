import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'moba_3d_phase2.dart';

/// Phase 4: BRUTAL campaign command layer.
/// The selected difficulty is intentionally exposed as a campaign parameter.
/// The existing Phase 2 battle core remains the simulation underneath until
/// its difficulty/state is made injectable in the next modular combat pass.
class Moba3DPhase4 extends StatefulWidget {
  const Moba3DPhase4({super.key});
  @override State<Moba3DPhase4> createState() => _Moba3DPhase4State();
}

class _Moba3DPhase4State extends State<Moba3DPhase4> {
  int difficulty = 25;
  bool temporal = true;
  bool sound = true;
  bool started = false;
  bool nightmare = false;

  String get rank => difficulty >= 90 ? 'NIGHTMARE' : difficulty >= 70 ? 'HELL' : difficulty >= 40 ? 'BRUTAL' : 'HARD';

  @override
  Widget build(BuildContext context) {
    if (started) {
      return Scaffold(
        body: Stack(children: [
          const Positioned.fill(child: Moba3DPhase2()),
          if (temporal) const Positioned.fill(child: _TemporalStorm()),
          Positioned(
            top: 8,
            left: 8,
            child: SafeArea(child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Text('PHASE 4 • $rank • CAMPAIGN LV $difficulty${temporal ? ' • TIME' : ''}${sound ? ' • SFX' : ''}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900))),
            )),
          ),
          Positioned(bottom: 8, left: 8, child: SafeArea(child: Text('BRUTAL PROTOCOL • Objective: break every enemy turret, then destroy the core.', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(.7), fontWeight: FontWeight.w700)))),
        ]),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xff17070b), Color(0xff3d111b), Color(0xff070a12)])),
        child: SafeArea(child: Center(child: SingleChildScrollView(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 820), child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [
          const Text('ARENA LEGENDS', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 3)),
          const Text('PHASE 4 • BRUTAL CAMPAIGN', style: TextStyle(fontSize: 16, color: Colors.redAccent, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Card(color: Colors.black54, child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            Row(children: [const Text('CAMPAIGN DIFFICULTY', style: TextStyle(fontWeight: FontWeight.w900)), const Spacer(), Text('$difficulty / 100', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900))]),
            Slider(value: difficulty.toDouble(), min: 1, max: 100, divisions: 99, onChanged: (v) => setState(() => difficulty = v.round())),
            Align(alignment: Alignment.centerLeft, child: Text(rank, style: const TextStyle(color: Colors.orangeAccent, fontSize: 22, fontWeight: FontWeight.w900))),
            const SizedBox(height: 8),
            const _Threat('AI aggression increases'),
            const _Threat('Enemy pressure and objective control become harsher'),
            const _Threat('Higher levels are intended for a future injectable combat-scaling core'),
            const _Threat('Turrets must fall before the enemy core can be finished'),
            const _Threat('Death/respawn and three-lane war remain active'),
          ]))),
          const SizedBox(height: 12),
          Card(color: Colors.black54, child: Column(children: [
            SwitchListTile(title: const Text('TEMPORAL WARFARE'), subtitle: const Text('4D-inspired time layer: afterimage/slow-time foundation, not literal fourth spatial dimension.'), value: temporal, onChanged: (v) => setState(() => temporal = v)),
            SwitchListTile(title: const Text('BATTLE SOUND'), subtitle: const Text('System feedback is enabled; full authored SFX/music asset pack remains a production asset pass.'), value: sound, onChanged: (v) => setState(() => sound = v)),
          ])),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 60, child: FilledButton.icon(onPressed: () async { if (sound) await SystemSound.play(SystemSoundType.click); setState(() => started = true); }, icon: const Icon(Icons.warning_amber_rounded), label: Text('ENTER $rank WAR', style: const TextStyle(fontWeight: FontWeight.w900)))),
          const SizedBox(height: 10),
          const Text('FASE 4 memprioritaskan campaign/progression dan temporal presentation. Sistem combat internal Phase 2 masih menjadi battle core agar tidak dipalsukan sebagai scaling 100% sebelum arsitekturnya injectable.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 11)),
        ]))))),
      ),
    );
  }
}

class _Threat extends StatelessWidget {
  const _Threat(this.text);
  final String text;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [const Icon(Icons.bolt, size: 16, color: Colors.orangeAccent), const SizedBox(width: 7), Expanded(child: Text(text))]));
}

class _TemporalStorm extends StatefulWidget {
  const _TemporalStorm();
  @override State<_TemporalStorm> createState() => _TemporalStormState();
}
class _TemporalStormState extends State<_TemporalStorm> {
  double phase = 0;
  Timer? timer;
  @override void initState() { super.initState(); timer = Timer.periodic(const Duration(milliseconds: 70), (_) { if (mounted) setState(() => phase += .055); }); }
  @override void dispose() { timer?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) => IgnorePointer(child: CustomPaint(painter: _TemporalStormPainter(phase)));
}
class _TemporalStormPainter extends CustomPainter {
  const _TemporalStormPainter(this.phase);
  final double phase;
  @override void paint(Canvas canvas, Size size) {
    final pulse = .018 + math.sin(phase).abs() * .018;
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0..color = Colors.redAccent.withOpacity(pulse);
    for (var i = 0; i < 7; i++) {
      final w = size.width * (.35 + i * .1);
      final h = size.height * (.22 + i * .035);
      canvas.drawOval(Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: w, height: h), p);
    }
  }
  @override bool shouldRepaint(covariant _TemporalStormPainter oldDelegate) => oldDelegate.phase != phase;
}
