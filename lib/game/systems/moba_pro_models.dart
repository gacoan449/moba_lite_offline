import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;

enum MobaDamageType { physical, magic, trueDamage }
enum TargetMode { nearest, manual, area, directional, locked }

class SkillLevel {
  const SkillLevel(this.damage, this.cooldown, this.cost, {this.attackRatio=0, this.magicRatio=0});
  final double damage, cooldown, cost, attackRatio, magicRatio;
}
class SkillData {
  const SkillData({required this.id, required this.name, required this.levels, this.range=18, this.radius=5, this.mode=TargetMode.area, this.damageType=MobaDamageType.physical});
  final String id, name;
  final List<SkillLevel> levels;
  final double range, radius;
  final TargetMode mode;
  final MobaDamageType damageType;
  SkillLevel at(int level)=>levels[(level-1).clamp(0,levels.length-1)];
}
class AbilityBook {
  AbilityBook(this.skills);
  final List<SkillData> skills;
  final Map<String,double> cooldowns={};
  bool ready(SkillData s)=>(cooldowns[s.id]??0)<=0;
  double remaining(SkillData s)=>cooldowns[s.id]??0;
  void start(SkillData s,double cd)=>cooldowns[s.id]=cd;
  void tick(double dt){for(final id in cooldowns.keys.toList()){cooldowns[id]=math.max(0,(cooldowns[id]??0)-dt);}}
}
class CombatStats {
  CombatStats({required this.maxHp,required this.attack,required this.armor,required this.magicResist,required this.moveSpeed,required this.range,this.maxMana=500})
      : hp=maxHp,mana=maxMana;
  double maxHp,hp,attack,armor,magicResist,moveSpeed,range,maxMana,mana,shield=0;
  bool get alive=>hp>0;
}
class StatusState {
  double slow=0,stun=0,silence=0,knockUp=0;
  void tick(double dt){slow=math.max(0,slow-dt);stun=math.max(0,stun-dt);silence=math.max(0,silence-dt);knockUp=math.max(0,knockUp-dt);}
  bool get disabled=>stun>0||knockUp>0;
}
class MobaUnit {
  MobaUnit({required this.id,required this.team,required this.position,required this.stats});
  final String id; final int team; final three.Vector3 position; final CombatStats stats;
  final StatusState status=StatusState();
  bool targetable=true; double respawnTimer=0; int level=1; int gold=500; double xp=0;
  bool get alive=>stats.alive;
  void heal(double amount){if(alive)stats.hp=math.min(stats.maxHp,stats.hp+amount);}
  void addShield(double amount){stats.shield=math.max(stats.shield,amount);}
  double takeDamage(double raw,MobaDamageType type){
    if(!alive||!targetable)return 0;
    var amount=raw;
    if(type==MobaDamageType.physical)amount*=100/(100+stats.armor);
    if(type==MobaDamageType.magic)amount*=100/(100+stats.magicResist);
    final absorbed=math.min(stats.shield,amount);stats.shield-=absorbed;amount-=absorbed;
    stats.hp=math.max(0,stats.hp-amount);return amount;
  }
  void gainXp(double value){xp+=value;while(level<15&&xp>=level*level*170){level++;}}
}
class ItemData {
  const ItemData(this.id,this.name,this.price,{this.attack=0,this.hp=0,this.armor=0,this.mr=0,this.speed=0});
  final String id,name;final int price;final double attack,hp,armor,mr,speed;
}
const shopItems=<ItemData>[
 ItemData('blade','Rift Blade',800,attack:28),
 ItemData('guard','Iron Guard',750,hp:300,armor:24),
 ItemData('mantle','Arcane Mantle',800,hp:180,mr:28),
 ItemData('boots','Swift Boots',650,speed:35),
 ItemData('edge','Execution Edge',1450,attack:48),
];
class Inventory {
 final List<ItemData> items=[];
 bool buy(ItemData item,MobaUnit unit){
  if(unit.gold<item.price||items.length>=6)return false;
  unit.gold-=item.price;items.add(item);unit.stats.maxHp+=item.hp;unit.stats.hp+=item.hp;
  unit.stats.attack+=item.attack;unit.stats.armor+=item.armor;unit.stats.magicResist+=item.mr;unit.stats.moveSpeed+=item.speed;return true;
 }
}
abstract class MobaTransport {
 bool get connected;
 Future<void> connect();
 Future<void> disconnect();
 Future<void> sendCommand(String command,Map<String,dynamic> payload);
}
class LocalTransport implements MobaTransport {
 bool _connected=false;
 bool get connected=>_connected;
 Future<void> connect()async{_connected=true;}
 Future<void> disconnect()async{_connected=false;}
 Future<void> sendCommand(String command,Map<String,dynamic> payload)async{}
}