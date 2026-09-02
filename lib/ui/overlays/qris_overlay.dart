import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../game/moba_game.dart';

class QrisOverlay extends StatefulWidget {
  final MOBAOfflineGame game;
  const QrisOverlay({super.key, required this.game});

  @override
  State<QrisOverlay> createState() => _QrisOverlayState();
}

class _QrisOverlayState extends State<QrisOverlay> {
  int timeLeft = 5;
  late Timer countdownTimer;
  final TextEditingController _verifyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        if (mounted) setState(() => timeLeft--);
      } else {
        timer.cancel();
        _forceGameOver();
      }
    });
  }

  void _forceGameOver() {
    widget.game.overlays.remove('QRIS_PAYWALL');
    widget.game.overlays.add('GAME_OVER_NORMAL');
  }

  Future<void> _activatePremium() async {
    if (_verifyController.text.trim().isNotEmpty) {
      countdownTimer.cancel();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium_weapon', true);
      widget.game.isPremiumWeapon = true;
      widget.game.player.hp = widget.game.player.maxHp;
      widget.game.player.isDead = false;
      widget.game.overlays.remove('QRIS_PAYWALL');
      widget.game.resumeEngine();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama/kode unik terlebih dahulu!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'WAKTU TERSISA: 00:0$timeLeft',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 15),
              Container(
                height: 150,
                width: 150,
                color: Colors.grey[300],
                child: Image.asset(
                  'assets/images/qris_gopay.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.qr_code_2, size: 100, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Bangkit Instan dengan HP Penuh + Damage Laser 3 Arah?\n\nCukup Scan QRIS Rp2.000!',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _verifyController,
                decoration: InputDecoration(
                  hintText: 'Nama Pengirim / Kode Unik',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700], foregroundColor: Colors.white),
                  onPressed: _activatePremium,
                  child: const Text('AKTIFKAN SEKARANG', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    countdownTimer.cancel();
    _verifyController.dispose();
    super.dispose();
  }
}
