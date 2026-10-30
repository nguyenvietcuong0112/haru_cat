import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/player_data.dart';
import '../widgets/game_popup_kit.dart';

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

    return GamePopupFrame(
      title: 'CONTINUE?',
      bannerPalette: GameButtonPalette.orange,
      maxWidth: 335,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),

          // 3D Ocean Countdown Ring + Mascot Row
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD5F3FA),
                  border: Border.all(color: const Color(0xFF6CC0D6), width: 2),
                ),
              ),
              SizedBox(
                width: 82,
                height: 82,
                child: CircularProgressIndicator(
                  value: _countdown / 5.0,
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  backgroundColor: const Color(0xFFB3E5FC),
                  color: _countdown <= 2
                      ? const Color(0xFFFF5252)
                      : const Color(0xFFFF9800),
                ),
              ),
              GameStrokedText(
                '$_countdown',
                fontSize: 34,
                fillColor: _countdown <= 2
                    ? const Color(0xFFFFEBEE)
                    : Colors.white,
                strokeColor: _countdown <= 2
                    ? const Color(0xFF7F1D1D)
                    : const Color(0xFF134B5A),
                strokeWidth: 5.2,
              ),
            ],
          ),
          const SizedBox(height: 12),

          Image.asset(
            'assets/images/sprites/ui/Haru_sad.png',
            height: 84,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.waves_rounded,
              size: 56,
              color: Color(0xFF26C6DA),
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD7F4FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF81CBE0), width: 1.5),
            ),
            child: const Text(
              'Revive now to clear the top 4 rows and keep your current score!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'BrandonText',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF155161),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Revive 3D Button
          Game3DButton(
            height: 52,
            palette: GameButtonPalette.green,
            onTap: () {
              _timer?.cancel();
              if (canAfford) {
                playerData.spendGoldFish(reviveCostGold);
                widget.onRevive();
              } else {
                widget.onRevive();
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (canAfford) ...[
                  Image.asset(
                    'assets/images/sprites/ui/coin-gold-8.png',
                    width: 23,
                    height: 23,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.star, color: Colors.yellow, size: 20),
                  ),
                  const SizedBox(width: 8),
                  GameStrokedText(
                    '$reviveCostGold  CONTINUE',
                    fontSize: 17.5,
                    strokeColor: GameButtonPalette.green.textStroke,
                    strokeWidth: 4.4,
                  ),
                ] else ...[
                  const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 6),
                  GameStrokedText(
                    'FREE CONTINUE',
                    fontSize: 17.5,
                    strokeColor: GameButtonPalette.green.textStroke,
                    strokeWidth: 4.4,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Give Up 3D Slate Button
          Game3DButton(
            label: 'NO, THANKS',
            palette: GameButtonPalette.slate,
            height: 42,
            fontSize: 14,
            onTap: () {
              _timer?.cancel();
              widget.onGiveUp();
            },
          ),
        ],
      ),
    );
  }
}
