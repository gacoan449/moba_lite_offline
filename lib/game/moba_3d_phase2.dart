import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:three_js/three_js.dart' as three;

/// Phase 2 true-3D MOBA: lanes, waves, jungle, towers, cores, combat,
/// respawn, XP/levels, items, difficulty and remappable keyboard controls.
class Moba3DPhase2 extends StatefulWidget {
  const Moba3DPhase2({super.key});
  @override State<Moba3DPhase2> createState() => _Moba3DPhase2State();
}

class _Moba3DPhase2State extends State<Moba3DPhase2> {
  late three.ThreeJS threeJs;
  final FocusNode focus = FocusNode();
  final Set<LogicalKeyboardKey> keys = <LogicalKeyboardKey>{};
  final List<_Unit> enemies = <_Unit>[];
  final List<_Unit> minions = <_Unit>[];
  final List<_Tower> towers = <_Tower>[];
  final List<_Shot> shots = <_Shot>[];
  final List<_Camp> camps = <_Camp>[];
  late _Unit player;
  late _Core enemyCore;
  late _Core allyCore;
  Offset stick = Offset.zero;
  Timer? timer;
  bool attackHeld=false, ended=false, win=false, shop=false, settings=false, paused=false;
  String? remap;
  int level=1,xp=0,gold=600,kills=0,deaths=0,wave=0,difficulty=1;
  double hp=1200,mana=600,maxHp=1200,maxMana=600,atk=110,armor=12,speed=10;
  double basicCd=0,s1=0,s2=0,ult=0,waveCd=0,respawn=0;
  final Map<String,LogicalKeyboardKey> bind=<String,LogicalKeyboardKey>{
    'up':LogicalKeyboardKey.keyW,'down':LogicalKeyboardKey.keyS,'left':LogicalKeyboardKey.keyA,'right':LogicalKeyboardKey.keyD,
    'attack':LogicalKeyboardKey.keyJ,'skill1':LogicalKeyboardKey.keyK,'skill2':LogicalKeyboardKey.keyL,'ultimate':LogicalKeyboardKey.keyU,'shop':LogicalKeyboardKey.keyB,
  };

  @override void initState(){super.initState(); threeJs=three.ThreeJS(onSetupComplete:()=>setState((){}),setup:setup,settings:three.Settings(renderOptions:<String,dynamic>{'antialias':true,'powerPreference':'high-performance'})); timer=Timer.periodic(const Duration(milliseconds:80),(_){if(mounted)setState((){});});}
  @override void dispose(){timer?.cancel();focus.dispose();threeJs.dispose();super.dispose();}

  Future<void> setup() async{
    threeJs.camera=three.PerspectiveCamera(48,threeJs.width/math.max(1.0,threeJs.height),0.1,2000);
    threeJs.camera.position.setValues(-8,58,62); threeJs.scene=three.Scene(); threeJs.scene.background=three.Color(0.38,0.72,0.94);
    threeJs.scene.add(three.HemisphereLight(0xc9efff,0x26351f,1.6)); final sun=three.DirectionalLight(0xffffff,2.6);sun.position.setValues(-70,120,40);threeJs.scene.add(sun);
    _map();_structures();_heroes();_jungle();_wave();threeJs.camera.lookAt(three.Vector3(0,0,0));threeJs.addAnimationEvent(_tick);
  }
  three.Mesh _mesh(three.BufferGeometry g,int c){return three.Mesh(g,three.MeshStandardMaterial(<three.MaterialProperty,dynamic>{three.MaterialProperty.color:c,three.MaterialProperty.roughness:.72,three.MaterialProperty.metalness:.08}));}

