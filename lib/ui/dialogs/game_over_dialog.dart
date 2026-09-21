import 'dart:math';
import 'package:flutter/material.dart';

class GameOverDialog extends StatelessWidget {
  final int score;
  final int bestScore;
  final int linesCleared;
  final int specialBlocksCleared;
  final int maxCombo;
  final int silverEarned;
  final VoidCallback onReplay;
  final VoidCallback onHome;

  GameOverDialog({
    super.key,
    required this.score,
    required this.bestScore,
    this.linesCleared = 0,
    this.specialBlocksCleared = 0,
    this.maxCombo = 0,
    this.silverEarned = 0,
    required this.onReplay,
    required this.onHome,
  });

  static const List<String> funFacts = [
    'Playing tips: Check the next blocks before you move the cat!',
    'NASA recently pinpointed that the perfect refreshing nap is 26 minutes long.',
    'Brain fact: The human brain weighs only about 3 lbs (1.5 kg).',
    'Playing tips: Prioritize clearing larger size-3 blocks first to create space!',
    'Brain fact: Concentration and puzzle abilities peak with daily brain training.',
    'Did you know: Cats spend 70% of their lives sleeping and 15% grooming!',
    'Playing tips: Special lightning cats can clear entire columns when triggered!',
    'Relaxing with puzzle games helps boost memory and reduces daily stress.',
  ];

  final String randomFact = funFacts[Random().nextInt(funFacts.length)];

  @override
  Widget build(BuildContext context) {
    final isNewRecord = score > 0 && score >= bestScore;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E7),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFD6A266), width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Character
            Image.asset(
              'assets/images/characters/GameOverCharacter.png',
              height: 90,
              errorBuilder: (_, __, ___) => const Text('😿', style: TextStyle(fontSize: 50)),
            ),
            const SizedBox(height: 8),

            const Text(
              'GAME OVER',
              style: TextStyle(
                fontFamily: 'JandaManatee',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(height: 12),

            // Score Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF5D4037),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'YOUR SCORE',
                    style: TextStyle(
                      fontFamily: 'BrandonText',
                      color: Color(0xFFFFD54F),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontFamily: 'JandaManatee',
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isNewRecord)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '★ NEW HIGH SCORE! ★',
                        style: TextStyle(
                          fontFamily: 'BrandonText',
                          color: Color(0xFF5D4037),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'BEST: $bestScore',
                    style: const TextStyle(
                      fontFamily: 'BrandonText',
                      color: Color(0xFFD7CCC8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Stats 4-Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatBadge('Lines Cleared', '$linesCleared', Icons.grid_view_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatBadge('Special Cleared', '$specialBlocksCleared', Icons.bolt_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildStatBadge('Max Combo', '${maxCombo}x', Icons.local_fire_department_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatBadge('Silver Earned', '+$silverEarned', Icons.set_meal_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fun Fact Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0D4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/sprites/ui/tag_fun_fact.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (_, __, ___) => const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      randomFact,
                      style: const TextStyle(
                        fontFamily: 'BrandonText',
                        fontSize: 11,
                        color: Color(0xFF6B4226),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Replay Button
            GestureDetector(
              onTap: onReplay,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.replay_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'PLAY AGAIN',
                      style: TextStyle(
                        fontFamily: 'JandaManatee',
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Home Button
            TextButton.icon(
              onPressed: onHome,
              icon: const Icon(Icons.home_rounded, color: Color(0xFF6B4226), size: 18),
              label: const Text(
                'MAIN MENU',
                style: TextStyle(
                  fontFamily: 'BrandonText',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4226),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String title, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2C4A2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.orange),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontFamily: 'BrandonText', fontSize: 9, color: Colors.brown.shade400),
                ),
                Text(
                  val,
                  style: const TextStyle(
                    fontFamily: 'JandaManatee',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
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
