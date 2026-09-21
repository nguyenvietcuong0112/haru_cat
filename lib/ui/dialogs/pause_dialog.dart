import 'package:flutter/material.dart';
import '../../audio/audio_manager.dart';
import '../../models/player_data.dart';
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9EE),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFD6A266), width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAUSED',
              style: TextStyle(
                fontFamily: 'JandaManatee',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4226),
              ),
            ),
            const SizedBox(height: 18),

            // Sound Toggles Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
            const SizedBox(height: 16),

            // How To Play Button
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const HowToPlayDialog(),
                );
              },
              icon: const Icon(Icons.help_outline_rounded, color: Colors.orange, size: 20),
              label: const Text(
                'How To Play Rules',
                style: TextStyle(
                  fontFamily: 'BrandonText',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4226),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Resume Button
            _buildActionButton(
              label: 'RESUME GAME',
              color: const Color(0xFF4CAF50),
              icon: Icons.play_arrow_rounded,
              onTap: widget.onResume,
            ),
            const SizedBox(height: 10),

            // Restart Button
            _buildActionButton(
              label: 'RESTART',
              color: const Color(0xFFFF9800),
              icon: Icons.refresh_rounded,
              onTap: widget.onRestart,
            ),
            const SizedBox(height: 10),

            // Home Button
            _buildActionButton(
              label: 'MAIN MENU',
              color: const Color(0xFF8D6E63),
              icon: Icons.home_rounded,
              onTap: widget.onHome,
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFFD54F) : const Color(0xFFE0E0E0),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: isActive ? const Color(0xFF5D4037) : Colors.grey, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'BrandonText',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'JandaManatee',
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 3,
        ),
      ),
    );
  }
}
