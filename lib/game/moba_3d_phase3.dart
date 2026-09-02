import 'dart:async';
import 'package:flutter/material.dart';
import 'moba_3d_phase2.dart';

/// Phase 3 command layer for Arena Legends 3D.
/// Keeps the proven Phase-2 battle simulation intact while adding a
/// production-style pre-match shell: difficulty, graphics profile,
/// temporal/4D-inspired mode and battle rules.
class Moba3DPhase3 extends StatefulWidget {
  const Moba3DPhase3({super.key});

  @override
  State<Moba3DPhase3> createState() => _Moba3DPhase3State();
}

class _Moba3DPhase3State extends State<Moba3DPhase3> {
  int difficulty = 3;
  String quality = 'HIGH';
  bool temporal = true;
  bool sound = true;
  bool started = false;
  bool cinematic = false;

  @override
  Widget build(BuildContext context) {
    if (started) {
      return Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: Moba3DPhase2()),
            if (temporal) const _TemporalLayer(),
            Positioned(
              top: 8,
              left: 8,
              child: SafeArea(
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      'PHASE 3 • $quality • DIFF $difficulty${temporal ? ' • TEMPORAL' : ''}${sound ? ' • AUDIO' : ''}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff081426), Color(0xff163c57), Color(0xff08111d)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      const Text('ARENA LEGENDS', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 3)),
                      const Text('3D • PHASE 3', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.cyanAccent)),
                      const SizedBox(height: 18),
                      _panel(
                        title: 'BATTLE CONFIGURATION',
                        child: Column(
                          children: [
                            _slider('DIFFICULTY', difficulty.toDouble(), 1, 20, (v) => setState(() => difficulty = v.round())),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('GRAPHICS', style: TextStyle(fontWeight: FontWeight.w800)),
                                const Spacer(),
                                DropdownButton<String>(
                                  value: quality,
                                  items: const ['LOW', 'MEDIUM', 'HIGH', 'ULTRA'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                                  onChanged: (v) => setState(() => quality = v ?? quality),
                                ),
                              ],
                            ),
                            SwitchListTile(title: const Text('Temporal / 4D-inspired combat layer'), subtitle: const Text('Time phase, afterimage and slow-time visual architecture'), value: temporal, onChanged: (v) => setState(() => temporal = v)),
                            SwitchListTile(title: const Text('Battle audio'), subtitle: const Text('Audio switch reserved for the Phase 3 asset/audio pipeline'), value: sound, onChanged: (v) => setState(() => sound = v)),
                            SwitchListTile(title: const Text('Cinematic camera'), value: cinematic, onChanged: (v) => setState(() => cinematic = v)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _panel(
                        title: 'MOBA RULES',
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Rule('3 lanes + river + jungle'),
                            _Rule('Minion waves push each lane'),
                            _Rule('Turrets must fall before the enemy core'),
                            _Rule('Core destroyed = match over'),
                            _Rule('Hero death = respawn, not instant elimination'),
                            _Rule('Gold + XP + levels + items'),
                            _Rule('Keyboard remapping + touch controls'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: FilledButton.icon(
                          onPressed: () => setState(() => started = true),
                          icon: const Icon(Icons.sports_esports),
                          label: Text('MULAI PERANG • LEVEL $difficulty', style: const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('Phase 3 memakai mesin pertarungan 3D Phase 2 yang sudah ada; konfigurasi berikut menjadi command layer untuk pengembangan sistem lanjutan.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel({required String title, required Widget child}) => Card(
        color: Colors.black.withOpacity(.45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, letterSpacing: 1.2)), const SizedBox(height: 10), child]),
        ),
      );

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w800)), const Spacer(), Text(value.round().toString(), style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900))]),
          Slider(value: value, min: min, max: max, divisions: (max - min).round(), onChanged: onChanged),
        ],
      );
}

class _Rule extends StatelessWidget {
  const _Rule(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [const Icon(Icons.check_circle, size: 16, color: Colors.lightGreenAccent), const SizedBox(width: 8), Expanded(child: Text(text))]),
      );
}

class _TemporalLayer extends StatefulWidget {
  const _TemporalLayer();
  @override
  State<_TemporalLayer> createState() => _TemporalLayerState();
}

class _TemporalLayerState extends State<_TemporalLayer> {
  double phase = 0;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 80), (_) { if (mounted) setState(() => phase += .04); });
  }
  @override
  void dispose() { timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(painter: _TemporalPainter(phase)),
      );
}

class _TemporalPainter extends CustomPainter {
  const _TemporalPainter(this.phase);
  final double phase;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = Colors.cyanAccent.withOpacity(.035);
    final r = (phase.sin().abs() * 22) + 20;
    for (var i = 0; i < 4; i++) {
      final rr = r + i * 28;
      canvas.drawOval(Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: size.width * .6 + rr, height: size.height * .32 + rr / 2), p);
    }
  }
  @override
  bool shouldRepaint(covariant _TemporalPainter oldDelegate) => oldDelegate.phase != phase;
}
