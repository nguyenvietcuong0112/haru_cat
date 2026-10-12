import 'package:flutter/material.dart';
import '../../audio/audio_manager.dart';
import '../../models/player_data.dart';
import 'character_select_dialog.dart';
import 'daily_reward_dialog.dart';
import 'lucky_draw_dialog.dart';
import 'how_to_play_dialog.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final AudioManager _audio = AudioManager();
  final PlayerData _playerData = PlayerData();

  @override
  Widget build(BuildContext context) {
    final canDaily = _playerData.canClaimDailyReward();
    final canSpin = _playerData.canFreeSpin();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9EE),
          borderRadius: BorderRadius.circular(28),
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
            // Header Row: Title & Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 32),
                const Text(
                  'SETTINGS',
                  style: TextStyle(
                    fontFamily: 'JandaManatee',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B4226),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _audio.playClick();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF6B4226)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sound Toggles
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE8D5B5), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildToggleButton(
                    icon: _audio.isBgmEnabled ? Icons.music_note_rounded : Icons.music_off_rounded,
                    label: 'Music',
                    isActive: _audio.isBgmEnabled,
                    onTap: () async {
                      await _audio.toggleBgm();
                      _playerData.toggleMusic();
                      setState(() {});
                    },
                  ),
                  _buildToggleButton(
                    icon: _audio.isSfxEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    label: 'Sound',
                    isActive: _audio.isSfxEnabled,
                    onTap: () async {
                      await _audio.toggleSfx();
                      _playerData.toggleSound();
                      setState(() {});
                    },
                  ),
                  _buildToggleButton(
                    icon: _playerData.vibrationEnabled ? Icons.vibration_rounded : Icons.mobile_off_rounded,
                    label: 'Vibrate',
                    isActive: _playerData.vibrationEnabled,
                    onTap: () {
                      _playerData.toggleVibration();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Navigation Grid: Collection, Daily, Lucky, Rules
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.pets_rounded,
                    label: 'Collection',
                    color: const Color(0xFFFF9800),
                    onTap: () {
                      _audio.playClick();
                      showDialog(context: context, builder: (_) => const CharacterSelectDialog());
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.calendar_month_rounded,
                    label: 'Daily',
                    color: const Color(0xFF4CAF50),
                    hasBadge: canDaily,
                    onTap: () {
                      _audio.playClick();
                      showDialog(context: context, builder: (_) => const DailyRewardDialog());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.rotate_right_rounded,
                    label: 'Lucky Spin',
                    color: const Color(0xFF9C27B0),
                    hasBadge: canSpin,
                    badgeText: 'FREE',
                    onTap: () {
                      _audio.playClick();
                      showDialog(context: context, builder: (_) => const LuckyDrawDialog());
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.help_outline_rounded,
                    label: 'How To Play',
                    color: const Color(0xFF2196F3),
                    onTap: () {
                      _audio.playClick();
                      showDialog(context: context, builder: (_) => const HowToPlayDialog());
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFF9800) : Colors.grey.shade300,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isActive ? const Color(0xFFFF9800) : Colors.grey).withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'BrandonText',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? const Color(0xFF6B4226) : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    bool hasBadge = false,
    String badgeText = '!',
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'BrandonText',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color.withOpacity(0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasBadge)
            Positioned(
              top: -4,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
