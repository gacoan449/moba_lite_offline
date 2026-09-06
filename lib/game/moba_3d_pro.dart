// ignore_for_file: prefer_const_constructors, curly_braces_in_flow_control_structures, prefer_interpolation_to_compose_strings
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'systems/moba_pro_models.dart';

class Moba3DPro extends StatefulWidget {
  const Moba3DPro({super.key});
  @override State<Moba3DPro> createState()=>_Moba3DProState();
}
class _Moba3DProState extends State<Moba3DPro> {
  late three.ThreeJS view;
  bool started=false,ended=false,won=false;
  double time=0,waveTimer=0,turtleTimer=0,drakeTimer=0,respawn=0;
  double joyX=0,joyZ=0,gold=500,hp=1600,mana=700;
  int kills=0,deaths=0,level=1,wave=0;
  final Map<String,double> cds={};
  final enemies=<ProUnit>[],allies=<ProUnit>[],minions=<ProUnit>[],jungle=<ProUnit>[];
  final Inventory inventory=Inventory();
  final towers=<ProTower>[];
  late ProUnit player; late ProCore blue,red;
  three.Mesh? aimRing;

  final skills=<SkillData>[
    SkillData(id:'slash',name:'SLASH',levels:[
      SkillLevel(90,7,35,attackRatio:.75),SkillLevel(125,6.5,35,attackRatio:.75),
      SkillLevel(160,6,35,attackRatio:.8),SkillLevel(195,5.5,35,attackRatio:.85),SkillLevel(230,5,35,attackRatio:.9)]),
    SkillData(id:'step',name:'STEP',levels:[
      SkillLevel(70,12,45,attackRatio:.55),SkillLevel(100,11,45,attackRatio:.55),
      SkillLevel(130,10,45,attackRatio:.6),SkillLevel(160,9,45,attackRatio:.65),SkillLevel(190,8,45,attackRatio:.7)],
      range:20,radius:4,mode:TargetMode.directional),
    SkillData(id:'nova',name:'ULT',levels:[
      SkillLevel(180,55,80,attackRatio:1),SkillLevel(270,48,80,attackRatio:1),SkillLevel(360,41,80,attackRatio:1.1)],range:25,radius:9)
  ];

