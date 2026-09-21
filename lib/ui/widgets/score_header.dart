import 'package:flutter/material.dart';
import '../../logic/game_controller.dart';
import '../../models/player_data.dart';

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
    final isReady = controller.isSkillReady;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Pause Button
              GestureDetector(
                onTap: onPause,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pause_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),

              // Character Avatar + Skill Charge Meter
              GestureDetector(
                onTap: isReady ? () => controller.activateSkill() : null,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Circular progress border
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: controller.skillCharge,
                        strokeWidth: 4,
                        backgroundColor: Colors.brown.shade200,
                        color: isReady ? Colors.amber : Colors.orangeAccent,
                      ),
                    ),

                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFF3E0),
                        border: Border.all(
                          color: isReady ? Colors.amber : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          currentChar.imageAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.pets, color: Colors.orange, size: 24),
                        ),
                      ),
                    ),

                    // Skill Ready Badge
                    if (isReady)
                      Positioned(
                        bottom: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'SKILL!',
                            style: TextStyle(
                              fontFamily: 'BrandonText',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Score & In-game Level
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D4037),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.mode == GameMode.endless
                          ? 'LV ${controller.inGameLevel} (x${controller.scoreMultiplier})'
                          : 'SCORE',
                      style: const TextStyle(
                        fontFamily: 'BrandonText',
                        color: Color(0xFFFFE082),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      '${controller.score}',
                      style: const TextStyle(
                        fontFamily: 'JandaManatee',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Best Score or Moves
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6D4C41),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.mode == GameMode.endless ? 'BEST' : 'MOVES',
                      style: const TextStyle(
                        fontFamily: 'BrandonText',
                        color: Color(0xFFBCAAA4),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      controller.mode == GameMode.endless
                          ? '${controller.bestScore}'
                          : '${controller.moves}',
                      style: const TextStyle(
                        fontFamily: 'JandaManatee',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Speech Bubble with Mascot quote
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD6A266)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.orange),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    controller.mascotQuote,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'BrandonText',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4226),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
