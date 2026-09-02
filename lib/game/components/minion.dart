import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../moba_game.dart';

class MinionComponent extends PositionComponent with HasGameRef<MOBAOfflineGame> {
  final bool allied;
  final bool ranged;
  double hp;
  double attackTimer = 0;

  MinionComponent({required Vector2 position, required this.allied, this.ranged = false})
      : hp = ranged ? 55 : 80,
        super(position: position, size: Vector2.all(38), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    attackTimer = math.max(0, attackTimer - dt);
    if (allied) {
      position.x += 18 * dt;
    } else {
      position.x -= 18 * dt;
    }
    if (position.x.abs() > 3000) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final c = Offset(size.x / 2, size.y / 2);
    final primary = allied ? const Color(0xFF2878D8) : const Color(0xFFD33A45);
    final secondary = allied ? const Color(0xFF71C8FF) : const Color(0xFFFF7474);

    canvas.drawOval(Rect.fromCenter(center: Offset(c.dx, c.dy + 11), width: 28, height: 8), Paint()..color = Colors.black.withOpacity(.25));
    canvas.drawCircle(Offset(c.dx, c.dy + 5), 11, Paint()..color = primary);
    canvas.drawCircle(Offset(c.dx, c.dy - 6), 9, Paint()..color = secondary);
    canvas.drawCircle(Offset(c.dx - 3, c.dy - 8), 2.2, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(c.dx + 3, c.dy - 8), 2.2, Paint()..color = Colors.white);
    canvas.drawLine(Offset(c.dx - 3, c.dy - 1), Offset(c.dx + 3, c.dy - 1), Paint()..color = Colors.black87..strokeWidth = 1.5);
    if (ranged) {
      canvas.drawCircle(Offset(c.dx, c.dy + 7), 5, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.amberAccent);
    }
  }
}
