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
  double time=0,waveTimer=0,turtleTimer=0,drakeTimer=0,respawn=0,uiRefreshTimer=0;
  double joyX=0,joyZ=0,gold=500,hp=1600,mana=700;
  int kills=0,deaths=0,level=1,wave=0;
  final Map<String,double> cds={};
  final enemies=<ProUnit>[],allies=<ProUnit>[],minions=<ProUnit>[],jungle=<ProUnit>[];
  final Inventory inventory=Inventory();
  final towers=<ProTower>[];
  late ProUnit player; late ProCore blue,red;
  three.Mesh? aimRing;
  double aimTimer=0;
  final Map<String,List<three.Group>> _rigParts={};
  final List<_BattleEffect> _effects=[];
  final List<_Projectile> _projectiles=[];

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
    // Raised stone bridges and lane markings make the battlefield easier to read.
    for(final x in [-42.0,0.0,42.0]){
      view.scene.add(mesh(three.BoxGeometry(18,.8,17),0xaaa28d,metal:.08)..position.setValues(x,.45,0));
      for(final z in [-34.0,0.0,34.0]){view.scene.add(mesh(three.BoxGeometry(4,.12,1.1),0xc9c2ac)..position.setValues(x,.62,z));}
    }
    final r=math.Random(42);
    for(int i=0;i<150;i++){final x=r.nextDouble()*160-80,z=r.nextDouble()*112-56;if(x.abs()<12||(z.abs()<43&&x.abs()<62))continue;_tree(x,z,.65+r.nextDouble()*.9);}
    for(final p in [three.Vector3(-15,0,-24),three.Vector3(15,0,24),three.Vector3(-15,0,24),three.Vector3(15,0,-24)]){
      view.scene.add(mesh(three.OctahedronGeometry(2.1,1),0x36d9e8,metal:.35)..position.setValues(p.x,2,p.z));
      view.scene.add(mesh(three.TorusGeometry(2.8,.12,8,28),0x50d9ed,metal:.25)..rotation.x=math.pi/2..position.setValues(p.x,.25,p.z));
    }
  }
  void _tree(double x,double z,double s){
    view.scene.add(mesh(three.CylinderGeometry(.7,1.2,5,8),0x654329)..position.setValues(x,2.5*s,z)..scale.setValues(s,s,s));
    view.scene.add(mesh(three.IcosahedronGeometry(3.2,1),0x277a42)..position.setValues(x,6*s,z)..scale.setValues(s,s,s));
    view.scene.add(mesh(three.IcosahedronGeometry(2.1,1),0x398c4c)..position.setValues(x-1.1*s,7.1*s,z+.35*s)..scale.setValues(s*.8,s*.85,s*.8));
  }
  void _buildBases(){
    _base(-84,0x3d83ff);_base(84,0xe34e5b);blue=ProCore(-84,0,0x4e91ff);red=ProCore(84,0,0xff5868);
    view.scene.add(blue.mesh);view.scene.add(red.mesh);
    for(final z in [-34.0,0.0,34.0]){for(final x in [-58.0,-28.0])_tower(x,z,true);for(final x in [28.0,58.0])_tower(x,z,false);}
  }
  void _base(double x,int c){
    view.scene.add(mesh(three.CylinderGeometry(11,14,2,10),0x303840)..position.setValues(x,1,0));
    view.scene.add(mesh(three.CylinderGeometry(8.2,9.5,.8,12),c,metal:.2)..position.setValues(x,2.05,0));
    view.scene.add(mesh(three.TorusGeometry(9,.7,12,48),c,metal:.25)..rotation.x=math.pi/2..position.setValues(x,2.5,0));
    view.scene.add(mesh(three.TorusGeometry(5,.16,8,36),0x8fefff,metal:.3)..rotation.x=math.pi/2..position.setValues(x,2.55,0));
  }
  void _tower(double x,double z,bool ally){final t=ProTower(x,z,ally);t.mesh=_towerMesh(ally?0x4f91ff:0xf05462);towers.add(t);view.scene.add(t.mesh!);}
  three.Group _towerMesh(int c){final g=three.Group();g.add(mesh(three.CylinderGeometry(2.8,3.7,4,8),0x343b43,metal:.35)..position.y=2);g.add(mesh(three.CylinderGeometry(2.1,2.5,1,8),c,metal:.3)..position.y=4.3);g.add(mesh(three.OctahedronGeometry(2.2,1),c,metal:.3)..position.y=5.5);g.add(mesh(three.TorusGeometry(2.4,.18,8,24),0xffe8a3,metal:.25)..rotation.x=math.pi/2..position.y=4.8);g.add(mesh(three.ConeGeometry(1.15,2.4,8),0xeafaff,metal:.4)..position.y=7.6);return g;}
  void _buildHeroes(){
    player=ProUnit('P',0,three.Vector3(-70,0,0),CombatStats(maxHp:1600,attack:135,armor:28,magicResist:24,moveSpeed:14,range:8,maxMana:700));
    player.mesh=_hero(0x3e8cff,allied:true,rigId:player.id);view.scene.add(player.mesh!);
    final zs=[-34.0,34.0,-10.0,10.0,0.0];final cs=[0xf05b68,0xd96c4e,0xc95fe0,0xe0b14d,0x72c8e8];
    for(int i=0;i<5;i++){final e=ProUnit('E$i',1,three.Vector3(70,0,zs[i]),CombatStats(maxHp:1250,attack:88,armor:22,magicResist:18,moveSpeed:6.5,range:8));e.lane=zs[i];e.mesh=_hero(cs[i],rigId:e.id);enemies.add(e);view.scene.add(e.mesh!);}
  }
  three.Group _hero(int c,{bool allied=false,String rigId=''}){
    final g=three.Group();
    // Lightweight fake contact shadow keeps the hero grounded on mobile GPUs.
    g.add(mesh(three.CylinderGeometry(2.35,2.35,.05,20),0x17251d)..position.y=.07..scale.setValues(1,.58,1));
    g.add(mesh(three.CapsuleGeometry(radius:1.05,length:2.4,capSegments:6,radialSegments:10),0x263247,metal:.32)..position.y=1.8);
    g.add(mesh(three.CapsuleGeometry(radius:1.35,length:2.1,capSegments:8,radialSegments:12),c,metal:.38)..position.setValues(0,3.55,0));
    g.add(mesh(three.BoxGeometry(2.9,.65,1.9),0xd8e3ed,metal:.62)..position.setValues(0,4.05,0));
    g.add(mesh(three.BoxGeometry(1.65,.5,1.98),c,metal:.42)..position.setValues(0,4.12,-.06));
    for(final side in [-1.0,1.0]){
      final shoulder=three.Group()..position.setValues(side*1.45,4.15,0);
      shoulder.add(mesh(three.SphereGeometry(.82,12,10),c,metal:.35));
      shoulder.add(mesh(three.CapsuleGeometry(radius:.38,length:1.6,capSegments:5,radialSegments:8),0x9aa9bc,metal:.5)..position.y=-1.45);
      shoulder.add(mesh(three.BoxGeometry(.8,.24,.65),0xffd36b,metal:.45)..position.setValues(0,-2.25,.2));
      g.add(shoulder);
      final leg=three.Group()..position.setValues(side*.72,1.15,0);
      leg.add(mesh(three.CapsuleGeometry(radius:.38,length:1.6,capSegments:5,radialSegments:8),0x263247,metal:.35)..position.y=-.25);
      leg.add(mesh(three.BoxGeometry(.9,.35,1.25),0x64768c,metal:.4)..position.setValues(0,-1.1,.35));
      g.add(leg);
    }
    g.add(mesh(three.SphereGeometry(.9,16,12),0xe9b994)..position.setValues(0,5.25,0));
    g.add(mesh(three.ConeGeometry(1.0,1.65,8),0xdce8f5,metal:.45)..position.setValues(0,6.25,0));
    g.add(mesh(three.BoxGeometry(.26,.22,1.15),0x192638,metal:.3)..position.setValues(0,5.32,.78));
    g.add(mesh(three.SphereGeometry(.18,8,8),0x79e9ff,metal:.45)..position.setValues(-.32,5.35,.83));
    g.add(mesh(three.ConeGeometry(1.35,2.7,5),allied?0x173e8a:0x742c3a)..position.setValues(0,2.65,-1.05)..rotation.x=math.pi);
    final sword=three.Group()..position.setValues(2.05,3.3,.15)..rotation.z=-.28;
    sword.add(mesh(three.CylinderGeometry(.12,.18,2.7,8),0xd9e4ef,metal:.65));
    sword.add(mesh(three.ConeGeometry(.16,.5,8),0xeafaff,metal:.5)..position.y=1.58);
    g.add(sword);
    g.add(mesh(three.BoxGeometry(.75,.18,.24),0xffd36b,metal:.45)..position.setValues(2.05,2.35,.15));
    g.add(mesh(three.OctahedronGeometry(.62,1),allied?0x8ef6ff:0xffb8bd,metal:.5)..position.setValues(0,7.35,0));
    g.add(mesh(three.TorusGeometry(2.05,.09,8,32),allied?0x3fcbff:0xff6676,metal:.25)..rotation.x=math.pi/2..position.setValues(0,.18,0));
    _rigParts[rigId]=g.children.whereType<three.Group>().where((part)=>part.children.length>=2).take(4).toList();
    return g;
  }
  void _buildJungle(){
    for(final p in [three.Vector3(-25,0,-17),three.Vector3(25,0,17),three.Vector3(-25,0,17),three.Vector3(25,0,-17)]){
      final m=ProUnit('C'+jungle.length.toString(),2,p,CombatStats(maxHp:700,attack:25,armor:12,magicResist:10,moveSpeed:0,range:5));m.mesh=_monster(false);jungle.add(m);view.scene.add(m.mesh!);
    }
    final t=ProUnit('TURTLE',2,three.Vector3(0,0,0),CombatStats(maxHp:4500,attack:65,armor:30,magicResist:25,moveSpeed:0,range:8));t.mesh=_monster(true);t.targetable=false;t.mesh!.visible=false;jungle.add(t);view.scene.add(t.mesh!);
    final d=ProUnit('DRAKE',2,three.Vector3(0,0,46),CombatStats(maxHp:6500,attack:90,armor:35,magicResist:30,moveSpeed:0,range:10));d.mesh=_monster(true);d.targetable=false;d.mesh!.visible=false;jungle.add(d);view.scene.add(d.mesh!);
  }
  three.Group _monster(bool boss){final g=three.Group();final c=boss?0x8f45d9:0xc47b31;g.add(mesh(three.SphereGeometry(boss?4.8:2.8,18,12),c,metal:.15)..position.y=boss?4:2.5);g.add(mesh(three.OctahedronGeometry(boss?1.5:.7,1),boss?0x56eaff:0xffbd49)..position.y=boss?8:5);return g;}
  three.Group _minion(bool ally,bool ranged){final g=three.Group();final c=ally?0x3f8dff:0xe95762;g.add(mesh(three.CylinderGeometry(1.1,1.4,2.5,8),c,metal:.18)..position.y=1.5);g.add(mesh(three.SphereGeometry(.8,12,8),0xe8bd9e)..position.y=3.2);g.add(mesh(three.ConeGeometry(.85,1.1,6),0xdbe7ef,metal:.35)..position.y=4);g.add(mesh(three.BoxGeometry(1.6,.28,1.2),0x283446,metal:.4)..position.setValues(0,2.4,.6));if(ranged){g.add(mesh(three.TorusGeometry(1.2,.18,6,18),0xffd45a)..rotation.x=math.pi/2..position.y=1);g.add(mesh(three.CylinderGeometry(.12,.12,1.8,6),0xffd45a,metal:.25)..position.setValues(.95,2.1,.3)..rotation.z=-.4);}return g;}
  void _spawnWave(){if(ended)return;wave++;for(final z in [-34.0,0.0,34.0])for(int i=0;i<3;i++){_addMinion(0,z,-78-i*4,i==2);_addMinion(1,z,78+i*4,i==2);}}
  void _addMinion(int team,double z,double x,bool ranged){final m=ProUnit('M'+minions.length.toString(),team,three.Vector3(x,0,z),CombatStats(maxHp:ranged?260:340,attack:ranged?32:38,armor:8,magicResist:8,moveSpeed:team==0?6.2:5.9,range:ranged?15:4));m.lane=z;m.mesh=_minion(team==0,ranged);minions.add(m);view.scene.add(m.mesh!);}
  void _tick(double dt){
    if(ended)return;time+=dt;waveTimer+=dt;turtleTimer+=dt;drakeTimer+=dt;
    uiRefreshTimer+=dt;
    _updateCombatEffects(dt);
    if(aimTimer>0){aimTimer=math.max(0,aimTimer-dt);if(aimRing!=null){aimRing!.visible=aimTimer>0;final s=aimRing!.scale.x+dt*1.8;aimRing!.scale.setValues(s,s,s);}}
    _animateHeroes();
    if(player.mesh!=null&&joyX.abs()+joyZ.abs()>.08){player.mesh!.rotation.y=math.atan2(joyX,joyZ);}
    for(int i=0;i<enemies.length;i++){final e=enemies[i];if(e.mesh!=null&&e.alive){e.mesh!.position.y=.08*math.sin(time*3+i);final dx=player.position.x-e.position.x,dz=player.position.z-e.position.z;if(dx.abs()+dz.abs()>.2)e.mesh!.rotation.y=math.atan2(dx,dz);}}
    if(uiRefreshTimer>=.25){uiRefreshTimer=0;if(mounted)setState((){});}
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
  void _animateHeroes(){
    for(final entry in _rigParts.entries){final id=entry.key;final unit=id=='P'?player:enemies.cast<ProUnit?>().firstWhere((u)=>u?.id==id,orElse:()=>null);if(unit==null||unit.mesh==null)continue;final moving=id=='P'?(joyX.abs()+joyZ.abs()>.08):unit.alive;final phase=time*(moving?9:2)+(id.hashCode%7);final parts=entry.value;if(parts.length>=4){parts[0].rotation.x=math.sin(phase)*.48;parts[1].rotation.x=-math.sin(phase)*.48;parts[2].rotation.x=-math.sin(phase)*.55;parts[3].rotation.x=math.sin(phase)*.55;}if(!unit.alive){unit.mesh!.rotation.z=math.min(math.pi/2,unit.mesh!.rotation.z+0.035);}}
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
    if(!target.alive){kills++;_earnGold(180);level=math.min(15,1+kills~/2);}
  }
  void _enemyUpdate(double dt){
    for(final e in enemies){if(!e.alive){e.respawnTimer-=dt;if(e.respawnTimer<=0){e.stats.hp=e.stats.maxHp;e.targetable=true;e.position.setValues(70,0,e.lane);e.mesh?.rotation.z=0;e.mesh?.rotation.x=0;e.mesh?.position.setValues(70,0,e.lane);e.mesh?.visible=true;}continue;}
      ProUnit? target;double best=player.alive? _dist(e.position,player.position):double.infinity;
      if(player.alive&&best<20)target=player;
      for(final m in minions.where((m)=>m.alive&&m.team==0)){final d=_dist(e.position,m.position);if(d<best&&d<24){best=d;target=m;}}
      if(target!=null){if(best<e.stats.range+3){e.attackTimer-=dt;if(e.attackTimer<=0){e.attackTimer=1.15;_spawnProjectile(e.position,target.position,0xffff7a66,7.5,e.stats.attack,target);}}else _move(e,target.position,dt);}
      else{final alliedTowers=towers.where((t)=>t.ally&&t.alive).toList()..sort((a,b)=>_dist(e.position,a.position).compareTo(_dist(e.position,b.position)));if(alliedTowers.isNotEmpty&&_dist(e.position,alliedTowers.first.position)<18){e.attackTimer-=dt;if(e.attackTimer<=0){e.attackTimer=1.4;alliedTowers.first.hp=math.max(0,alliedTowers.first.hp-e.stats.attack*.65);if(!alliedTowers.first.alive)alliedTowers.first.mesh?.visible=false;}}else if(alliedTowers.isEmpty){final d=_dist(e.position,blue.mesh.position);if(d<17){e.attackTimer-=dt;if(e.attackTimer<=0){e.attackTimer=1.5;blue.hp=math.max(0,blue.hp-e.stats.attack*.8);}}else _move(e,three.Vector3(-84,0,e.lane),dt);}else _move(e,alliedTowers.first.position,dt);}
    }
  }
  void _minionUpdate(double dt){
    for(final m in minions)if(m.alive){ProUnit? target;double best=m.stats.range+2;for(final o in minions)if(o.alive&&o.team!=m.team&&(o.position.z-m.position.z).abs()<7){final d=_dist(m.position,o.position);if(d<best){best=d;target=o;}}if(target!=null){m.attackTimer-=dt;if(m.attackTimer<=0){m.attackTimer=.8;target.takeDamage(m.stats.attack,MobaDamageType.physical);}}else{
        final tower=towers.where((t)=>t.alive&&t.ally!= (m.team==0)&&(t.position.z-m.position.z).abs()<7).toList()..sort((a,b)=>_dist(m.position,a.position).compareTo(_dist(m.position,b.position)));
        if(tower.isNotEmpty&&_dist(m.position,tower.first.position)<14){m.attackTimer-=dt;if(m.attackTimer<=0){m.attackTimer=.9;tower.first.hp=math.max(0,tower.first.hp-m.stats.attack*.65);if(tower.first.hp<=0)tower.first.mesh?.visible=false;}}
        else{final enemyTowers=towers.where((t)=>t.alive&&t.ally!=(m.team==0)&&(t.position.z-m.position.z).abs()<7).toList()..sort((a,b)=>_dist(m.position,a.position).compareTo(_dist(m.position,b.position)));if(enemyTowers.isEmpty){final core=m.team==0?red:blue;if(_dist(m.position,core.mesh.position)<15){m.attackTimer-=dt;if(m.attackTimer<=0){m.attackTimer=1;m.team==0?red.hp=math.max(0,red.hp-m.stats.attack):blue.hp=math.max(0,blue.hp-m.stats.attack);}}else{m.position.x+=(m.team==0?1:-1)*m.stats.moveSpeed*dt;m.mesh?.position.setValues(m.position.x,0,m.position.z);}}else{m.position.x+=(m.team==0?1:-1)*m.stats.moveSpeed*dt;m.mesh?.position.setValues(m.position.x,0,m.position.z);}}
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
  void _move(ProUnit u,three.Vector3 p,double dt){final dx=p.x-u.position.x,dz=p.z-u.position.z,d=math.sqrt(dx*dx+dz*dz);if(d>.01){final step=math.min(d, u.stats.moveSpeed*dt);u.position.x+=dx/d*step;u.position.z+=dz/d*step;u.mesh?.position.setValues(u.position.x,0,u.position.z);if(u.mesh!=null)u.mesh!.rotation.y=math.atan2(dx,dz);}}
  void _damagePlayer(double raw){if(!player.alive)return;player.takeDamage(raw,MobaDamageType.physical);_spawnBurst(player.position,0xffff4f70,2.5);if(!player.alive){deaths++;respawn=6;player.targetable=false;player.mesh?.rotation.z=math.pi/2;player.mesh?.visible=true;}}
  void _respawnPlayer(){player.stats.hp=player.stats.maxHp;player.stats.mana=player.stats.maxMana;player.targetable=true;player.position.setValues(-70,0,0);player.mesh?.position.setValues(-70,0,0);player.mesh?.rotation.z=0;player.mesh?.rotation.x=0;player.mesh?.visible=true;}
  bool _allEnemyTowersDown()=>towers.where((t)=>!t.ally).every((t)=>!t.alive);
  void _respawn(String id){final j=jungle.firstWhere((x)=>x.id==id);j.stats.hp=j.stats.maxHp;j.targetable=true;j.mesh?.visible=true;}
  void _cleanup(){for(final m in minions)if(!m.alive)m.mesh?.visible=false;for(final e in enemies)if(!e.alive)e.mesh?.visible=false;for(final t in towers)if(!t.alive)t.mesh?.visible=false;}
  double _dist(three.Vector3 a,three.Vector3 b){final x=a.x-b.x,z=a.z-b.z;return math.sqrt(x*x+z*z);}
  void basicAttack(){if(!player.alive)return;ProUnit? target;double best=player.stats.range+2;for(final e in enemies)if(e.alive){final d=_dist(player.position,e.position);if(d<best){best=d;target=e;}}for(final m in minions)if(m.alive&&m.team==1){final d=_dist(player.position,m.position);if(d<best){best=d;target=m;}}
    for(final j in jungle)if(j.alive&&j.targetable){final d=_dist(player.position,j.position);if(d<best){best=d;target=j;}}
    if(target!=null){_swingHero(player);_spawnProjectile(player.position,target.position,0xffa9f7ff,12,player.stats.attack,target);}
    else{
      for(final t in towers.where((t)=>!t.ally&&t.alive)){if(_dist(player.position,t.position)<player.stats.range+4){t.hp=math.max(0,t.hp-player.stats.attack*.75);if(t.hp<=0)t.mesh?.visible=false;return;}}
      if(_allEnemyTowersDown()&&_dist(player.position,red.mesh.position)<18){red.hp=math.max(0,red.hp-player.stats.attack);}
    }}
  void castSkill(int i){if(!player.alive||i<0||i>=skills.length)return;final s=skills[i],l=s.at(level);if((cds[s.id]??0)>0||player.stats.mana<l.cost)return;player.stats.mana-=l.cost;cds[s.id]=l.cooldown;var center=player.position.clone();if(i==1){center.x+=joyX*s.range;center.z+=joyZ*s.range;player.position.setValues(center.x,0,center.z);player.mesh?.position.setValues(center.x,0,center.z);}if(i!=1)center=_nearestPoint();_spawnBurst(center,i==2?0xffbd72ff:0xff55e8ff,s.radius);for(final e in enemies)if(e.alive&&_dist(center,e.position)<=s.radius){_spawnProjectile(player.position,e.position,i==2?0xffc477ff:0xff63efff,18,0,null);e.takeDamage(l.damage+player.stats.attack*l.attackRatio,s.damageType);if(i==2)e.status.stun=.8;if(!e.alive){kills++;_earnGold(180);}}for(final m in minions)if(m.alive&&m.team==1&&_dist(center,m.position)<=s.radius){m.takeDamage(l.damage,s.damageType);if(!m.alive)_earnGold(45);}_showAim(center,s.radius);}
  void _rewardKill(ProUnit target){if(target.id.startsWith('E')){kills++;_earnGold(180);level=math.min(15,1+kills~/2);}else if(target.id.startsWith('M'))_earnGold(45);else if(target.id=='TURTLE'){_earnGold(300);player.addShield(450);}else if(target.id=='DRAKE')_earnGold(500);else if(target.id.startsWith('C'))_earnGold(80);}
  void _swingHero(ProUnit unit){final parts=_rigParts[unit.id];if(parts!=null&&parts.length>=2){parts[0].rotation.x=-1.15;parts[1].rotation.x=1.15;}}
  void _spawnProjectile(three.Vector3 from,three.Vector3 to,int color,double speed,double damage,ProUnit? target){final orb=mesh(three.SphereGeometry(.55,8,6),color,metal:.3);orb.position.setValues(from.x,3.2,from.z);view.scene.add(orb);_projectiles.add(_Projectile(orb,three.Vector3(from.x,3.2,from.z),three.Vector3(to.x,2.5,to.z),speed,damage,target));}
  void _spawnBurst(three.Vector3 p,int color,double radius){final ring=mesh(three.TorusGeometry(math.max(1,radius*.65),.22,6,24),color,metal:.25);ring.rotation.x=math.pi/2;ring.position.setValues(p.x,.45,p.z);view.scene.add(ring);_effects.add(_BattleEffect(ring,.55,radius*.9));for(int i=0;i<6;i++){final spark=mesh(three.OctahedronGeometry(.32,0),color,metal:.2);spark.position.setValues(p.x,1.1,p.z);view.scene.add(spark);_effects.add(_BattleEffect(spark,.35,radius*(.45+i*.08),phase:i*math.pi/3));}}
  void _updateCombatEffects(double dt){for(final p in _projectiles.toList()){final dx=p.to.x-p.position.x,dz=p.to.z-p.position.z,dy=p.to.y-p.position.y,d=math.sqrt(dx*dx+dy*dy+dz*dz);final step=p.speed*dt;if(d<=step||d<.8){if(p.target!=null&&p.target!.alive){final target=p.target!;if(target.id=='P'){_damagePlayer(p.damage);}else{final wasAlive=target.alive;target.takeDamage(p.damage,MobaDamageType.physical);_spawnBurst(target.position,0xffffc66b,1.8);if(wasAlive&&!target.alive)_rewardKill(target);}}view.scene.remove(p.mesh);_projectiles.remove(p);}else{p.position.x+=dx/d*step;p.position.y+=dy/d*step;p.position.z+=dz/d*step;p.mesh.position.setValues(p.position.x,p.position.y,p.position.z);}}
    for(final e in _effects.toList()){e.life-=dt;e.mesh.rotation.y+=dt*4;e.mesh.scale.setValues(1+(1-e.life/.55)*e.scale,1+(1-e.life/.55)*e.scale,1+(1-e.life/.55)*e.scale);e.mesh.position.y=.45+(1-e.life/.55)*1.2;if(e.phase!=0){e.mesh.position.x+=math.cos(e.phase)*dt*e.scale*2;e.mesh.position.z+=math.sin(e.phase)*dt*e.scale*2;}if(e.life<=0){view.scene.remove(e.mesh);_effects.remove(e);}}
  }
  three.Vector3 _nearestPoint(){final alive=enemies.where((e)=>e.alive&&e.targetable).toList();if(alive.isEmpty)return player.position.clone();alive.sort((a,b)=>_dist(a.position,player.position).compareTo(_dist(b.position,player.position)));return alive.first.position.clone();}
  void _showAim(three.Vector3 p,double r){if(aimRing==null){aimRing=mesh(three.TorusGeometry(1,.08,8,32),0x6ee7ff,metal:.2);view.scene.add(aimRing!);}aimTimer=.85;aimRing!.visible=true;aimRing!.scale.setValues(r,r,r);aimRing!.position.setValues(p.x,.35,p.z);aimRing!.rotation.z=0;}
  void _camera(){if(!started)return;view.camera.position.setValues(player.position.x-42,58,player.position.z+55);view.camera.lookAt(player.position);}
  void _finish(bool v){if(ended)return;ended=true;won=v;joyX=0;joyZ=0;if(mounted)setState((){});}

  Widget _mainMenu() {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff06101e), Color(0xff102f3d), Color(0xff07160f)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xdd081522),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xff55dff2).withValues(alpha: .42)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield_moon, size: 48, color: Color(0xff6de9ff)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ARENA LEGENDS', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white)),
                                Text('3D MOBILE MOBA • OFFLINE BATTLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xff6de9ff))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 145,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xff174b5b), Color(0xff142b49), Color(0xff311b50)],
                          ),
                        ),
                        child: const Stack(
                          children: [
                            Positioned(left: 18, top: 18, child: Icon(Icons.auto_awesome, size: 34, color: Color(0xff7af3ff))),
                            Positioned(right: 28, top: 16, child: Icon(Icons.bolt, size: 42, color: Color(0xffffcf6e))),
                            Center(child: Icon(Icons.sports_martial_arts, size: 88, color: Color(0xffd8f5ff))),
                            Positioned(left: 16, bottom: 12, child: Text('ENTER THE BATTLEFIELD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text('Pilih lane. Kalahkan lawan. Hancurkan crystal musuh.', style: TextStyle(color: Color(0xffd3e3ef), fontSize: 14)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _menuTag(Icons.view_in_ar, '3D ARENA'),
                          _menuTag(Icons.route, '3 LANES'),
                          _menuTag(Icons.auto_awesome, 'HERO SKILLS'),
                          _menuTag(Icons.castle, 'TOWER SIEGE'),
                        ],
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xff22c9e8),
                            foregroundColor: const Color(0xff061522),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: start,
                          icon: const Icon(Icons.play_arrow_rounded, size: 30),
                          label: const Text('MULAI PERTANDINGAN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Center(child: Text('SINGLE PLAYER • TOUCH CONTROLS • ORIGINAL HEROES', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Color(0xff8ca9bc), letterSpacing: 1.1))),
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
  Widget _menuTag(IconData icon,String label)=>Container(padding:const EdgeInsets.symmetric(horizontal:11,vertical:9),decoration:BoxDecoration(color:const Color(0xff173043),borderRadius:BorderRadius.circular(10),border:Border.all(color:const Color(0xff35546b))),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:15,color:const Color(0xff72eaff)),const SizedBox(width:6),Text(label,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w800,color:Colors.white))]));

  @override Widget build(BuildContext context){
    if(!started)return _mainMenu();
    return Scaffold(body:Stack(children:[Positioned.fill(child:view.build()),Positioned(top:10,left:10,right:10,child:_hud()),Positioned(top:56,right:12,child:_miniMap()),Positioned(left:18,bottom:18,child:_joystick()),Positioned(right:18,bottom:18,child:_buttons()),if(ended)Positioned.fill(child:_result())]));
  }
  Widget _hud()=>Row(children:[_pill('TIME '+time.toInt().toString()),const SizedBox(width:6),_pill('K/D '+kills.toString()+'/'+deaths.toString()),const SizedBox(width:6),_pill('LV '+level.toString()+' GOLD '+gold.toInt().toString()),const SizedBox(width:6),_pill('HP '+hp.toInt().toString()),const SizedBox(width:6),_pill('MP '+mana.toInt().toString()),const SizedBox(width:6),GestureDetector(onTap:_buyItem,child:_pill('SHOP '+inventory.items.length.toString()+'/6')),const Spacer(),_pill('WAVE '+wave.toString())]);
  void _earnGold(int amount){gold+=amount.toDouble();player.gold+=amount;}
  void _buyItem(){if(inventory.buy(shopItems[inventory.items.length%shopItems.length],player)){gold=player.gold.toDouble();setState((){});}}
  Widget _pill(String s)=>Material(color:Colors.black.withValues(alpha:.72),borderRadius:BorderRadius.circular(12),child:Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),child:Text(s,style:const TextStyle(fontWeight:FontWeight.w800))));
  Widget _joystick()=>GestureDetector(onPanUpdate:(d){joyX=(d.localPosition.dx-70)/60;joyZ=(d.localPosition.dy-70)/60;final n=math.sqrt(joyX*joyX+joyZ*joyZ);if(n>1){joyX/=n;joyZ/=n;}},onPanEnd:(_){joyX=0;joyZ=0;},child:Container(width:140,height:140,decoration:BoxDecoration(shape:BoxShape.circle,color:Colors.black54,border:Border.all(color:Colors.white24,width:2)),child:Center(child:Transform.translate(offset:Offset(joyX*27,joyZ*27),child:Container(width:58,height:58,decoration:BoxDecoration(shape:BoxShape.circle,color:const Color(0xff8beaff).withValues(alpha:.28),border:Border.all(color:Colors.white54,width:1.5),boxShadow:const [BoxShadow(color:Color(0x5539cfff),blurRadius:12)]),child:const Icon(Icons.gamepad,color:Colors.white70))))));
  Widget _miniMap()=>Container(width:150,height:92,padding:const EdgeInsets.all(7),decoration:BoxDecoration(color:Colors.black.withValues(alpha:.78),borderRadius:BorderRadius.circular(12),border:Border.all(color:Colors.white30)),child:CustomPaint(painter:_MiniMapPainter(playerX:player.position.x,playerZ:player.position.z)));
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