  @override void initState(){super.initState();}
  @override void dispose(){if(started)view.dispose();super.dispose();}
  void start(){
    setState(()=>started=true);
    view=three.ThreeJS(onSetupComplete:(){if(mounted)setState((){});},setup:_setup,
      settings:three.Settings(renderOptions:<String,dynamic>{'antialias':true,'powerPreference':'high-performance'}));
  }
  Future<void> _setup() async {
    view.camera=three.PerspectiveCamera(48,view.width/math.max(1.0,view.height),.1,2500);
    view.scene=three.Scene();view.scene.background=three.Color(.035,.09,.06);
    view.scene.add(three.HemisphereLight(0xdaf6ff,0x122015,1.8));
    final sun=three.DirectionalLight(0xffffff,2.5);sun.position.setValues(-80,150,60);view.scene.add(sun);
    _buildMap();_buildBases();_buildHeroes();_buildJungle();_spawnWave();view.addAnimationEvent(_tick);_camera();
  }
  three.Mesh mesh(three.BufferGeometry g,int c,{double metal=.05})=>three.Mesh(g,three.MeshStandardMaterial(<three.MaterialProperty,dynamic>{
    three.MaterialProperty.color:c,three.MaterialProperty.metalness:metal,three.MaterialProperty.roughness:.72}));
  void _buildMap(){
    view.scene.add(mesh(three.BoxGeometry(190,2,130),0x3c884b)..position.y=-1);
    for(final z in [-34.0,0.0,34.0])view.scene.add(mesh(three.BoxGeometry(176,.7,13),0x6c685f)..position.setValues(0,.15,z));
    view.scene.add(mesh(three.BoxGeometry(13,.4,130),0x238fb8)..position.y=.25);
    final r=math.Random(42);
    for(int i=0;i<120;i++){final x=r.nextDouble()*160-80,z=r.nextDouble()*112-56;if(x.abs()<10||(z.abs()<43&&x.abs()<62))continue;_tree(x,z,.65+r.nextDouble()*.9);}
  }
  void _tree(double x,double z,double s){
    view.scene.add(mesh(three.CylinderGeometry(.7,1.2,5,8),0x654329)..position.setValues(x,2.5*s,z)..scale.setValues(s,s,s));
    view.scene.add(mesh(three.IcosahedronGeometry(3.2,1),0x277a42)..position.setValues(x,6*s,z)..scale.setValues(s,s,s));
  }
  void _buildBases(){
    _base(-84,0x3d83ff);_base(84,0xe34e5b);blue=ProCore(-84,0,0x4e91ff);red=ProCore(84,0,0xff5868);
    view.scene.add(blue.mesh);view.scene.add(red.mesh);
    for(final z in [-34.0,0.0,34.0]){for(final x in [-58.0,-28.0])_tower(x,z,true);for(final x in [28.0,58.0])_tower(x,z,false);}
  }
  void _base(double x,int c){
    view.scene.add(mesh(three.CylinderGeometry(11,14,2,10),0x303840)..position.setValues(x,1,0));
    view.scene.add(mesh(three.TorusGeometry(9,.7,12,48),c,metal:.25)..rotation.x=math.pi/2..position.setValues(x,2.2,0));
  }
  void _tower(double x,double z,bool ally){final t=ProTower(x,z,ally);t.mesh=_towerMesh(ally?0x4f91ff:0xf05462);towers.add(t);view.scene.add(t.mesh!);}
  three.Group _towerMesh(int c){final g=three.Group();g.add(mesh(three.CylinderGeometry(2.8,3.7,4,8),0x343b43,metal:.35)..position.y=2);g.add(mesh(three.OctahedronGeometry(2.2,1),c,metal:.3)..position.y=5.5);return g;}
  void _buildHeroes(){
    player=ProUnit('P',0,three.Vector3(-70,0,0),CombatStats(maxHp:1600,attack:135,armor:28,magicResist:24,moveSpeed:14,range:8,maxMana:700));
    player.mesh=_hero(0x3e8cff);view.scene.add(player.mesh!);
    final zs=[-34.0,34.0,-10.0,10.0,0.0];final cs=[0xf05b68,0xd96c4e,0xc95fe0,0xe0b14d,0x72c8e8];
    for(int i=0;i<5;i++){final e=ProUnit('E$i',1,three.Vector3(70,0,zs[i]),CombatStats(maxHp:1250,attack:88,armor:22,magicResist:18,moveSpeed:6.5,range:8));e.lane=zs[i];e.mesh=_hero(cs[i]);enemies.add(e);view.scene.add(e.mesh!);}
  }
  three.Group _hero(int c){final g=three.Group();g.add(mesh(three.CapsuleGeometry(radius:1.6,length:3,capSegments:8,radialSegments:12),c,metal:.2)..position.y=3);g.add(mesh(three.BoxGeometry(4,.8,2),0x24303c,metal:.55)..position.y=4);g.add(mesh(three.SphereGeometry(1.15,16,12),0xe9b994)..position.y=5.8);g.add(mesh(three.OctahedronGeometry(.65,1),0x79e9ff,metal:.3)..position.y=7.2);return g;}
  void _buildJungle(){
    for(final p in [three.Vector3(-25,0,-17),three.Vector3(25,0,17),three.Vector3(-25,0,17),three.Vector3(25,0,-17)]){
      final m=ProUnit('C'+jungle.length.toString(),2,p,CombatStats(maxHp:700,attack:25,armor:12,magicResist:10,moveSpeed:0,range:5));m.mesh=_monster(false);jungle.add(m);view.scene.add(m.mesh!);
    }
    final t=ProUnit('TURTLE',2,three.Vector3(0,0,0),CombatStats(maxHp:4500,attack:65,armor:30,magicResist:25,moveSpeed:0,range:8));t.mesh=_monster(true);t.targetable=false;t.mesh!.visible=false;jungle.add(t);view.scene.add(t.mesh!);
    final d=ProUnit('DRAKE',2,three.Vector3(0,0,46),CombatStats(maxHp:6500,attack:90,armor:35,magicResist:30,moveSpeed:0,range:10));d.mesh=_monster(true);d.targetable=false;d.mesh!.visible=false;jungle.add(d);view.scene.add(d.mesh!);
  }
  three.Group _monster(bool boss){final g=three.Group();final c=boss?0x8f45d9:0xc47b31;g.add(mesh(three.SphereGeometry(boss?4.8:2.8,18,12),c,metal:.15)..position.y=boss?4:2.5);g.add(mesh(three.OctahedronGeometry(boss?1.5:.7,1),boss?0x56eaff:0xffbd49)..position.y=boss?8:5);return g;}
  three.Group _minion(bool ally,bool ranged){final g=three.Group();final c=ally?0x3f8dff:0xe95762;g.add(mesh(three.CylinderGeometry(1.1,1.4,2.5,8),c)..position.y=1.5);g.add(mesh(three.SphereGeometry(.8,12,8),0xe8bd9e)..position.y=3.2);if(ranged)g.add(mesh(three.TorusGeometry(1.2,.18,6,18),0xffd45a)..rotation.x=math.pi/2..position.y=1);return g;}
  void _spawnWave(){if(ended)return;wave++;for(final z in [-34.0,0.0,34.0])for(int i=0;i<3;i++){_addMinion(0,z,-78-i*4,i==2);_addMinion(1,z,78+i*4,i==2);}}
  void _addMinion(int team,double z,double x,bool ranged){final m=ProUnit('M'+minions.length.toString(),team,three.Vector3(x,0,z),CombatStats(maxHp:ranged?260:340,attack:ranged?32:38,armor:8,magicResist:8,moveSpeed:team==0?6.2:5.9,range:ranged?15:4));m.lane=z;m.mesh=_minion(team==0,ranged);minions.add(m);view.scene.add(m.mesh!);}
  void _tick(double dt){
    if(ended)return;time+=dt;waveTimer+=dt;turtleTimer+=dt;drakeTimer+=dt;
    if(waveTimer>=24){waveTimer=0;_spawnWave();}
    if(turtleTimer>=150&&jungle.any((x)=>x.id=='TURTLE'&&!x.alive)){_respawn('TURTLE');turtleTimer=0;}
    if(drakeTimer>=180&&jungle.any((x)=>x.id=='DRAKE'&&!x.alive)){_respawn('DRAKE');drakeTimer=0;}
    _playerUpdate(dt);_enemyUpdate(dt);_allyUpdate(dt);_minionUpdate(dt);_jungleUpdate(dt);_towerUpdate(dt);_cleanup();
    if(!red.alive)_finish(true);if(!blue.alive)_finish(false);_camera();
  }
  void _playerUpdate(double dt){
    if(!player.alive){respawn-=dt;if(respawn<=0)_respawnPlayer();return;}
    if(!player.status.disabled){final n=math.sqrt(joyX*joyX+joyZ*joyZ);if(n>.05){player.position.x+=(joyX/n)*player.stats.moveSpeed*dt;player.position.z+=(joyZ/n)*player.stats.moveSpeed*dt;player.position.x=player.position.x.clamp(-82.0,82.0);player.position.z=player.position.z.clamp(-56.0,56.0);player.mesh?.position.setValues(player.position.x,0,player.position.z);}}
    player.status.tick(dt);player.stats.mana=math.min(player.stats.maxMana,player.stats.mana+18*dt);
    mana=player.stats.mana;hp=player.stats.hp;for(final k in cds.keys.toList())cds[k]=math.max(0,(cds[k]??0)-dt);
  }
  void _allyUpdate(double dt){
    for(final a in allies){
      if(!a.alive)continue;
      ProUnit? target;double best=70;
      for(final e in enemies)if(e.alive){final d=_dist(a.position,e.position);if(d<best){best=d;target=e;}}
      if(target!=null){if(best<12){a.attackTimer-=dt;if(a.attackTimer<=0){a.attackTimer=1;aTargetDamage(target,a.stats.attack);}}else _move(a,target.position,dt);}
      else{final laneTarget=three.Vector3(70,0,a.lane);_move(a,laneTarget,dt);}
    }
  }
  void aTargetDamage(ProUnit target,double damage){
    target.takeDamage(damage,MobaDamageType.physical);
    if(!target.alive){kills++;gold+=180;level=math.min(15,1+kills~/2);}
  }
  void _enemyUpdate(double dt){
    for(final e in enemies){if(!e.alive){e.respawnTimer-=dt;if(e.respawnTimer<=0){e.stats.hp=e.stats.maxHp;e.targetable=true;e.position.setValues(70,0,e.lane);e.mesh?.visible=true;}continue;}if(!player.alive)continue;final d=_dist(e.position,player.position);if(d<12){e.attackTimer-=dt;if(e.attackTimer<=0){e.attackTimer=1;_damagePlayer(e.stats.attack);}}else if(d<65)_move(e,player.position,dt);}
  }
  void _minionUpdate(double dt){
    for(final m in minions)if(m.alive){ProUnit? target;double best=m.stats.range+2;for(final o in minions)if(o.alive&&o.team!=m.team&&(o.position.z-m.position.z).abs()<7){final d=_dist(m.position,o.position);if(d<best){best=d;target=o;}}if(target!=null){m.attackTimer-=dt;if(m.attackTimer<=0){m.attackTimer=.8;target.takeDamage(m.stats.attack,MobaDamageType.physical);}}else{
        final tower=towers.where((t)=>t.alive&&t.ally!= (m.team==0)&&(t.position.z-m.position.z).abs()<7).toList()..sort((a,b)=>_dist(m.position,a.position).compareTo(_dist(m.position,b.position)));
        if(tower.isNotEmpty&&_dist(m.position,tower.first.position)<14){m.attackTimer-=dt;if(m.attackTimer<=0){m.attackTimer=.9;tower.first.hp=math.max(0,tower.first.hp-m.stats.attack*.65);if(tower.first.hp<=0)tower.first.mesh?.visible=false;}}
        else{m.position.x+=(m.team==0?1:-1)*m.stats.moveSpeed*dt;m.mesh?.position.setValues(m.position.x,0,m.position.z);}
      }}}
  void _jungleUpdate(double dt){
    for(final j in jungle){
      if(j.id=='TURTLE'&&!j.targetable&&time>=180){j.targetable=true;j.mesh?.visible=true;}
      if(j.id=='DRAKE'&&!j.targetable&&time>=480){j.targetable=true;j.mesh?.visible=true;}
      if(!j.alive)continue;final d=_dist(j.position,player.position);if(d<j.stats.range+6){j.attackTimer-=dt;if(j.attackTimer<=0){j.attackTimer=1.1;_damagePlayer(j.stats.attack);}}}
  }
  void _towerUpdate(double dt){
    for(final t in towers)if(t.alive){t.attackTimer-=dt;if(t.attackTimer>0)continue;final team=t.ally?0:1;final candidates=<ProUnit>[...minions.where((m)=>m.alive&&m.team!=team),...enemies.where((e)=>e.alive&&e.team!=team)];if(!t.ally&&player.alive)candidates.add(player);candidates.sort((a,b)=>_dist(a.position,t.position).compareTo(_dist(b.position,t.position)));for(final c in candidates)if(_dist(c.position,t.position)<22){c.takeDamage(70,MobaDamageType.physical);t.attackTimer=1;break;}}
  }
  void _move(ProUnit u,three.Vector3 p,double dt){final dx=p.x-u.position.x,dz=p.z-u.position.z,d=math.sqrt(dx*dx+dz*dz);if(d>.01){u.position.x+=dx/d*u.stats.moveSpeed*dt;u.position.z+=dz/d*u.stats.moveSpeed*dt;u.mesh?.position.setValues(u.position.x,0,u.position.z);}}
  void _damagePlayer(double raw){if(!player.alive)return;player.takeDamage(raw,MobaDamageType.physical);if(!player.alive){deaths++;respawn=6;player.targetable=false;player.mesh?.visible=false;}}
  void _respawnPlayer(){player.stats.hp=player.stats.maxHp;player.stats.mana=player.stats.maxMana;player.targetable=true;player.position.setValues(-70,0,0);player.mesh?.position.setValues(-70,0,0);player.mesh?.visible=true;}
  bool _allEnemyTowersDown()=>towers.where((t)=>!t.ally).every((t)=>!t.alive);
  void _respawn(String id){final j=jungle.firstWhere((x)=>x.id==id);j.stats.hp=j.stats.maxHp;j.targetable=true;j.mesh?.visible=true;}
  void _cleanup(){for(final m in minions)if(!m.alive)m.mesh?.visible=false;for(final e in enemies)if(!e.alive)e.mesh?.visible=false;for(final t in towers)if(!t.alive)t.mesh?.visible=false;}
  double _dist(three.Vector3 a,three.Vector3 b){final x=a.x-b.x,z=a.z-b.z;return math.sqrt(x*x+z*z);}
  void basicAttack(){if(!player.alive)return;ProUnit? target;double best=player.stats.range+2;for(final e in enemies)if(e.alive){final d=_dist(player.position,e.position);if(d<best){best=d;target=e;}}for(final m in minions)if(m.alive&&m.team==1){final d=_dist(player.position,m.position);if(d<best){best=d;target=m;}}
    for(final j in jungle)if(j.alive&&j.targetable){final d=_dist(player.position,j.position);if(d<best){best=d;target=j;}}
    if(target!=null){target.takeDamage(player.stats.attack,MobaDamageType.physical);if(!target.alive){if(target.id.startsWith('E')){kills++;gold+=180;level=math.min(15,1+kills~/2);}else if(target.id.startsWith('M'))gold+=45;else{gold+=target.id=='TURTLE'?300:target.id=='DRAKE'?500:80;player.addShield(target.id=='TURTLE'?450:0);}}}
    else{
      for(final t in towers.where((t)=>!t.ally&&t.alive)){if(_dist(player.position,t.position)<player.stats.range+4){t.hp=math.max(0,t.hp-player.stats.attack*.75);if(t.hp<=0)t.mesh?.visible=false;return;}}
      if(_allEnemyTowersDown()&&_dist(player.position,red.mesh.position)<18){red.hp=math.max(0,red.hp-player.stats.attack);}
    }}
  void castSkill(int i){if(!player.alive||i<0||i>=skills.length)return;final s=skills[i],l=s.at(level);if((cds[s.id]??0)>0||player.stats.mana<l.cost)return;player.stats.mana-=l.cost;cds[s.id]=l.cooldown;var center=player.position.clone();if(i==1){center.x+=joyX*s.range;center.z+=joyZ*s.range;player.position.setValues(center.x,0,center.z);player.mesh?.position.setValues(center.x,0,center.z);}if(i!=1)center=_nearestPoint();for(final e in enemies)if(e.alive&&_dist(center,e.position)<=s.radius){e.takeDamage(l.damage+player.stats.attack*l.attackRatio,s.damageType);if(i==2)e.status.stun=.8;if(!e.alive){kills++;gold+=180;}}for(final m in minions)if(m.alive&&m.team==1&&_dist(center,m.position)<=s.radius){m.takeDamage(l.damage,s.damageType);if(!m.alive)gold+=45;}_showAim(center,s.radius);}
  three.Vector3 _nearestPoint(){if(enemies.isEmpty)return player.position.clone();enemies.sort((a,b)=>_dist(a.position,player.position).compareTo(_dist(b.position,player.position)));return enemies.first.position.clone();}
  void _showAim(three.Vector3 p,double r){if(aimRing==null){aimRing=mesh(three.TorusGeometry(1,.08,8,32),0x6ee7ff,metal:.2);view.scene.add(aimRing!);}aimRing!.scale.setValues(r,r,r);aimRing!.position.setValues(p.x,.35,p.z);}
  void _camera(){if(!started)return;view.camera.position.setValues(player.position.x-42,58,player.position.z+55);view.camera.lookAt(player.position);}
  void _finish(bool v){if(ended)return;ended=true;won=v;}