  void _map(){
    final ground=_mesh(three.BoxGeometry(180,2,120),0x5da84d);ground.position.y=-1;threeJs.scene.add(ground);
    for(final z in <double>[-30,0,30]){final s=_mesh(three.BoxGeometry(170,.35,15),0x89857e);s.position.setValues(0,-.15,z);threeJs.scene.add(s);final l=_mesh(three.BoxGeometry(170,.8,11),0x686660);l.position.setValues(0,.1,z);threeJs.scene.add(l);}
    final r=_mesh(three.BoxGeometry(14,.25,120),0x2e9ed1);r.position.y=.2;threeJs.scene.add(r);
    for(final z in <double>[-42,-14,14,42]){final b=_mesh(three.BoxGeometry(19,1,8),0x9b7049);b.position.setValues(0,.6,z);threeJs.scene.add(b);}
    final rnd=math.Random(2030);for(int i=0;i<110;i++){final x=rnd.nextDouble()*155-77.5,z=rnd.nextDouble()*108-54;if(x.abs()<20||(z.abs()<38&&x.abs()<62))continue;_tree(x,z,.8+rnd.nextDouble()*1.5);}
  }
  void _tree(double x,double z,double s){final t=_mesh(three.CylinderGeometry(.7,1.1,5,8),0x6b4329);t.position.setValues(x,2.5*s,z);t.scale.setValues(s,s,s);threeJs.scene.add(t);final c=_mesh(three.IcosahedronGeometry(3.2,1),0x2e7e42);c.position.setValues(x,6*s,z);c.scale.setValues(s,s,s);threeJs.scene.add(c);}
  void _base(double x,int c){final p=_mesh(three.CylinderGeometry(11,13,1.5,8),0x313c45);p.position.setValues(x,.75,0);threeJs.scene.add(p);final q=_mesh(three.TorusGeometry(10,.65,12,48),c);q.position.setValues(x,1.8,0);q.rotation.x=math.pi/2;threeJs.scene.add(q);}
  three.Group _coreMesh(int c){final g=three.Group();final a=_mesh(three.OctahedronGeometry(6.2,1),c);a.position.y=1;g.add(a);final r=_mesh(three.TorusGeometry(8,.55,12,48),c);r.rotation.x=math.pi/2;r.position.y=-5;g.add(r);return g;}
  void _structures(){
    _base(-80,0x3f7cff);_base(80,0xe34d59);allyCore=_Core(three.Vector3(-80,7,0),true,3000);enemyCore=_Core(three.Vector3(80,7,0),false,3000);allyCore.mesh=_coreMesh(0x3f7cff);enemyCore.mesh=_coreMesh(0xe34d59);threeJs.scene.add(allyCore.mesh!);threeJs.scene.add(enemyCore.mesh!);
    for(final z in <double>[-30,0,30]){for(int i=0;i<2;i++){final a=_Tower(three.Vector3(38+i*16,4,z),false,z);a.mesh=_tower(0xe34d59);threeJs.scene.add(a.mesh!);towers.add(a);}for(int i=0;i<2;i++){final a=_Tower(three.Vector3(-38-i*16,4,z),true,z);a.mesh=_tower(0x3f7cff);threeJs.scene.add(a.mesh!);towers.add(a);}}
  }
  three.Group _tower(int c){final g=three.Group();final b=_mesh(three.CylinderGeometry(2.8,3.5,3.6,8),0x30373e);b.position.y=1.8;g.add(b);final x=_mesh(three.OctahedronGeometry(2.25,1),c);x.position.y=5.5;g.add(x);final r=_mesh(three.TorusGeometry(3,.22,8,32),c);r.rotation.x=math.pi/2;r.position.y=3;g.add(r);return g;}

  void _heroes(){
    player=_Unit(three.Vector3(-55,0,0),true,1200);player.mesh=_hero(0x3e8cff);threeJs.scene.add(player.mesh!);
    for(final p in <three.Vector3>[three.Vector3(55,0,-30),three.Vector3(55,0,0),three.Vector3(55,0,30),three.Vector3(30,0,-8),three.Vector3(30,0,8)]){final e=_Unit(p,false,800+difficulty*100);e.damage=48+difficulty*8;e.speed=4+difficulty*.25;e.lane=p.z;e.mesh=_hero(0xe95461);threeJs.scene.add(e.mesh!);enemies.add(e);}
  }
  three.Group _hero(int c){final g=three.Group();final b=_mesh(three.CapsuleGeometry(radius:1.5,length:2.8,capSegments:8,radialSegments:12),c);b.position.y=3;g.add(b);final h=_mesh(three.SphereGeometry(1.15,16,12),0xf0c4a0);h.position.y=5.7;g.add(h);final a=_mesh(three.BoxGeometry(3.7,.8,1.9),0x253344);a.position.y=3.9;g.add(a);final w=_mesh(three.CylinderGeometry(.16,.16,4.2,8),0xdceaff);w.rotation.z=math.pi/2;w.position.setValues(2,3,0);g.add(w);final q=_mesh(three.TorusGeometry(2.25,.12,8,40),c);q.rotation.x=math.pi/2;q.position.y=.25;g.add(q);return g;}
  void _jungle(){for(final p in <three.Vector3>[three.Vector3(-28,1,-16),three.Vector3(-28,1,16),three.Vector3(28,1,-16),three.Vector3(28,1,16)]){final c=_Camp(p,650+difficulty*100);final g=three.Group();final pad=_mesh(three.CylinderGeometry(3.4,3.8,.5,12),0x3d4c43);pad.position.y=.25;g.add(pad);final m=_mesh(three.IcosahedronGeometry(2,1),0xa06ad8);m.position.y=2.2;g.add(m);c.mesh=g;threeJs.scene.add(g);camps.add(c);}}

