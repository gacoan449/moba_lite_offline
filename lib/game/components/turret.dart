import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../moba_game.dart';
class TurretComponent extends PositionComponent with HasGameRef<MOBAOfflineGame>{
 final bool allied; final String lane; double hp=900,timer=0;
 TurretComponent({required Vector2 position,required this.allied,required this.lane}):super(position:position,size:Vector2(70,90),anchor:Anchor.center);
 bool get destroyed=>hp<=0;
 void takeDamage(double d){if(destroyed)return;hp=math.max(0,hp-d);if(destroyed)gameRef.onTurretDestroyed(this);}
 @override void update(double dt){super.update(dt);if(destroyed)return;timer=math.max(0,timer-dt);if(timer>0)return;if(allied){for(final e in gameRef.enemies){if(!e.isDead&&e.position.distanceTo(position)<430){e.takeDamage(35);timer=.9;break;}}}else if(!gameRef.player.isDead&&gameRef.player.position.distanceTo(position)<430){gameRef.player.takeDamage(18);timer=.9;}}
 @override void render(Canvas c){super.render(c);final p=Paint()..color=allied?const Color(0xff2878d8):const Color(0xffd13d4b);c.drawOval(Rect.fromCenter(center:const Offset(35,76),width:58,height:18),Paint()..color=Colors.black38);c.drawRect(const Rect.fromLTWH(13,28,44,48),p);c.drawCircle(const Offset(35,27),19,p);c.drawRect(const Rect.fromLTWH(5,2,60,7),Paint()..color=Colors.black87);c.drawRect(Rect.fromLTWH(5,2,60*math.max(0,hp/900),7),Paint()..color=Colors.limeAccent);c.drawLine(const Offset(35,20),const Offset(35,0),Paint()..color=Colors.amber..strokeWidth=5);}
}
