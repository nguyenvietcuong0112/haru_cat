import 'package:flutter/material.dart';
import '../../logic/game_controller.dart';
import '../../models/player_data.dart';
import '../dialogs/shop_dialog.dart';
import '../dialogs/character_select_dialog.dart';

class ScoreHeader extends StatelessWidget {
  final GameController controller;
  final VoidCallback onPause;

  const ScoreHeader({
    super.key,
    required this.controller,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    final currentChar = PlayerData().currentCharacter;

    return AnimatedBuilder(
      animation: PlayerData(),
      builder: (context, _) {
        final playerData = PlayerData();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Silver Coin Pill, Gold Coin Pill, Pause Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Silver Coin Pill (bỏ dấu + theo feedback)
                  _buildCurrencyPill(
                    context,
                    iconAsset: 'assets/images/sprites/ui/coin-silver-8.png',
                    amount: '${playerData.silverFish}',
                    multiplier: controller.silverMultiplier,
                    showAddButton: false,
                    onTap: () => showDialog(context: context, builder: (_) => const ShopDialog()),
                  ),

                  // Gold Coin Pill (giữ dấu + để nạp)
                  _buildCurrencyPill(
                    context,
                    iconAsset: 'assets/images/sprites/ui/coin-gold-8.png',
                    amount: '${playerData.goldFish}',
                    showAddButton: true,
                    onTap: () => showDialog(context: context, builder: (_) => const ShopDialog()),
                  ),

                  // Pause Button
                  GestureDetector(
                    onTap: onPause,
                    child: Image.asset(
                      'assets/images/sprites/ui/btn_pause.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF80DEEA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.pause, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Row 2: Collection Button (left), and Score Pill (right)
              Row(
                children: [
                  // Collection Button (đổi từ Skill Button theo feedback)
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => const CharacterSelectDialog(),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F7FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF80DEEA), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFF80DEEA), width: 1.5),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                currentChar.imageAsset,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.collections_bookmark_rounded, color: Colors.cyan, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'COLLECTION',
                                style: TextStyle(
                                  fontFamily: 'BrandonText',
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF006064),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Bộ sưu tập',
                                style: TextStyle(
                                  fontFamily: 'BrandonText',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00838F),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 2),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Score Capsule (matches score_pill.png)
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F7FA),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF80DEEA), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Left half: Best Score
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Best Score',
                                  style: TextStyle(
                                    fontFamily: 'BrandonText',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${controller.bestScore}',
                                  style: const TextStyle(
                                    fontFamily: 'JandaManatee',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1.5,
                            height: 28,
                            color: const Color(0xFF80DEEA),
                          ),
                          // Right half: SCORE
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'SCORE',
                                  style: TextStyle(
                                    fontFamily: 'BrandonText',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${controller.score}',
                                  style: const TextStyle(
                                    fontFamily: 'JandaManatee',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrencyPill(
    BuildContext context, {
    required String iconAsset,
    required String amount,
    double? multiplier,
    bool showAddButton = true,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F7FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF80DEEA), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconAsset,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.circle, size: 16, color: Colors.amber),
            ),
            if (showAddButton) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 10, color: Colors.white),
              ),
            ],
            const SizedBox(width: 6),
            Text(
              amount,
              style: const TextStyle(
                fontFamily: 'JandaManatee',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            if (multiplier != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'x${multiplier.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontFamily: 'BrandonText',
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