  void _wave(){if(ended)return;wave++;for(final z in <double>[-30,0,30]){for(int i=0;i<3;i++){_minion(true,z,-66-i*3,i==2);_minion(false,z,66+i*3,i==2);}}}
  void _minion(bool ally,double z,double x,bool ranged){final m=_Unit(three.Vector3(x,1.5,z),ally,330+level*18+difficulty*30);m.lane=z;m.damage=(ranged?38:52)+difficulty*5;m.ranged=ranged;m.mesh=_minionMesh(ally,ranged);threeJs.scene.add(m.mesh!);minions.add(m);}
  three.Group _minionMesh(bool ally,bool ranged){final g=three.Group();final b=_mesh(three.CylinderGeometry(1,1.2,2.2,8),ally?0x4d91ff:0xe95661);b.position.y=1.5;g.add(b);final h=_mesh(three.SphereGeometry(.75,12,8),0xf0c2a0);h.position.y=3;g.add(h);if(ranged){final o=_mesh(three.SphereGeometry(.35,10,8),0xffd95a);o.position.setValues(1,2.1,0);g.add(o);}return g;}

  void _tick(double dt){if(ended||paused)return;basicCd=math.max(0,basicCd-dt);s1=math.max(0,s1-dt);s2=math.max(0,s2-dt);ult=math.max(0,ult-dt);waveCd+=dt;
    if(waveCd>math.max(10,28-difficulty*1.2)){waveCd=0;_wave();} _player(dt);_ai(dt);_minions(dt);_towers(dt);_shots(dt);_cores(dt);
    if(!player.alive){respawn-=dt;if(respawn<=0)_respawn();}if(enemyCore.hp<=0)_finish(true);if(allyCore.hp<=0)_finish(false);
  }
  void _player(double dt){if(!player.alive)return;final dx=_axis('right','left')+stick.dx,dz=_axis('down','up')+stick.dy,l=math.sqrt(dx*dx+dz*dz);if(l>.05){player.position.x+=(dx/math.max(1,l))*speed*dt;player.position.z+=(dz/math.max(1,l))*speed*dt;player.position.x=player.position.x.clamp(-72.0,72.0).toDouble();player.position.z=player.position.z.clamp(-52.0,52.0).toDouble();player.mesh?.position.copy(player.position);}mana=math.min(maxMana,mana+18*dt);if(attackHeld||keys.contains(bind['attack']))_attack();}
  double _axis(String p,String n)=>((keys.contains(bind[p])?1:0)-(keys.contains(bind[n])?1:0)).toDouble();
  void _ai(double dt){for(final e in enemies){if(!e.alive){e.respawn-=dt;if(e.respawn<=0){e.alive=true;e.hp=e.maxHp;e.position.setValues(55,0,e.lane);e.mesh?.position.copy(e.position);e.mesh?.visible=true;}continue;}if(player.alive){final vx=player.position.x-e.position.x,vz=player.position.z-e.position.z,d=math.sqrt(vx*vx+vz*vz);if(d<13){e.attackTimer-=dt;if(e.attackTimer<=0){e.attackTimer=1;_hurt(e.damage);}}else if(d<70){e.position.x+=vx/math.max(1,d)*e.speed*dt;e.position.z+=vz/math.max(1,d)*e.speed*dt;e.mesh?.position.copy(e.position);}}}}
  void _minions(double dt){for(final m in minions){if(!m.alive)continue;final dir=m.allied?1:-1;_Unit?target;double best=7;for(final o in minions){if(!o.alive||o.allied==m.allied||(o.lane-m.lane).abs()>4)continue;final d=_dist(m.position,o.position);if(d<best){best=d;target=o;}}if(target!=null){m.attackTimer-=dt;if(m.attackTimer<=0){m.attackTimer=m.ranged?.9:.75;target.hp-=m.damage;if(target.hp<=0)_killMinion(target);}}else{m.position.x+=dir*(m.ranged?4.2:4.7)*dt;m.mesh?.position.copy(m.position);}final t=_towerFor(m);if(t!=null&&_dist(m.position,t.position)<8){t.hp-=m.damage*dt;if(t.hp<=0)_destroy(t);}if(m.allied&&_allEnemyDown()&&_dist(m.position,enemyCore.position)<10)enemyCore.hp-=m.damage*dt;if(!m.allied&&_allAllyDown()&&_dist(m.position,allyCore.position)<10)allyCore.hp-=m.damage*dt;}}
  _Tower? _towerFor(_Unit m){_Tower?best;double d0=8;for(final t in towers){if(t.destroyed||t.allied==m.allied||(t.lane-m.lane).abs()>4)continue;final d=_dist(m.position,t.position);if(d<d0){d0=d;best=t;}}return best;}
  void _towers(double dt){for(final t in towers){if(t.destroyed)continue;t.attackTimer-=dt;if(t.attackTimer>0)continue;_Unit?target;double d0=13;for(final m in minions){if(!m.alive||m.allied==t.allied||(m.lane-t.lane).abs()>5)continue;final d=_dist(t.position,m.position);if(d<d0){d0=d;target=m;}}if(target!=null){t.attackTimer=1;_shot(t.position,target.position,t.allied,100,target);}else if(!t.allied&&player.alive&&_dist(t.position,player.position)<13){t.attackTimer=1;_shot(t.position,player.position,false,130,null,player:true);}}}
  void _shots(double dt){for(final s in shots){if(!s.alive)continue;final vx=s.target.x-s.pos.x,vy=s.target.y-s.pos.y,vz=s.target.z-s.pos.z,d=math.sqrt(vx*vx+vy*vy+vz*vz);if(d<1.5){s.alive=false;s.mesh?.visible=false;if(s.unit!=null&&s.unit!.alive){s.unit!.hp-=s.damage;if(s.unit!.hp<=0)_killMinion(s.unit!);}if(s.hero!=null&&s.hero!.alive){s.hero!.hp-=s.damage;if(s.hero!.hp<=0)_killEnemy(s.hero!);}if(s.tower!=null&&!s.tower!.destroyed){s.tower!.hp-=s.damage;if(s.tower!.hp<=0)_destroy(s.tower!);}if(s.hitPlayer)_hurt(s.damage);}else{s.pos.x+=vx/math.max(1,d)*s.speed*dt;s.pos.y+=vy/math.max(1,d)*s.speed*dt;s.pos.z+=vz/math.max(1,d)*s.speed*dt;s.mesh?.position.copy(s.pos);}}shots.removeWhere((s)=>!s.alive);}
  void _cores(double dt){if(_allEnemyDown()&&player.alive&&keys.contains(bind['attack'])&&_dist(player.position,enemyCore.position)<16)enemyCore.hp-=atk*dt;}

