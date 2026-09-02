import 'package:flutter/material.dart';
import 'moba_3d_phase5.dart';

/// Stable world entry point kept for backwards compatibility.
/// Phase 5 is the maintained three_js runtime.
class Moba3DWorld extends StatelessWidget {
  const Moba3DWorld({super.key});

  @override
  Widget build(BuildContext context) => const Moba3DPhase5();
}
