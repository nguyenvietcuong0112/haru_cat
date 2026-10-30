import 'package:flutter/material.dart';
import '../widgets/game_popup_kit.dart';

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
    return GamePopupFrame(
      title: 'VICTORY!',
      bannerPalette: GameButtonPalette.gold,
      maxWidth: 350,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),

          // Happy Mascot
          Image.asset(
            'assets/images/characters/BestScoreCharacter.png',
            height: 98,
            errorBuilder: (ctx, err, stack) =>
                const Text('😸', style: TextStyle(fontSize: 56)),
          ),
          const SizedBox(height: 10),

          // 3D Arcade Stars Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final isAchieved = index < stars;
              return Padding(
                padding: EdgeInsets.only(
                  left: 6,
                  right: 6,
                  bottom: index == 1 ? 8 : 0,
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: isAchieved
                      ? const Color(0xFFFFCA28)
                      : const Color(0xFFB0BEC5),
                  size: index == 1 ? 52 : 44,
                  shadows: [
                    Shadow(
                      color: isAchieved
                          ? const Color(0xFF8C5300)
                          : const Color(0xFF546E7A),
                      offset: const Offset(0, 3),
                      blurRadius: 1,
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 10),

          // Moves Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFD5F3FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF7EC3D6), width: 1.8),
            ),
            child: GameStrokedText(
              'MOVES: $moves',
              fontSize: 15,
              strokeColor: const Color(0xFF134B5A),
              strokeWidth: 3.6,
            ),
          ),
          const SizedBox(height: 18),

          // Next Level Button
          Game3DButton(
            label: 'NEXT LEVEL',
            icon: Icons.arrow_forward_rounded,
            palette: GameButtonPalette.green,
            height: 50,
            fontSize: 17.5,
            onTap: onNextLevel,
          ),
          const SizedBox(height: 10),

          // Level List Button
          Game3DButton(
            label: 'LEVELS',
            icon: Icons.grid_view_rounded,
            palette: GameButtonPalette.gold,
            height: 45,
            fontSize: 15.5,
            onTap: onHome,
          ),
        ],
      ),
    );
  }
}