  void _attack(){if(basicCd>0||!player.alive||ended)return;basicCd=.42;_Unit?e;double d0=16;for(final x in enemies){if(x.alive){final d=_dist(player.position,x.position);if(d<d0){d0=d;e=x;}}}if(e!=null){_shot(player.position,e.position,true,atk, null,hero:e);return;}for(final t in towers){if(!t.allied&&!t.destroyed&&_dist(player.position,t.position)<16){_shot(player.position,t.position,true,atk,null,tower:t);return;}}}
  void _shot(three.Vector3 a,three.Vector3 b,bool ally,double damage,_Unit?unit,{_Unit?hero,_Tower?tower,bool player=false}){final s=_Shot(three.Vector3(a.x,a.y+2,a.z),three.Vector3(b.x,b.y+2,b.z));s.damage=damage;s.unit=unit;s.hero=hero;s.tower=tower;s.hitPlayer=player;s.mesh=_mesh(three.SphereGeometry(.35,10,8),ally?0x74d6ff:0xff7b66);threeJs.scene.add(s.mesh!);shots.add(s);}
  void _skill1(){if(s1>0||mana<80||!player.alive)return;s1=4;mana-=80;for(final e in enemies){if(e.alive&&_dist(player.position,e.position)<13){e.hp-=260+level*25;if(e.hp<=0)_killEnemy(e);}}for(final t in towers){if(!t.allied&&!t.destroyed&&_dist(player.position,t.position)<12){t.hp-=220;if(t.hp<=0)_destroy(t);}}}
  void _skill2(){if(s2>0||mana<100||!player.alive)return;s2=7;mana-=100;hp=math.min(maxHp,hp+320);for(final e in enemies){if(e.alive&&_dist(player.position,e.position)<10){e.hp-=190+level*15;if(e.hp<=0)_killEnemy(e);}}}
  void _ult(){if(ult>0||mana<180||!player.alive)return;ult=22;mana-=180;for(final e in enemies){if(e.alive&&_dist(player.position,e.position)<20){e.hp-=700+level*50;if(e.hp<=0)_killEnemy(e);}}for(final t in towers){if(!t.allied&&!t.destroyed&&_dist(player.position,t.position)<17){t.hp-=450;if(t.hp<=0)_destroy(t);}}}
  void _hurt(double raw){if(!player.alive)return;hp-=raw*(100/(100+armor*5));if(hp<=0)_killPlayer();}
  void _killPlayer(){player.alive=false;deaths++;respawn=5+level*.8;player.mesh?.visible=false;}
  void _respawn(){player.alive=true;hp=maxHp;mana=maxMana;player.position.setValues(-55,0,0);player.mesh?.position.copy(player.position);player.mesh?.visible=true;}
  void _killEnemy(_Unit e){if(!e.alive)return;e.alive=false;e.respawn=7+level*.4;e.mesh?.visible=false;kills++;gold+=180+20*difficulty;_xp(220);}
  void _killMinion(_Unit m){if(!m.alive)return;m.alive=false;m.mesh?.visible=false;if(!m.allied){gold+=m.ranged?32:24;_xp(m.ranged?55:45);}}
  void _destroy(_Tower t){if(t.destroyed)return;t.destroyed=true;t.mesh?.visible=false;if(!t.allied){gold+=220;_xp(180);}}
  void _xp(int n){xp+=n;while(level<15&&xp>=500+level*180){xp-=500+level*180;level++;maxHp+=100;maxMana+=40;atk+=14;armor+=2;hp=maxHp;mana=maxMana;}}
  bool _allEnemyDown()=>towers.every((t)=>t.allied||t.destroyed);bool _allAllyDown()=>towers.every((t)=>!t.allied||t.destroyed);
  double _dist(three.Vector3 a,three.Vector3 b){final x=a.x-b.x,z=a.z-b.z;return math.sqrt(x*x+z*z);}
  void _finish(bool v){if(ended)return;ended=true;win=v;}
  void _buy(String id){final price=<String,int>{'blade':700,'armor':650,'boots':500,'crystal':800}[id]!;if(gold<price)return;gold-=price;if(id=='blade')atk+=45;if(id=='armor')armor+=12;if(id=='boots')speed+=1.8;if(id=='crystal'){maxMana+=150;mana=maxMana;}}
  void _reset(){setState((){ended=false;win=false;level=1;xp=0;gold=600;kills=0;deaths=0;wave=0;maxHp=1200;hp=1200;maxMana=600;mana=600;atk=110;armor=12;speed=10;enemyCore.hp=enemyCore.maxHp;allyCore.hp=allyCore.maxHp;player.alive=true;player.position.setValues(-55,0,0);player.mesh?.position.copy(player.position);player.mesh?.visible=true;for(final e in enemies){e.alive=true;e.hp=e.maxHp;e.mesh?.visible=true;}for(final t in towers){t.destroyed=false;t.hp=t.maxHp;t.mesh?.visible=true;}for(final m in minions){m.alive=false;m.mesh?.visible=false;}_wave();});}

