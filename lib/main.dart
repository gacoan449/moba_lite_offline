import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game/moba_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final game = MOBAOfflineGame(initialPremiumStatus: prefs.getBool('is_premium_weapon') ?? false);

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: GameWidget<MOBAOfflineGame>(
        game: game,
        overlayBuilderMap: {
          'HUD': (context, game) => SafeArea(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: ValueListenableBuilder(
                    valueListenable: game.player,
                    builder: (_, __, ___) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(.65), borderRadius: BorderRadius.circular(16)),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('⚔️ MOBA LITE • LV ${game.currentLevel} • RANK ${game.heroRank}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        SizedBox(width: 280, child: LinearProgressIndicator(value: game.player.hp / game.player.maxHp, minHeight: 8)),
                        const SizedBox(height: 4),
                        Text('❤️ ${game.player.hp.ceil()}   💧 ${game.player.mana.ceil()}   🪙 ${game.gold}   ⚔️ ${game.enemyKilled}', style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(game.quest, style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
          'GAME_OVER_NORMAL': (context, game) => Center(
            child: Card(
              color: Colors.black87,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('PETUALANGAN BERAKHIR', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('Level ${game.currentLevel} • ${game.enemyKilled} musuh • ${game.gold} gold', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 18),
                  ElevatedButton(onPressed: game.resetGame, child: const Text('Mulai Lagi')),
                ]),
              ),
            ),
          ),
        },
        initialActiveOverlays: const ['HUD'],
      ),
    ),
  ));
}
