import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/player_data.dart';

class ContinueDialog extends StatefulWidget {
  final VoidCallback onRevive;
  final VoidCallback onGiveUp;

  const ContinueDialog({
    super.key,
    required this.onRevive,
    required this.onGiveUp,
  });

  @override
  State<ContinueDialog> createState() => _ContinueDialogState();
}

class _ContinueDialogState extends State<ContinueDialog> {
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
        widget.onGiveUp();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerData = PlayerData();
    const reviveCostGold = 2;
    final canAfford = playerData.goldFish >= reviveCostGold;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7EA),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD6A266), width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular countdown with icon
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: _countdown / 5.0,
                    strokeWidth: 6,
                    backgroundColor: Colors.orange.shade100,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  '$_countdown',
                  style: const TextStyle(
                    fontFamily: 'JandaManatee',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B4226),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sad Haru image
            Image.asset(
              'assets/images/sprites/ui/Haru_sad.png',
              height: 90,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.pets,
                size: 60,
                color: Color(0xFFD6A266),
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'CONTINUE?',
              style: TextStyle(
                fontFamily: 'JandaManatee',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4226),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Revive now to clear 4 rows\nand keep your awesome score!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'BrandonText',
                fontSize: 14,
                color: Color(0xFF8B5A2B),
              ),
            ),
            const SizedBox(height: 20),

            // Revive button
            GestureDetector(
              onTap: () {
                _timer?.cancel();
                if (canAfford) {
                  playerData.spendGoldFish(reviveCostGold);
                  widget.onRevive();
                } else {
                  // Free emergency continue!
                  widget.onRevive();
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (canAfford) ...[
                      Image.asset(
                        'assets/images/sprites/ui/coin-gold-8.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (_, __, ___) => const Icon(Icons.star, color: Colors.yellow, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$reviveCostGold CONTINUE',
                        style: const TextStyle(
                          fontFamily: 'JandaManatee',
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else ...[
                      const Icon(Icons.play_arrow_rounded, color: Colors.white),
                      const SizedBox(width: 6),
                      const Text(
                        'FREE CONTINUE',
                        style: TextStyle(
                          fontFamily: 'JandaManatee',
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Give up button
            TextButton(
              onPressed: () {
                _timer?.cancel();
                widget.onGiveUp();
              },
              child: const Text(
                'NO, THANKS',
                style: TextStyle(
                  fontFamily: 'BrandonText',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
