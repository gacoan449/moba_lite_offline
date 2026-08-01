import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game/moba_game.dart';
// import 'ui/overlays/qris_overlay.dart'; // Aktifkan jika file UI QRIS sudah Anda buat

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Ambil state senjata dari Local Storage
  final prefs = await SharedPreferences.getInstance();
  final isPremium = prefs.getBool('is_premium_weapon') ?? false;

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: GameWidget<MOBAOfflineGame>(
        game: MOBAOfflineGame(initialPremiumStatus: isPremium),
        overlayBuilderMap: {
          'QRIS_PAYWALL': (context, game) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                color: Colors.black87,
                child: const Text(
                  "UI QRIS DITAMPILKAN DI SINI\n(Buat di lib/ui/overlays/qris_overlay.dart)",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            );
            // Return QrisOverlay(game: game, prefs: prefs);
          },
          'GAME_OVER_NORMAL': (context, game) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  game.overlays.remove('GAME_OVER_NORMAL');
                  // Logika reset level
                },
                child: const Text("Coba Lagi"),
              ),
            );
          }
        },
      ),
    ),
  ));
}
