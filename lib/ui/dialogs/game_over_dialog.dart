import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/game_popup_kit.dart';

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
    'Mẹo: Quan sát hàng cá chuẩn bị ở đáy trước khi trượt!',
    'Mẹo: Ưu tiên dọn các chú cá lớn 3-4 ô để bể luôn thông thoáng!',
    'Mẹo: Xóa hàng liên hoàn từ trên xuống để nhân điểm Combo cực lớn!',
    'Mẹo: Búa Ốc có thể đập vỡ tảng băng chỉ trong 1 lần duy nhất!',
    'Mẹo: Thu thập hộp quà trong hàng để nhận Vàng, Bạc và Đạo cụ miễn phí!',
    'Mẹo: Đừng để cá Bom đếm ngược về 0 nếu không muốn bị thả thêm cá cản trở!',
  ];

  final String randomFact = funFacts[Random().nextInt(funFacts.length)];

  @override
  Widget build(BuildContext context) {
    final isNewRecord = score > 0 && score >= bestScore;

    return GamePopupFrame(
      title: 'GAME OVER',
      bannerPalette: GameButtonPalette.coral,
      maxWidth: 365,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Character Mascot
            Image.asset(
              'assets/images/characters/GameOverCharacter.png',
              height: 82,
              errorBuilder: (_, __, ___) =>
                  const Text('😿', style: TextStyle(fontSize: 46)),
            ),
            const SizedBox(height: 8),

            // Deep Ocean Score Plaque
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF15768D), Color(0xFF0B4A5A)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isNewRecord
                      ? const Color(0xFFFFD54F)
                      : const Color(0xFF6AD5E8),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF073440).withValues(alpha: 0.28),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const GameStrokedText(
                    'SCORE',
                    fontSize: 13,
                    fillColor: Color(0xFFFFE082),
                    strokeColor: Color(0xFF07303B),
                    strokeWidth: 3.2,
                  ),
                  const SizedBox(height: 2),
                  GameStrokedText(
                    '$score',
                    fontSize: 32,
                    fillColor: Colors.white,
                    strokeColor: const Color(0xFF062933),
                    strokeWidth: 5.5,
                  ),
                  if (isNewRecord)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFFF9800)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const GameStrokedText(
                        '★ NEW BEST! ★',
                        fontSize: 11.5,
                        strokeColor: Color(0xFF682C00),
                        strokeWidth: 3.0,
                      ),
                    ),
                  const SizedBox(height: 4),
                  GameStrokedText(
                    'BEST: $bestScore',
                    fontSize: 12.5,
                    fillColor: const Color(0xFFB2EBF2),
                    strokeColor: const Color(0xFF07303B),
                    strokeWidth: 3.0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 2x2 Ocean Stat Tiles
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    label: 'LINES',
                    value: '$linesCleared',
                    icon: Icons.waves_rounded,
                    iconColor: const Color(0xFF00ACC1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatTile(
                    label: 'SPECIAL',
                    value: '$specialBlocksCleared',
                    icon: Icons.auto_awesome_rounded,
                    iconColor: const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    label: 'MAX COMBO',
                    value: '${maxCombo}x',
                    icon: Icons.local_fire_department_rounded,
                    iconColor: const Color(0xFFFF5252),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatTile(
                    label: 'SILVER',
                    value: '+$silverEarned',
                    assetIcon: 'assets/images/sprites/ui/coin-silver-8.png',
                    icon: Icons.monetization_on_rounded,
                    iconColor: const Color(0xFF26A69A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Ocean Tip Scroll Plaque
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD7F4FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF81CBE0), width: 1.6),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/sprites/ui/tag_fun_fact.png',
                    width: 26,
                    height: 26,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.lightbulb_rounded,
                      color: Color(0xFFFFB300),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      randomFact,
                      style: const TextStyle(
                        fontFamily: 'BrandonText',
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF175363),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons
            Game3DButton(
              label: 'PLAY AGAIN',
              icon: Icons.replay_rounded,
              palette: GameButtonPalette.green,
              height: 50,
              fontSize: 18,
              onTap: onReplay,
            ),
            const SizedBox(height: 9),
            Game3DButton(
              label: 'HOME',
              icon: Icons.home_rounded,
              palette: GameButtonPalette.gold,
              height: 45,
              fontSize: 15.5,
              onTap: onHome,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    String? assetIcon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF83C7D9), width: 1.8),
      ),
      child: Row(
        children: [
          if (assetIcon != null)
            Image.asset(
              assetIcon,
              width: 22,
              height: 22,
              errorBuilder: (_, __, ___) => Icon(icon, size: 20, color: iconColor),
            )
          else
            Icon(icon, size: 21, color: iconColor),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'BrandonText',
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E7888),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GameStrokedText(
                    value,
                    fontSize: 14,
                    strokeColor: const Color(0xFF134B5A),
                    strokeWidth: 3.2,
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
