import 'package:flutter/material.dart';
import '../../models/player_data.dart';
import '../../audio/audio_manager.dart';
import '../widgets/game_popup_kit.dart';

class DailyRewardDialog extends StatefulWidget {
  const DailyRewardDialog({super.key});

  @override
  State<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<DailyRewardDialog> {
  final PlayerData _playerData = PlayerData();
  final AudioManager _audio = AudioManager();
  Map<String, int>? _justClaimed;

  final List<Map<String, dynamic>> _rewards = [
    {'day': 1, 'silver': 100, 'gold': 0, 'item': '100 Bạc'},
    {'day': 2, 'silver': 150, 'gold': 2, 'item': '150 Bạc + 2 Vàng'},
    {'day': 3, 'silver': 200, 'gold': 0, 'hammer': 1, 'item': '200 Bạc + 1 Búa'},
    {'day': 4, 'silver': 250, 'gold': 5, 'item': '250 Bạc + 5 Vàng'},
    {'day': 5, 'silver': 300, 'gold': 0, 'net': 1, 'item': '300 Bạc + 1 Vợt'},
    {'day': 6, 'silver': 350, 'gold': 5, 'wand': 1, 'item': '350 Bạc + 5 Vàng + 1 Đũa'},
    {
      'day': 7,
      'silver': 500,
      'gold': 15,
      'hammer': 2,
      'magnet': 2,
      'wand': 2,
      'item': 'KHO BÁU ĐẠI DƯƠNG: 500 Bạc + 15 Vàng + Trọn bộ Đạo cụ!'
    },
  ];

  void _claim() {
    _audio.playBooster();
    final reward = _playerData.claimDailyReward();
    setState(() {
      _justClaimed = reward;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentDay = _playerData.dailyRewardDay;
    final canClaim = _playerData.canClaimDailyReward();

    return GamePopupFrame(
      title: 'DAILY GIFT',
      bannerPalette: GameButtonPalette.green,
      maxWidth: 380,
      onClose: () => Navigator.pop(context),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/sprites/ui/Haru_Daily_popup.png',
              height: 66,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.card_giftcard_rounded,
                size: 48,
                color: Color(0xFFFF9800),
              ),
            ),
            const SizedBox(height: 6),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFD5F3FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Điểm danh mỗi ngày để nhận kho báu đại dương!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'BrandonText',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF155363),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 7 Days Grid: 2 rows of 3 + full-width Day 7 Chest
            LayoutBuilder(
              builder: (context, constraints) {
                final cardW = ((constraints.maxWidth - 16) / 3).floorToDouble();
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (int i = 0; i < 6; i++)
                      _buildDayCard(
                        day: i + 1,
                        width: cardW,
                        rewardText: _rewards[i]['item'] as String,
                        isClaimed:
                            (i + 1) < currentDay || ((i + 1) == currentDay && !canClaim),
                        isToday: (i + 1) == currentDay && canClaim,
                        isFullWidth: false,
                      ),
                    _buildDayCard(
                      day: 7,
                      width: constraints.maxWidth,
                      rewardText: _rewards[6]['item'] as String,
                      isClaimed: currentDay > 7 || (currentDay == 7 && !canClaim),
                      isToday: currentDay == 7 && canClaim,
                      isFullWidth: true,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),

            if (_justClaimed != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF66BB6A), width: 1.8),
                ),
                child: const GameStrokedText(
                  'NHẬN QUÀ THÀNH CÔNG!',
                  fontSize: 13,
                  strokeColor: Color(0xFF1B5E20),
                  strokeWidth: 3.2,
                ),
              ),
              const SizedBox(height: 10),
            ],

            Game3DButton(
              label: canClaim ? 'CLAIM GIFT!' : 'CLAIMED TODAY',
              icon: canClaim ? Icons.redeem_rounded : Icons.check_circle_rounded,
              palette: canClaim ? GameButtonPalette.green : GameButtonPalette.slate,
              height: 50,
              fontSize: 17.5,
              onTap: canClaim ? _claim : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard({
    required int day,
    required double width,
    required String rewardText,
    required bool isClaimed,
    required bool isToday,
    required bool isFullWidth,
  }) {
    final bgGradient = isToday
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF6D6), Color(0xFFFFE082)],
          )
        : isClaimed
            ? const LinearGradient(
                colors: [Color(0xFFDCEBF0), Color(0xFFC8DFE6)],
              )
            : const LinearGradient(
                colors: [Colors.white, Color(0xFFEAF8FC)],
              );

    final borderColor = isToday
        ? const Color(0xFFFF9800)
        : isClaimed
            ? const Color(0xFF90B4C0)
            : const Color(0xFF81C6D8);

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: 6,
        vertical: isFullWidth ? 9 : 7,
      ),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor, width: isToday ? 2.5 : 1.8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFFFF9800) : const Color(0xFF39A9BE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: GameStrokedText(
              'DAY $day',
              fontSize: 11,
              strokeColor:
                  isToday ? const Color(0xFF682C00) : const Color(0xFF104957),
              strokeWidth: 2.8,
            ),
          ),
          const SizedBox(height: 6),
          if (isClaimed)
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF43A047),
              size: 26,
            )
          else if (isFullWidth)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/sprites/ui/coin-gold-8.png', width: 24, height: 24),
                const SizedBox(width: 6),
                Image.asset('assets/images/sprites/ui/coin-silver-8.png', width: 24, height: 24),
                const SizedBox(width: 6),
                Image.asset(
                  'assets/images/sprites/boosters/booster_hammer.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.auto_awesome, color: Colors.orange, size: 22),
                ),
              ],
            )
          else
            Image.asset(
              day % 2 == 0
                  ? 'assets/images/sprites/ui/coin-gold-8.png'
                  : 'assets/images/sprites/ui/coin-silver-8.png',
              width: 25,
              height: 25,
            ),
          const SizedBox(height: 5),
          Text(
            rewardText,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'BrandonText',
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF174F5E),
            ),
          ),
        ],
      ),
    );
  }
}
