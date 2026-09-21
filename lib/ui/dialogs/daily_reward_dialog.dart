import 'package:flutter/material.dart';
import '../../models/player_data.dart';
import '../../audio/audio_manager.dart';

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
    {'day': 1, 'silver': 100, 'gold': 0, 'item': '100 Silver'},
    {'day': 2, 'silver': 150, 'gold': 2, 'item': '150 Silver + 2 Gold'},
    {'day': 3, 'silver': 200, 'gold': 0, 'hammer': 1, 'item': '200 Silver + 1 Hammer'},
    {'day': 4, 'silver': 250, 'gold': 5, 'item': '250 Silver + 5 Gold'},
    {'day': 5, 'silver': 300, 'gold': 0, 'magnet': 1, 'item': '300 Silver + 1 Magnet'},
    {'day': 6, 'silver': 350, 'gold': 5, 'wand': 1, 'item': '350 Silver + 5 Gold + 1 Wand'},
    {'day': 7, 'silver': 500, 'gold': 15, 'hammer': 2, 'magnet': 2, 'wand': 2, 'item': 'JACKPOT! 500 Silver + 15 Gold + Boosters!'},
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

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9EE),
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
            // Header with Haru
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 32),
                const Text(
                  'DAILY REWARD',
                  style: TextStyle(
                    fontFamily: 'JandaManatee',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B4226),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF6B4226)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Image.asset(
              'assets/images/sprites/ui/Haru_Daily_popup.png',
              height: 70,
              errorBuilder: (_, __, ___) => const Icon(Icons.card_giftcard, size: 50, color: Colors.orange),
            ),
            const SizedBox(height: 8),

            const Text(
              'Come back everyday to earn special gifts!',
              style: TextStyle(
                fontFamily: 'BrandonText',
                fontSize: 13,
                color: Color(0xFF8B5A2B),
              ),
            ),
            const SizedBox(height: 16),

            // 7 Days Grid: 3 rows (Day 1-3, Day 4-6, Day 7 spanning full width)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (int i = 0; i < 6; i++)
                  _buildDayCard(
                    day: i + 1,
                    rewardText: _rewards[i]['item'],
                    isClaimed: (i + 1) < currentDay || ((i + 1) == currentDay && !canClaim),
                    isToday: (i + 1) == currentDay,
                    isFullWidth: false,
                  ),
                _buildDayCard(
                  day: 7,
                  rewardText: _rewards[6]['item'],
                  isClaimed: currentDay > 7 || (currentDay == 7 && !canClaim),
                  isToday: currentDay == 7,
                  isFullWidth: true,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Claim feedback or button
            if (_justClaimed != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: const Text(
                  '🎉 Rewards claimed successfully! Enjoy!',
                  style: TextStyle(
                    fontFamily: 'BrandonText',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Claim Button
            GestureDetector(
              onTap: canClaim ? _claim : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: canClaim
                      ? const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFF57C00)])
                      : LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: canClaim
                      ? [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    canClaim ? 'CLAIM REWARD' : 'CLAIMED FOR TODAY',
                    style: const TextStyle(
                      fontFamily: 'JandaManatee',
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard({
    required int day,
    required String rewardText,
    required bool isClaimed,
    required bool isToday,
    required bool isFullWidth,
  }) {
    return Container(
      width: isFullWidth ? 310 : 96,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isToday
            ? const Color(0xFFFFF0D4)
            : isClaimed
                ? Colors.grey.shade200
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? Colors.orange : Colors.amber.shade200,
          width: isToday ? 2.5 : 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Day $day',
            style: TextStyle(
              fontFamily: 'JandaManatee',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.orange.shade800 : const Color(0xFF6B4226),
            ),
          ),
          const SizedBox(height: 4),
          if (isClaimed)
            const Icon(Icons.check_circle, color: Colors.green, size: 24)
          else if (isFullWidth)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/sprites/ui/coin-gold-8.png', width: 22, height: 22),
                const SizedBox(width: 4),
                Image.asset('assets/images/sprites/ui/coin-silver-8.png', width: 22, height: 22),
                const SizedBox(width: 4),
                const Icon(Icons.card_giftcard, color: Colors.purple, size: 22),
              ],
            )
          else
            Image.asset(
              day % 2 == 0
                  ? 'assets/images/sprites/ui/coin-gold-8.png'
                  : 'assets/images/sprites/ui/coin-silver-8.png',
              width: 24,
              height: 24,
            ),
          const SizedBox(height: 4),
          Text(
            rewardText,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'BrandonText',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B5A2B),
            ),
          ),
        ],
      ),
    );
  }
}