  @override Widget build(BuildContext c)=>Scaffold(backgroundColor:Colors.black,body:KeyboardListener(focusNode:focus,autofocus:true,onKeyEvent:(e){if(e is KeyDownEvent){if(remap!=null){setState((){bind[remap!]=e.logicalKey;remap=null;});return;}keys.add(e.logicalKey);if(e.logicalKey==bind['skill1'])_skill1();if(e.logicalKey==bind['skill2'])_skill2();if(e.logicalKey==bind['ultimate'])_ult();if(e.logicalKey==bind['shop'])setState(()=>shop=!shop);}if(e is KeyUpEvent)keys.remove(e.logicalKey);},child:Stack(children:[Positioned.fill(child:threeJs.build()),_hud(),_mapHud(),_buttons(),if(shop)_shop(),if(settings)_settings(),if(ended)_result(),if(respawn>0&&!ended)_respawn()])));
  Widget _hud()=>SafeArea(child:Align(alignment:Alignment.topCenter,child:Container(margin:const EdgeInsets.all(8),padding:const EdgeInsets.symmetric(horizontal:12,vertical:6),decoration:BoxDecoration(color:Colors.black.withOpacity(.72),borderRadius:BorderRadius.circular(16)),child:Text('ARENA LEGENDS 3D • LV.$level • HP ${hp.ceil()}/${maxHp.ceil()} • MP ${mana.ceil()} • GOLD $gold • K/D $kills/$deaths • WAVE $wave',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:12)))));
  Widget _mapHud()=>Positioned(top:12,right:12,child:SafeArea(child:Container(width:150,height:94,decoration:BoxDecoration(color:Colors.black.withOpacity(.65),borderRadius:BorderRadius.circular(12)),child:CustomPaint(painter:_MapPainter()))));
  Widget _buttons()=>Positioned.fill(child:Stack(children:[Positioned(left:20,bottom:20,child:_Stick(onChanged:(v)=>setState(()=>stick=v),onEnd:()=>setState(()=>stick=Offset.zero))),Positioned(right:18,bottom:20,child:Row(children:[_Btn('ULT',60,_ult,ult),const SizedBox(width:8),_Btn('S2',60,_skill2,s2),const SizedBox(width:8),_Btn('S1',60,_skill1,s1),const SizedBox(width:8),GestureDetector(onTapDown:(_)=>setState(()=>attackHeld=true),onTapUp:(_)=>setState(()=>attackHeld=false),onTapCancel:()=>setState(()=>attackHeld=false),child:_Btn('ATK',86,_attack,basicCd))])),Positioned(left:12,top:86,child:Row(children:[_small('SHOP',()=>setState(()=>shop=!shop)),const SizedBox(width:5),_small('KEYS',()=>setState(()=>settings=!settings)),const SizedBox(width:5),_small(paused?'PLAY':'PAUSE',()=>setState(()=>paused=!paused))]))]));
  Widget _small(String s,VoidCallback f)=>FilledButton.tonal(onPressed:f,child:Text(s,style:const TextStyle(fontSize:10)));
  Widget _shop()=>Center(child=Container(width:430,padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.black.withOpacity(.95),borderRadius:BorderRadius.circular(18)),child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('ITEM SHOP',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900,color:Colors.white)),Text('Gold: $gold',style:const TextStyle(color:Colors.white)),Wrap(spacing:6,children:[_item('BLADE',700,'blade'),_item('ARMOR',650,'armor'),_item('BOOTS',500,'boots'),_item('CRYSTAL',800,'crystal')]),TextButton(onPressed:()=>setState(()=>shop=false),child:const Text('TUTUP'))])));
  Widget _item(String n,int p,String id)=>SizedBox(width:195,child:FilledButton.tonal(onPressed:gold>=p?()=>setState(()=>_buy(id)):null,child:Text('$n • $p gold')));
  Widget _settings()=>Center(child:Container(width:360,padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.black.withOpacity(.95),borderRadius:BorderRadius.circular(18)),child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('KEYBOARD SETTINGS',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:Colors.white)),...bind.entries.map((e)=>ListTile(title:Text(e.key,style:const TextStyle(color:Colors.white)),trailing:OutlinedButton(onPressed:()=>setState(()=>remap=e.key),child:Text(remap==e.key?'PRESS':e.value.keyLabel.toUpperCase())))),TextButton(onPressed:()=>setState(()=>settings=false),child:const Text('SELESAI'))])));
  Widget _result()=>Center(child:Card(color:Colors.black.withOpacity(.94),child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(win?'🏆 VICTORY':'💀 DEFEAT',style:const TextStyle(fontSize:34,color:Colors.white,fontWeight:FontWeight.w900)),const SizedBox(height:8),Text(win?'Enemy core hancur.':'Core tim kamu hancur.',style:const TextStyle(color:Colors.white)),const SizedBox(height:14),FilledButton(onPressed:_reset,child:const Text('MAIN LAGI'))]))));
  Widget _respawn()=>Center(child:Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.black.withOpacity(.75),borderRadius:BorderRadius.circular(14)),child:Text('RESPAWN ${respawn.ceil()}s',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900))));
}