class _MiniMapPainter extends CustomPainter {
  const _MiniMapPainter({required this.playerX, required this.playerZ});
  final double playerX;
  final double playerZ;

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()..color = const Color(0xff81796b)..strokeWidth = 5..strokeCap = StrokeCap.round;
    final river = Paint()..color = const Color(0xff258eb4)..strokeWidth = 7;
    final blue = Paint()..color = const Color(0xff4e91ff);
    final red = Paint()..color = const Color(0xfff05462);
    final green = Paint()..color = const Color(0xff3c884b);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(7)), green);
    for (final y in <double>[size.height * .22, size.height * .5, size.height * .78]) {
      canvas.drawLine(Offset(5, y), Offset(size.width - 5, y), road);
    }
    canvas.drawLine(Offset(size.width * .5, 3), Offset(size.width * .5, size.height - 3), river);
    for (final y in <double>[size.height * .22, size.height * .5, size.height * .78]) {
      canvas.drawCircle(Offset(size.width * .25, y), 3, blue);
      canvas.drawCircle(Offset(size.width * .75, y), 3, red);
    }
    canvas.drawCircle(Offset(8 + (playerX + 84) / 168 * (size.width - 16), 8 + (playerZ + 56) / 112 * (size.height - 16)), 4.5, Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(8 + (playerX + 84) / 168 * (size.width - 16), 8 + (playerZ + 56) / 112 * (size.height - 16)), 6, Paint()..color = Colors.white.withValues(alpha:.65)..style = PaintingStyle.stroke..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant _MiniMapPainter oldDelegate) => oldDelegate.playerX != playerX || oldDelegate.playerZ != playerZ;
}

class _Projectile { _Projectile(this.mesh,this.position,this.to,this.speed,this.damage,this.target); final three.Mesh mesh; final three.Vector3 position,to; final double speed,damage; final ProUnit? target; }
class _BattleEffect { _BattleEffect(this.mesh,this.life,this.scale,{this.phase=0}); final three.Mesh mesh; double life; final double scale,phase; }
