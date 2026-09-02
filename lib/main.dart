import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/moba_3d_phase5.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ArenaLegendsApp());
}

class ArenaLegendsApp extends StatelessWidget {
  const ArenaLegendsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Arena Legends 3D',
        theme: ThemeData.dark(useMaterial3: true),
        home: const Moba3DPhase5(),
      );
}
