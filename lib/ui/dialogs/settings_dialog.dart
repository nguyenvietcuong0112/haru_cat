import 'package:flutter/material.dart';
import '../../audio/audio_manager.dart';
import '../../models/player_data.dart';
import '../widgets/game_popup_kit.dart';
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

    return GamePopupFrame(
      title: 'SETTINGS',
      bannerPalette: GameButtonPalette.aqua,
      onClose: () => Navigator.pop(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),

          // 1. 3D Sound & Haptics Medallions Panel
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFD5F3FA),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF7EC3D6), width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GameMedallionToggle(
                  icon: _audio.isBgmEnabled
                      ? Icons.music_note_rounded
                      : Icons.music_off_rounded,
                  label: 'MUSIC',
                  isActive: _audio.isBgmEnabled,
                  onTap: () async {
                    await _audio.toggleBgm();
                    _playerData.toggleMusic();
                    setState(() {});
                  },
                ),
                GameMedallionToggle(
                  icon: _audio.isSfxEnabled
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  label: 'SOUND',
                  isActive: _audio.isSfxEnabled,
                  onTap: () async {
                    await _audio.toggleSfx();
                    _playerData.toggleSound();
                    setState(() {});
                  },
                ),
                GameMedallionToggle(
                  icon: _playerData.vibrationEnabled
                      ? Icons.vibration_rounded
                      : Icons.mobile_off_rounded,
                  label: 'VIBRATE',
                  isActive: _playerData.vibrationEnabled,
                  onTap: () {
                    _audio.playClick();
                    _playerData.toggleVibration();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. 2x2 Chunky 3D Game Feature Buttons
          Row(
            children: [
              Expanded(
                child: _buildFeatureTile(
                  icon: Icons.collections_bookmark_rounded,
                  label: 'COLLECTION',
                  palette: GameButtonPalette.gold,
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (_) => const CharacterSelectDialog(),
                    );
                    if (mounted) setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFeatureTile(
                  icon: Icons.card_giftcard_rounded,
                  label: 'DAILY GIFT',
                  palette: GameButtonPalette.green,
                  hasBadge: canDaily,
                  badgeText: '!',
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (_) => const DailyRewardDialog(),
                    );
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildFeatureTile(
                  icon: Icons.stars_rounded,
                  label: 'LUCKY SPIN',
                  palette: GameButtonPalette.orange,
                  hasBadge: canSpin,
                  badgeText: 'FREE',
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (_) => const LuckyDrawDialog(),
                    );
                    if (mounted) setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFeatureTile(
                  icon: Icons.menu_book_rounded,
                  label: 'HOW TO PLAY',
                  palette: GameButtonPalette.aqua,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const HowToPlayDialog(),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String label,
    required GameButtonPalette palette,
    bool hasBadge = false,
    String badgeText = '!',
    required VoidCallback onTap,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Game3DButton(
          height: 62,
          borderRadius: 16,
          palette: palette,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 22,
                shadows: [
                  Shadow(
                    color: palette.textStroke,
                    offset: const Offset(0, 2),
                    blurRadius: 1,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              GameStrokedText(
                label,
                fontSize: 12.5,
                strokeColor: palette.textStroke,
                strokeWidth: 3.4,
                maxLines: 1,
              ),
            ],
          ),
        ),
        if (hasBadge)
          Positioned(
            top: -6,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFE53935)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: GameStrokedText(
                badgeText,
                fontSize: 10,
                strokeColor: const Color(0xFF631010),
                strokeWidth: 2.8,
              ),
            ),
          ),
      ],
    );
  }
}
