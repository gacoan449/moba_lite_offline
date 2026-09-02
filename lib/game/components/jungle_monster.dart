import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../moba_game.dart';
class JungleMonster extends PositionComponent with HasGameRef<MOBAOfflineGame>{
 final bool boss; double hp,timer=0; final double maxHp;
 JungleMonster({required Vector2 position,this.boss=false}):maxHp=boss?1800:450,hp=boss?1800:450,super(position:position,size:Vector2.all(boss?90:58),anchor:Anchor.center);
 bool get dead=>hp<=0;
 void takeDamage(double d){if(dead)return;hp=math.max(0,hp-d);if(dead)gameRef.onMonsterKilled(this);}
 @override void update(double dt){super.update(dt);if(dead||gameRef.player.isDead)return;timer=math.max(0,timer-dt);final d=gameRef.player.position.distanceTo(position);if(d<280&&timer<=0){gameRef.player.takeDamage(boss?28:12);timer=boss?.75:1.15;}}
 @override void render(Canvas c){super.render(c);final r=size.x/2;final center=Offset(r,r);c.drawOval(Rect.fromCenter(center:Offset(r,r+size.y*.28),width:size.x*.8,height:size.y*.2),Paint()..color=Colors.black38);final body=Paint()..color=boss?const Color(0xff7b2cbf):const Color(0xffc66b24);c.drawCircle(center,r*.7,body);c.drawCircle(Offset(r-r*.22,r-r*.18),r*.12,Paint()..color=Colors.redAccent);c.drawCircle(Offset(r+r*.22,r-r*.18),r*.12,Paint()..color=Colors.redAccent);c.drawRect(Rect.fromLTWH(4,1,size.x-8,5),Paint()..color=Colors.black87);c.drawRect(Rect.fromLTWH(4,1,(size.x-8)*math.max(0,hp/maxHp),5),Paint()..color=Colors.limeAccent);if(boss)c.drawCircle(Offset(r,r),r*.88,Paint()..style=PaintingStyle.stroke..strokeWidth=3..color=Colors.amber);}
}
