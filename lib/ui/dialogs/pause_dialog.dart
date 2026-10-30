import 'package:flutter/material.dart';
import '../../audio/audio_manager.dart';
import '../../models/player_data.dart';
import '../widgets/game_popup_kit.dart';
import 'how_to_play_dialog.dart';

class PauseDialog extends StatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  const PauseDialog({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onHome,
  });

  @override
  State<PauseDialog> createState() => _PauseDialogState();
}

class _PauseDialogState extends State<PauseDialog> {
  final AudioManager _audio = AudioManager();
  final PlayerData _playerData = PlayerData();

  @override
  Widget build(BuildContext context) {
    return GamePopupFrame(
      title: 'PAUSED',
      bannerPalette: GameButtonPalette.aqua,
      maxWidth: 345,
      onClose: widget.onResume,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),

          // Sound & Vibrate 3D Medallions
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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
          const SizedBox(height: 16),

          // Resume Button (Lime Green like Play)
          Game3DButton(
            label: 'RESUME',
            icon: Icons.play_arrow_rounded,
            palette: GameButtonPalette.green,
            height: 50,
            fontSize: 18,
            onTap: widget.onResume,
          ),
          const SizedBox(height: 10),

          // Restart Button (Arcade Orange)
          Game3DButton(
            label: 'RESTART',
            icon: Icons.refresh_rounded,
            palette: GameButtonPalette.orange,
            height: 48,
            fontSize: 16.5,
            onTap: widget.onRestart,
          ),
          const SizedBox(height: 10),

          // How To Play & Home Row
          Row(
            children: [
              Expanded(
                child: Game3DButton(
                  label: 'RULES',
                  icon: Icons.menu_book_rounded,
                  palette: GameButtonPalette.aqua,
                  height: 46,
                  fontSize: 14.5,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const HowToPlayDialog(),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Game3DButton(
                  label: 'HOME',
                  icon: Icons.home_rounded,
                  palette: GameButtonPalette.gold,
                  height: 46,
                  fontSize: 14.5,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onTap: widget.onHome,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
