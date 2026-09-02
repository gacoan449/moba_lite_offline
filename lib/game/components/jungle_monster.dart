import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../moba_game.dart';
import 'world_render_3d.dart';

class JungleMonster extends PositionComponent with HasGameRef<MOBAOfflineGame> {
  final bool boss;
  double hp;
  double timer = 0;
  double visualTime = 0;
  final double maxHp;

  JungleMonster({required Vector2 position, this.boss = false})
      : maxHp = boss ? 1800 : 450,
        hp = boss ? 1800 : 450,
        super(position: position, size: Vector2.all(boss ? 110 : 70), anchor: Anchor.center);

  bool get dead => hp <= 0;

  void takeDamage(double damage) {
    if (dead) return;
    hp = math.max(0, hp - damage).toDouble();
    if (dead) gameRef.onMonsterKilled(this);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (dead || gameRef.player.isDead) return;
    visualTime += dt;
    timer = math.max(0, timer - dt).toDouble();
    final distance = gameRef.player.position.distanceTo(position);
    if (distance < 280 && timer <= 0) {
      gameRef.player.takeDamage(boss ? 28 : 12);
      timer = boss ? 0.75 : 1.15;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final r = size.x / 2;
    final c = Offset(r, r);
    final pulse = math.sin(visualTime * (boss ? 4 : 7));
    final primary = boss ? const Color(0xff5b168f) : const Color(0xff9a531d);
    final secondary = boss ? const Color(0xffffc13b) : const Color(0xffffa342);

    WorldRender3D.shadow(canvas, Offset(r, r + size.y * .29), size.x * .82, size.y * .22);
    WorldRender3D.armoredBody(
      canvas,
      center: Offset(r, r + 7),
      width: size.x * .72,
      height: size.y * .70,
      primary: primary,
      secondary: secondary,
      phase: visualTime,
    );
    canvas.drawCircle(Offset(r, r - size.y * .18), size.x * .22, Paint()..color = secondary);
    canvas.drawCircle(Offset(r - r * .25, r - r * .19), r * .11, Paint()..color = Colors.redAccent);
    canvas.drawCircle(Offset(r + r * .25, r - r * .19), r * .11, Paint()..color = Colors.redAccent);
    canvas.drawLine(
      Offset(r - r * .16, r + r * .02),
      Offset(r + r * .16, r + r * .02),
      Paint()..color = Colors.black87..strokeWidth = math.max(2, r * .06),
    );
    if (boss) {
      WorldRender3D.crystal(
        canvas,
        center: Offset(r, r - r * .48 + pulse * 2),
        radius: r * .18,
        color: Colors.cyanAccent,
        phase: visualTime,
      );
      canvas.drawCircle(
        c,
        r * (.86 + pulse * .025),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.amber.withOpacity(.75),
      );
    }
    WorldRender3D.hpBar(canvas, x: 5, y: 1, width: size.x - 10, hp: hp, maxHp: maxHp);
  }
}