class _Unit{_Unit(this.position,this.allied,this.maxHp):hp=maxHp;final three.Vector3 position;final bool allied;final double maxHp;double hp,damage=60,speed=4.5,attackTimer=0,respawn=0,lane=0;bool alive=true,ranged=false;three.Group? mesh;}
class _Tower{_Tower(this.position,this.allied,this.lane);final three.Vector3 position;final bool allied;final double lane;final double maxHp=1800;double hp=1800,attackTimer=0;bool destroyed=false;three.Group? mesh;}
class _Core{_Core(this.position,this.allied,this.maxHp):hp=maxHp;final three.Vector3 position;final bool allied;final double maxHp;double hp;three.Group? mesh;}
class _Camp{_Camp(this.position,this.maxHp):hp=maxHp;final three.Vector3 position;final double maxHp;double hp;bool alive=true;three.Group? mesh;}
class _Shot{_Shot(this.pos,this.target);final three.Vector3 pos,target;double damage=0,speed=28;bool alive=true,hitPlayer=false;_Unit? unit,hero;_Tower? tower;three.Mesh? mesh;}
class _Stick extends StatefulWidget{const _Stick({required this.onChanged,required this.onEnd});final ValueChanged<Offset> onChanged;final VoidCallback onEnd;@override State<_Stick> createState()=>_StickState();}
class _StickState extends State<_Stick>{Offset v=Offset.zero;@override Widget build(BuildContext c)=>GestureDetector(onPanUpdate:(d){final x=d.localPosition-const Offset(70,70);final l=x.distance;v=l>48?x/l*48:x;widget.onChanged(v/48);setState((){});},onPanEnd:(_){v=Offset.zero;widget.onEnd();setState((){});},child:Container(width:140,height:140,decoration:BoxDecoration(shape:BoxShape.circle,color:Colors.black.withOpacity(.35),border:Border.all(color:Colors.white24,width:2)),child:Center(child:Transform.translate(offset:v,child:Container(width:58,height:58,decoration:const BoxDecoration(shape:BoxShape.circle,color:Colors.white54))))));}
class _Btn extends StatelessWidget{const _Btn(this.text,this.size,this.onTap,this.cd);final String text;final double size,cd;final VoidCallback onTap;@override Widget build(BuildContext c)=>GestureDetector(onTap:onTap,child:Container(width:size,height:size,alignment:Alignment.center,decoration:BoxDecoration(shape:BoxShape.circle,color:cd>0?Colors.grey.shade800:Colors.deepPurple.withOpacity(.86),border:Border.all(color:Colors.white54,width:2)),child:Text(cd>0?cd.toStringAsFixed(1):text,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:10))));}
class _MapPainter extends CustomPainter{@override void paint(Canvas c,Size s){final p=Paint()..strokeWidth=5..style=PaintingStyle.stroke..color=Colors.blueAccent.withOpacity(.7);c.drawLine(Offset(s.width*.1,s.height*.9),Offset(s.width*.9,s.height*.1),p);p.color=Colors.redAccent.withOpacity(.7);c.drawLine(Offset(s.width*.1,s.height*.1),Offset(s.width*.9,s.height*.9),p);}@override bool shouldRepaint(covariant CustomPainter o)=>false;}
