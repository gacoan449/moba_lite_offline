import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game/moba_game.dart';
import 'game/data/hero_catalog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final prefs = await SharedPreferences.getInstance();
  final game = MOBAOfflineGame(initialPremiumStatus: prefs.getBool('is_premium_weapon') ?? false);
  runApp(MaterialApp(debugShowCheckedModeBanner:false,theme:ThemeData.dark(useMaterial3:true),home:Scaffold(body:GameWidget<MOBAOfflineGame>(game:game,overlayBuilderMap:{
    'HUD':(context,game)=>ValueListenableBuilder<int>(valueListenable:game.hudTick,builder:(_,__,___)=>SafeArea(child:Stack(children:[
      Align(alignment:Alignment.topCenter,child:Container(margin:const EdgeInsets.all(8),padding:const EdgeInsets.symmetric(horizontal:14,vertical:6),decoration:BoxDecoration(color:Colors.black.withOpacity(.72),borderRadius:BorderRadius.circular(16)),child:Column(mainAxisSize:MainAxisSize.min,children:[Text('⚔ ARENA LEGENDS • ${game.selectedHero.name} • ${game.selectedHero.role}',style:const TextStyle(fontWeight:FontWeight.bold)),SizedBox(width:260,child:LinearProgressIndicator(value:game.player.hp/game.player.maxHp,minHeight:6)),Text('❤️${game.player.hp.ceil()}  💧${game.player.mana.ceil()}  🪙${game.gold}  🟡${game.coins}  ☠${game.enemyKilled}  LV.${game.currentLevel}',style:const TextStyle(fontSize:11)),Text(game.quest,style:const TextStyle(color:Colors.amberAccent,fontSize:10))]))),
      Positioned(top:55,right:8,child:Column(children:[_MenuButton(icon:Icons.people_alt,label:'HERO',onTap:()=>_showHeroes(context,game)),_MenuButton(icon:Icons.auto_awesome,label:'SKIN',onTap:()=>_showSkins(context,game)),_MenuButton(icon:Icons.public,label:'MABAR',onTap:()=>_showMultiplayer(context))])),
      Positioned(bottom:10,left:12,child:FilledButton.icon(onPressed:()=>game.onRewardedAdCompleted(),icon:const Icon(Icons.ondemand_video,size:17),label:const Text('IKLAN +100',style:TextStyle(fontSize:10))))]))),
    'GAME_OVER_NORMAL':(context,game)=>Center(child:Card(color:Colors.black87,child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(game.victory?'🏆 VICTORY':'💀 DEFEAT',style:const TextStyle(fontSize:28,fontWeight:FontWeight.bold)),const SizedBox(height:8),Text(game.victory?'Semua turret musuh hancur!':'Hero kamu tumbang.'),Text('Level ${game.currentLevel} • ${game.enemyKilled} kill • ${game.gold} gold'),const SizedBox(height:15),ElevatedButton(onPressed:game.resetGame,child:const Text('MAIN LAGI'))]))))},initialActiveOverlays:const ['HUD']))));
}
class _MenuButton extends StatelessWidget{final IconData icon;final String label;final VoidCallback onTap;const _MenuButton({required this.icon,required this.label,required this.onTap});@override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:5),child:SizedBox(width:82,height:32,child:ElevatedButton.icon(onPressed:onTap,icon:Icon(icon,size:14),label:Text(label,style:const TextStyle(fontSize:10)))));}
void _showHeroes(BuildContext context,MOBAOfflineGame game){showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:const Color(0xff101614),builder:(_)=>SafeArea(child:SizedBox(height:MediaQuery.of(context).size.height*.82,child:GridView.count(crossAxisCount:4,padding:const EdgeInsets.all(12),childAspectRatio:2.4,children:heroCatalog.map((h){final owned=game.ownedHeroes.contains(h.id);return Card(child:ListTile(leading:CircleAvatar(child:Text(h.name[0])),title:Text('${h.name} • ${h.role}',style:const TextStyle(fontSize:12)),subtitle:Text('HP ${h.hp} • DMG ${h.damage}',style:const TextStyle(fontSize:9)),trailing:TextButton(onPressed:()async{if(owned)await game.selectHero(h);else await game.buyHero(h);},child:Text(owned?(game.selectedHeroId==h.id?'PAKAI':'PILIH'):'${h.price}🟡',style:const TextStyle(fontSize:9))));}).toList()))));}
void _showSkins(BuildContext context,MOBAOfflineGame game){showModalBottomSheet(context:context,backgroundColor:const Color(0xff101614),builder:(_)=>ListView(padding:const EdgeInsets.all(16),children:skinCatalog.map((s)=>ListTile(title:Text(s['name']! as String),subtitle:Text('Hero ${s['hero']}'),trailing:Text('${s['price']} 🟡'))).toList()));}
void _showMultiplayer(BuildContext context){showDialog(context:context,builder:(_)=>const AlertDialog(title:Text('🌐 MABAR'),content:Text('Mode online membutuhkan backend realtime/matchmaking. Mode latihan lokal sudah memakai 5 musuh hero.')));}
