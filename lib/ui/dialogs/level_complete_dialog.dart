import 'package:flutter/material.dart';

class LevelCompleteDialog extends StatelessWidget {
  final int stars;
  final int moves;
  final VoidCallback onNextLevel;
  final VoidCallback onHome;

  const LevelCompleteDialog({
    super.key,
    required this.stars,
    required this.moves,
    required this.onNextLevel,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E7),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFFD54F), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Happy Mascot
            Image.asset(
              'assets/images/characters/BestScoreCharacter.png',
              height: 110,
              errorBuilder: (ctx, err, stack) => const Text('😸', style: TextStyle(fontSize: 60)),
            ),
            const SizedBox(height: 12),

            const Text(
              'CHIẾN THẮNG!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF4CAF50),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // Stars Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isAchieved = index < stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    isAchieved ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isAchieved ? const Color(0xFFFFB300) : Colors.grey[400],
                    size: 46,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),

            Text(
              'Số lượt di chuyển: $moves',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5D4037),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Next Level Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onNextLevel,
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
                label: const Text(
                  'MÀN KẾ TIẾP',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Level List / Home Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: onHome,
                icon: const Icon(Icons.list_alt_rounded, color: Color(0xFF5D4037)),
                label: const Text(
                  'DANH SÁCH MÀN',
                  style: TextStyle(color: Color(0xFF5D4037), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFBCAAA4), width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

