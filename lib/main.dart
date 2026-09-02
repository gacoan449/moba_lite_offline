import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game/moba_game.dart';
import 'game/data/hero_catalog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final game = MOBAOfflineGame(initialPremiumStatus: prefs.getBool('is_premium_weapon') ?? false);

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true),
    home: Scaffold(
      body: GameWidget<MOBAOfflineGame>(
        game: game,
        overlayBuilderMap: {
          'HUD': (context, game) => ValueListenableBuilder<int>(
            valueListenable: game.hudTick,
            builder: (_, __, ___) => SafeArea(
              child: Stack(children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(.72), borderRadius: BorderRadius.circular(18)),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('⚔️ ARENA LEGENDS 3D  •  ${game.selectedHero.name}  •  ${game.selectedHero.role}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      SizedBox(width: 285, child: LinearProgressIndicator(value: game.player.hp / game.player.maxHp, minHeight: 7)),
                      const SizedBox(height: 4),
                      Text('❤️ ${game.player.hp.ceil()}  💧 ${game.player.mana.ceil()}  🪙 ${game.gold}  🟡 ${game.coins}  ☠ ${game.enemyKilled}'),
                      Text(game.quest, style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
                    ]),
                  ),
                ),
                Positioned(top: 92, right: 10, child: Column(children: [
                  _MenuButton(icon: Icons.people_alt, label: 'HERO', onTap: () => _showHeroes(context, game)),
                  _MenuButton(icon: Icons.auto_awesome, label: 'SKIN', onTap: () => _showSkins(context, game)),
                  _MenuButton(icon: Icons.public, label: 'MABAR', onTap: () => _showMultiplayer(context)),
                ])),
                Positioned(bottom: 18, left: 18, child: _AdRewardButton(game: game)),
              ]),
            ),
          ),
          'GAME_OVER_NORMAL': (context, game) => Center(
            child: Card(
              color: Colors.black87,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('PERTEMPURAN BERAKHIR', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('Level ${game.currentLevel} • ${game.enemyKilled} musuh • ${game.gold} gold'),
                  const SizedBox(height: 18),
                  ElevatedButton(onPressed: game.resetGame, child: const Text('Main Lagi')),
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

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: ElevatedButton.icon(onPressed: onTap, icon: Icon(icon, size: 17), label: Text(label, style: const TextStyle(fontSize: 11))),
  );
}

class _AdRewardButton extends StatelessWidget {
  final MOBAOfflineGame game;
  const _AdRewardButton({required this.game});
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: () async {
      await game.onRewardedAdCompleted();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reward +100 coin diterapkan. Hubungkan callback ini ke Google AdMob Rewarded Ad.')));
      }
    },
    icon: const Icon(Icons.ondemand_video),
    label: const Text('TONTON IKLAN +100', style: TextStyle(fontSize: 11)),
  );
}

void _showHeroes(BuildContext context, MOBAOfflineGame game) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF101614),
    builder: (_) => SafeArea(child: SizedBox(height: MediaQuery.of(context).size.height * .72, child: ValueListenableBuilder<int>(
      valueListenable: game.hudTick,
      builder: (_, __, ___) => ListView(padding: const EdgeInsets.all(16), children: [
        Text('HEROES  •  ${game.coins} COIN', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Hero gratis + hero premium. Harga dan progres disimpan lokal.'),
        const SizedBox(height: 14),
        ...heroCatalog.map((hero) {
          final owned = game.ownedHeroes.contains(hero.id);
          return Card(child: ListTile(
            leading: CircleAvatar(child: Text(hero.name[0])),
            title: Text('${hero.name}  •  ${hero.role}'),
            subtitle: Text('${hero.description}\nHP ${hero.hp} • DMG ${hero.damage} • Speed ${hero.speed}'),
            isThreeLine: true,
            trailing: ElevatedButton(
              onPressed: () async {
                if (owned) {
                  await game.selectHero(hero);
                } else {
                  final ok = await game.buyHero(hero);
                  if (!ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coin belum cukup.')));
                }
              },
              child: Text(owned ? (game.selectedHeroId == hero.id ? 'DIPAKAI' : 'PILIH') : '${hero.price} 🟡'),
            ),
          ));
        }),
      ]),
    ))),
  );
}

void _showSkins(BuildContext context, MOBAOfflineGame game) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF101614),
    builder: (_) => SafeArea(child: SizedBox(height: MediaQuery.of(context).size.height * .65, child: ValueListenableBuilder<int>(
      valueListenable: game.hudTick,
      builder: (_, __, ___) => ListView(padding: const EdgeInsets.all(16), children: [
        Text('SKIN SHOP  •  ${game.coins} COIN', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...skinCatalog.map((skin) {
          final id = skin['id']! as String;
          final hero = skin['hero']! as String;
          final owned = game.ownedSkins.contains(id);
          final heroOwned = game.ownedHeroes.contains(hero);
          return Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.auto_awesome)),
            title: Text(skin['name']! as String),
            subtitle: Text(heroOwned ? 'Skin tersedia' : 'Beli hero ${hero.toUpperCase()} terlebih dahulu'),
            trailing: ElevatedButton(
              onPressed: heroOwned ? () async {
                if (owned) {
                  await game.buySkin({...skin, 'price': 0});
                } else {
                  final ok = await game.buySkin(skin);
                  if (!ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coin belum cukup atau skin tidak tersedia.')));
                }
              } : null,
              child: Text(owned ? 'PAKAI' : '${skin['price']} 🟡'),
            ),
          ));
        }),
      ]),
    ))),
  );
}

void _showMultiplayer(BuildContext context) {
  showDialog(context: context, builder: (_) => AlertDialog(
    title: const Text('🌐 MABAR ONLINE'),
    content: const Text('Fondasi multiplayer sudah dipisahkan dari gameplay.\n\nRoom / matchmaking, sinkronisasi posisi, server-authoritative combat, chat dan reconnect membutuhkan backend realtime. Project ini sengaja tidak mengubah pubspec.yaml atau workflow yang sudah ada.'),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('SIAP'))],
  ));
}