  @override Widget build(BuildContext context){
    if(!started)return Scaffold(body:Center(child:FilledButton.icon(onPressed:start,icon:const Icon(Icons.sports_esports),label:const Text('ENTER ARENA LEGENDS'))));
    return Scaffold(body:Stack(children:[Positioned.fill(child:view.build()),Positioned(top:10,left:10,right:10,child:_hud()),Positioned(left:18,bottom:18,child:_joystick()),Positioned(right:18,bottom:18,child:_buttons()),if(ended)Positioned.fill(child:_result())]));
  }
  Widget _hud()=>Row(children:[_pill('TIME '+time.toInt().toString()),const SizedBox(width:6),_pill('K/D '+kills.toString()+'/'+deaths.toString()),const SizedBox(width:6),_pill('LV '+level.toString()+' GOLD '+gold.toInt().toString()),const SizedBox(width:6),GestureDetector(onTap:_buyItem,child:_pill('SHOP '+inventory.items.length.toString()+'/6')),const Spacer(),_pill('WAVE '+wave.toString())]);
  void _buyItem(){if(inventory.buy(shopItems[inventory.items.length%shopItems.length],player))setState((){});}
  Widget _pill(String s)=>Material(color:Colors.black.withValues(alpha:.72),borderRadius:BorderRadius.circular(12),child:Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),child:Text(s,style:const TextStyle(fontWeight:FontWeight.w800))));
  Widget _joystick()=>GestureDetector(onPanUpdate:(d){joyX=(d.localPosition.dx-70)/60;joyZ=(d.localPosition.dy-70)/60;final n=math.sqrt(joyX*joyX+joyZ*joyZ);if(n>1){joyX/=n;joyZ/=n;}},onPanEnd:(_){joyX=0;joyZ=0;},child:Container(width:140,height:140,decoration:BoxDecoration(shape:BoxShape.circle,color:Colors.black54,border:Border.all(color:Colors.white24,width:2)),child:Center(child:Container(width:58,height:58,decoration:const BoxDecoration(shape:BoxShape.circle,color:Colors.white24),child:const Icon(Icons.gamepad,color:Colors.white70)))));
  Widget _buttons()=>Row(mainAxisSize:MainAxisSize.min,children:[_button('ATK',-1),const SizedBox(width:8),_button('S1',0),const SizedBox(width:8),_button('S2',1),const SizedBox(width:8),_button('ULT',2)]);
  Widget _button(String label,int i){final cd=i<0?0:(cds[skills[i].id]??0);return GestureDetector(onTap:()=>i<0?basicAttack():castSkill(i),child:Container(width:i==2?76:64,height:i==2?76:64,decoration:BoxDecoration(shape:BoxShape.circle,color:i==2?Colors.deepPurple:Colors.blue,border:Border.all(color:Colors.white70,width:2)),child:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(label,style:const TextStyle(fontWeight:FontWeight.w900)),if(i>=0)Text(cd>0?cd.toStringAsFixed(1):'READY',style:const TextStyle(fontSize:10))]))));}
  Widget _result()=>ColoredBox(color:Colors.black87,child:Center(child:Text(won?'VICTORY':'DEFEAT',style:TextStyle(fontSize:60,fontWeight:FontWeight.w900,color:won?Colors.cyanAccent:Colors.redAccent))));
}
class ProUnit extends MobaUnit {
  ProUnit(String id,int team,three.Vector3 p,CombatStats s):super(id:id,team:team,position:p,stats:s);
  three.Group? mesh;double attackTimer=0,lane=0;
}
class ProTower {
  ProTower(double x,double z,this.ally):position=three.Vector3(x,0,z);
  final bool ally;final three.Vector3 position;double hp=2200,attackTimer=0;three.Group? mesh;bool get alive=>hp>0;
}
class ProCore {
  ProCore(double x,double z,int c):mesh=_make(c);
  final three.Group mesh;double hp=6000;bool get alive=>hp>0;
  static three.Group _make(int c){final g=three.Group();g.add(three.Mesh(three.OctahedronGeometry(6,1),three.MeshStandardMaterial(<three.MaterialProperty,dynamic>{three.MaterialProperty.color:c,three.MaterialProperty.metalness:.25,three.MaterialProperty.roughness:.5})));return g;}
}