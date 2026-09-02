import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../moba_game.dart';
import 'world_render_3d.dart';

class MinionComponent extends PositionComponent with HasGameReference<MOBAOfflineGame> {
  final bool allied;
  final bool ranged;
  double hp;
  double attackTimer = 0;
  double visualTime = 0;

  MinionComponent({required Vector2 position, required this.allied, this.ranged = false})
      : hp = ranged ? 65 : 95,
        super(position: position, size: Vector2.all(52), anchor: Anchor.center);

  void takeDamage(double damage) {
    hp -= damage;
    if (hp <= 0) {
      hp = 0;
      removeFromParent();
      game.gold += 12;
      game.xp += 8;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hp <= 0) return;
    visualTime += dt;
    attackTimer = math.max(0, attackTimer - dt).toDouble();
    final enemyMinions = game.minions.where((minion) => minion.allied != allied && !minion.isRemoved && minion.position.distanceTo(position) < 80).toList();
    final enemyTurrets = game.turrets.where((turret) => turret.allied != allied && !turret.destroyed && turret.position.distanceTo(position) < 95).toList();
    if (attackTimer <= 0) {
      if (enemyMinions.isNotEmpty) {
        enemyMinions.first.takeDamage(ranged ? 18 : 25);
        attackTimer = ranged ? 0.8 : 0.7;
      } else if (enemyTurrets.isNotEmpty) {
        enemyTurrets.first.takeDamage(ranged ? 13 : 19);
        attackTimer = 1;
      } else {
        position.x += (allied ? 95 : -95) * dt;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final o = Offset(size.x / 2, size.y / 2);
    final primary = allied ? const Color(0xff1d65b4) : const Color(0xffa92e3d);
    final secondary = allied ? const Color(0xff79d4ff) : const Color(0xffff7c86);
    WorldRender3D.shadow(canvas, Offset(o.dx, o.dy + 18), 36, 11);
    WorldRender3D.armoredBody(canvas, center: Offset(o.dx, o.dy + 5), width: ranged ? 38 : 42, height: ranged ? 38 : 42,
      primary: primary, secondary: secondary, phase: visualTime);
    canvas.drawCircle(Offset(o.dx, o.dy - 14), 10, Paint()..color = secondary);
    canvas.drawPath(Path()..moveTo(o.dx - 9, o.dy - 14)..lineTo(o.dx, o.dy - 22)..lineTo(o.dx + 9, o.dy - 14)..close(), Paint()..color = Colors.black.withValues(alpha: .65));
    canvas.drawCircle(Offset(o.dx - 3, o.dy - 14), 2, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(o.dx + 3, o.dy - 14), 2, Paint()..color = Colors.white);
    if (ranged) {
      canvas.drawCircle(Offset(o.dx, o.dy + 9), 8, Paint()..color = Colors.amber.withValues(alpha: .85));
    }
    WorldRender3D.hpBar(canvas, x: 6, y: 1, width: size.x - 12, hp: hp, maxHp: ranged ? 65 : 95);
  }
}
