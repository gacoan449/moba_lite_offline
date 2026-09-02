import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../moba_game.dart';
import 'turret.dart';
class MinionComponent extends PositionComponent with HasGameRef<MOBAOfflineGame>{
 final bool allied,ranged; double hp,attackTimer=0;
 MinionComponent({required Vector2 position,required this.allied,this.ranged=false}):hp=ranged?65:95,super(position:position,size:Vector2.all(42),anchor:Anchor.center);
 void takeDamage(double d){hp-=d;if(hp<=0){hp=0;removeFromParent();gameRef.gold+=12;gameRef.xp+=8;}}
 @override void update(double dt){super.update(dt);if(hp<=0)return;attackTimer=math.max(0,attackTimer-dt);final es=gameRef.minions.where((m)=>m.allied!=allied&&!m.isRemoved&&m.position.distanceTo(position)<80).toList();final ts=gameRef.turrets.where((t)=>t.allied!=allied&&!t.destroyed&&t.position.distanceTo(position)<95).toList();if(attackTimer<=0){if(es.isNotEmpty){es.first.takeDamage(ranged?18:25);attackTimer=ranged?.8:.7;}else if(ts.isNotEmpty){ts.first.takeDamage(ranged?13:19);attackTimer=1;}else{position.x+=(allied?95:-95)*dt;}}}
 @override void render(Canvas c){super.render(c);final o=Offset(size.x/2,size.y/2);final a=allied?const Color(0xff2581dd):const Color(0xffd83e4c),b=allied?const Color(0xff8ed8ff):const Color(0xffff8b8b);c.drawOval(Rect.fromCenter(center:Offset(o.dx,o.dy+14),width:32,height:9),Paint()..color=Colors.black38);c.drawCircle(Offset(o.dx,o.dy+5),13,Paint()..color=a);c.drawCircle(Offset(o.dx,o.dy-8),10,Paint()..color=b);c.drawCircle(Offset(o.dx-4,o.dy-10),2.4,Paint()..color=Colors.white);c.drawCircle(Offset(o.dx+4,o.dy-10),2.4,Paint()..color=Colors.white);c.drawLine(Offset(o.dx-4,o.dy-2),Offset(o.dx+4,o.dy-2),Paint()..color=Colors.black87..strokeWidth=2);if(ranged)c.drawCircle(Offset(o.dx,o.dy+7),7,Paint()..style=PaintingStyle.stroke..strokeWidth=2..color=Colors.amber);c.drawRect(Rect.fromLTWH(5,1,32,4),Paint()..color=Colors.black87);c.drawRect(Rect.fromLTWH(5,1,32*math.max(0,hp/(ranged?65:95)),4),Paint()..color=Colors.limeAccent);}
}
