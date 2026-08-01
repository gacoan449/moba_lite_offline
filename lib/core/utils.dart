import 'dart:math';
import 'package:flame/components.dart';

class GameUtils {
  static final Random _random = Random();

  /// Fungsi untuk mendapatkan koordinat spawn musuh secara acak
  /// di luar layar pemain namun tidak terlalu jauh.
  static Vector2 generateRandomSpawnPosition(Vector2 playerPosition, double minRadius, double maxRadius) {
    // Dapatkan sudut acak dari 0 hingga 360 derajat (dalam radian)
    double angle = _random.nextDouble() * 2 * pi;
    
    // Dapatkan jarak acak antara minRadius dan maxRadius
    double radius = minRadius + _random.nextDouble() * (maxRadius - minRadius);
    
    // Konversi koordinat polar ke kartesian (X, Y)
    double offsetX = cos(angle) * radius;
    double offsetY = sin(angle) * radius;

    return playerPosition + Vector2(offsetX, offsetY);
  }

  /// Fungsi utilitas untuk membatasi nilai agar tidak melebihi batas (Clamping)
  static double clampValue(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
