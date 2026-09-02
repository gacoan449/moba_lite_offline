import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/hero_player.dart';
import 'components/bot_enemy.dart';
import 'components/minion.dart';
import 'components/turret.dart';
import 'components/jungle_monster.dart';
import 'data/hero_catalog.dart';

class MOBAOfflineGame extends FlameGame with HasCollisionDetection {
 final bool initialPremiumStatus; bool isPremiumWeapon; int currentLevel=1,enemyKilled=0,gold=0,xp=0,heroRank=1,coins=0;
 String selectedHeroId='astra',selectedSkinId='astra_default'; final Set<String> ownedHeroes={'astra'},ownedSkins={'astra_default'};
 String quest='Hancurkan turret musuh dan menangkan pertandingan'; double messageTimer=0; final ValueNotifier<int> hudTick=ValueNotifier(0); bool victory=false;
 late HeroPlayerComponent player; late JoystickComponent joystick; late HudButtonComponent attackButton,skillButton;
 final List<BotEnemyComponent> enemies=[]; final List<MinionComponent> minions=[]; final List<TurretComponent> turrets=[]; final List<JungleMonster> monsters=[]; SharedPreferences? _prefs;
 MOBAOfflineGame({required this.initialPremiumStatus}):isPremiumWeapon=initialPremiumStatus;
 HeroDefinition get selectedHero=>heroCatalog.firstWhere((h)=>h.id==selectedHeroId);
 @override Color backgroundColor()=>const Color(0xff10251a);
 @override Future<void> onLoad() async {await super.onLoad();_prefs=await SharedPreferences.getInstance();coins=_prefs?.getInt('moba_coins')??0;selectedHeroId=_prefs?.getString('selected_hero')??'astra';selectedSkinId=_prefs?.getString('selected_skin')??'astra_default';ownedHeroes.addAll(_prefs?.getStringList('owned_heroes')??['astra']);ownedSkins.addAll(_prefs?.getStringList('owned_skins')??['astra_default']);player=HeroPlayerComponent();world.add(player);applyHeroStats();camera.follow(player);
  joystick=JoystickComponent(knob:CircleComponent(radius:30,paint:BasicPalette.white.withAlpha(220).paint()),background:CircleComponent(radius:78,paint:BasicPalette.black.withAlpha(150).paint()),margin:const EdgeInsets.only(left:28,bottom:30));camera.viewport.add(joystick);
  attackButton=HudButtonComponent(button:CircleComponent(radius:43,paint:Paint()..color=Colors.redAccent.withOpacity(.9)),margin:const EdgeInsets.only(right:28,bottom:30),onPressed:()=>player.basicAttack(isPremiumWeapon));camera.viewport.add(attackButton);
  skillButton=HudButtonComponent(button:CircleComponent(radius:32,paint:Paint()..color=Colors.deepPurpleAccent.withOpacity(.9)),margin:const EdgeInsets.only(right:115,bottom:36),onPressed:player.useSkill);camera.viewport.add(skillButton);buildBattlefield();overlays.add('HUD');}
 void applyHeroStats(){player.maxHp=selectedHero.hp.toDouble();player.hp=player.maxHp;player.speed=selectedHero.speed;player.baseDamage=selectedHero.damage.toDouble();player.baseSkillDamage=selectedHero.skillDamage.toDouble();}
 void buildBattlefield(){for(final t in List<TurretComponent>.from(turrets))t.removeFromParent();for(final m in List<JungleMonster>.from(monsters))m.removeFromParent();for(final e in List<BotEnemyComponent>.from(enemies))e.removeFromParent();for(final m in List<MinionComponent>.from(minions))m.removeFromParent();turrets.clear();monsters.clear();enemies.clear();minions.clear();
  const lanes=[-560.0,0.0,560.0];for(final y in lanes){for(final x in [-2050.0,-1250.0]){final t=TurretComponent(position:Vector2(x,y),allied:true,lane:'lane');turrets.add(t);world.add(t);}for(final x in [1250.0,2050.0]){final t=TurretComponent(position:Vector2(x,y),allied:false,lane:'lane');turrets.add(t);world.add(t);}}
  for(final p in [Vector2(-950,-300),Vector2(-950,300),Vector2(0,-900),Vector2(0,900)]){final m=JungleMonster(position:p);monsters.add(m);world.add(m);}final boss=JungleMonster(position:Vector2(0,0),boss:true);monsters.add(boss);world.add(boss);spawnWave();spawnEnemyHeroes();}
 void spawnEnemyHeroes(){for(int i=0;i<5;i++){final e=BotEnemyComponent(Vector2(1800,[-560.0,0,560,-120,120][i]));enemies.add(e);world.add(e);}}
 void spawnWave(){const lanes=[-560.0,0.0,560.0];for(final y in lanes){for(int i=0;i<3;i++){final a=MinionComponent(position:Vector2(-2500-i*55,y),allied:true,ranged:i==2);final b=MinionComponent(position:Vector2(2500+i*55,y),allied:false,ranged:i==2);minions..add(a)..add(b);world.add(a);world.add(b);}}quest='3 LANE • MINION WAVE • HANCURKAN TURRET';}
 @override void update(double dt){super.update(dt);enemies.removeWhere((e)=>e.isRemoved);minions.removeWhere((e)=>e.isRemoved);turrets.removeWhere((e)=>e.isRemoved);monsters.removeWhere((e)=>e.isRemoved);messageTimer=max(0,messageTimer-dt);hudTick.value++;if(!victory&&turrets.where((t)=>!t.allied&&!t.destroyed).isEmpty){victory=true;quest='MENANG! SEMUA TURRET MUSUH HANCUR';overlays.add('GAME_OVER_NORMAL');pauseEngine();}}
 void onTurretDestroyed(TurretComponent t){gold+=180;xp+=120;flashMessage('TURRET MUSUH HANCUR! +180 GOLD');}
 void onMonsterKilled(JungleMonster m){gold+=m.boss?500:80;xp+=m.boss?350:70;flashMessage(m.boss?'BOSS JUNGLE DIKALAHKAN! +500 GOLD':'MONSTER JUNGLE DIKALAHKAN! +80 GOLD');}
 void onEnemyKilled(){enemyKilled++;gold+=25;xp+=30;if(enemyKilled%5==0){currentLevel++;heroRank=1+(xp~/100);player.maxHp+=15;player.hp=player.maxHp;flashMessage('LEVEL $currentLevel • POWER NAIK');}}
 void flashMessage(String text){quest=text;messageTimer=2;}
 Future<void> selectHero(HeroDefinition h)async{if(!ownedHeroes.contains(h.id))return;selectedHeroId=h.id;await _prefs?.setString('selected_hero',h.id);applyHeroStats();hudTick.value++;}
 Future<bool> buyHero(HeroDefinition h)async{if(ownedHeroes.contains(h.id))return true;if(coins<h.price)return false;coins-=h.price;ownedHeroes.add(h.id);await _saveWallet();await selectHero(h);return true;}
 Future<bool> buySkin(Map<String,Object>s)async{final id=s['id']! as String,hero=s['hero']! as String,price=s['price']! as int;if(!ownedHeroes.contains(hero)||ownedSkins.contains(id)||coins<price)return false;coins-=price;ownedSkins.add(id);await equipSkin(s);await _saveWallet();return true;}
 Future<void> equipSkin(Map<String,Object>s)async{final id=s['id']! as String;if(!ownedSkins.contains(id))return;selectedSkinId=id;await _prefs?.setString('selected_skin',id);hudTick.value++;}
 Future<void> onRewardedAdCompleted()async{coins+=100;await _saveWallet();flashMessage('+100 COIN');hudTick.value++;}
 Future<void> _saveWallet()async{await _prefs?.setInt('moba_coins',coins);await _prefs?.setStringList('owned_heroes',ownedHeroes.toList());await _prefs?.setStringList('owned_skins',ownedSkins.toList());}
 void resetGame(){victory=false;currentLevel=1;enemyKilled=0;gold=0;xp=0;heroRank=1;player.reset();overlays.remove('GAME_OVER_NORMAL');resumeEngine();buildBattlefield();}
 void triggerGameOver(){if(victory)return;overlays.add('GAME_OVER_NORMAL');pauseEngine();}
 @override void render(Canvas c){c.drawRect(const Rect.fromLTWH(-3500,-1800,7000,3600),Paint()..color=const Color(0xff294b31));final lane=Paint()..color=const Color(0xffb49a67)..strokeWidth=120..style=PaintingStyle.stroke;for(final y in [-560.0,0.0,560.0])c.drawLine(Offset(-3000,y),Offset(3000,y),lane);c.drawRect(const Rect.fromLTWH(-120,-1800,240,3600),Paint()..color=const Color(0xff2b6780).withOpacity(.55));final jungle=Paint()..color=const Color(0xff173821);for(final r in [Rect.fromLTWH(-1150,-800,500,380),Rect.fromLTWH(650,-800,500,380),Rect.fromLTWH(-1150,420,500,380),Rect.fromLTWH(650,420,500,380)])c.drawRect(r,jungle);c.drawRect(const Rect.fromLTWH(-2900,-1000,300,2000),Paint()..color=const Color(0xff2456a5).withOpacity(.7));c.drawRect(const Rect.fromLTWH(2600,-1000,300,2000),Paint()..color=const Color(0xffa42d3b).withOpacity(.7));super.render(c);}
}
