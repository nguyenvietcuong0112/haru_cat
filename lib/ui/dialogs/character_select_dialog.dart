import 'package:flutter/material.dart';
import '../../models/player_data.dart';
import '../../audio/audio_manager.dart';
import '../widgets/game_popup_kit.dart';

class CharacterSelectDialog extends StatefulWidget {
  const CharacterSelectDialog({super.key});

  @override
  State<CharacterSelectDialog> createState() => _CharacterSelectDialogState();
}

class _CharacterSelectDialogState extends State<CharacterSelectDialog> {
  final PlayerData _playerData = PlayerData();
  final AudioManager _audio = AudioManager();

  @override
  Widget build(BuildContext context) {
    return GamePopupFrame(
      title: 'COLLECTION',
      bannerPalette: GameButtonPalette.gold,
      maxWidth: 385,
      maxHeight: 545,
      onClose: () => Navigator.pop(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gold Wallet Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GameWalletPill(
                iconAsset: 'assets/images/sprites/ui/coin-gold-8.png',
                amount: '${_playerData.goldFish}',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Character List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: PlayerData.allCharacters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final char = PlayerData.allCharacters[index];
                final isUnlocked = _playerData.unlockedCharacters.contains(char.id);
                final isSelected = _playerData.selectedCharacter == char.id;

                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFFFFF8DC), Color(0xFFFFECB3)],
                          )
                        : const LinearGradient(
                            colors: [Colors.white, Color(0xFFF2FBFE)],
                          ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFFB300)
                          : const Color(0xFF83C7D9),
                      width: isSelected ? 2.5 : 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF145466).withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Character Avatar Medallion
                      Container(
                        width: 58,
                        height: 58,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFF3C4)
                              : const Color(0xFFD8F4FA),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFFCA28)
                                : const Color(0xFF7AC2D5),
                            width: 1.8,
                          ),
                        ),
                        child: Image.asset(
                          char.imageAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.pets_rounded,
                            color: Color(0xFF00ACC1),
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Character Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: GameStrokedText(
                                char.name,
                                fontSize: 15.5,
                                strokeColor: const Color(0xFF144E5E),
                                strokeWidth: 3.6,
                                textAlign: TextAlign.left,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F7FA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                char.skillTitle,
                                style: const TextStyle(
                                  fontFamily: 'BrandonText',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00798C),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              char.skillDescription,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'BrandonText',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF386F7E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 3D Action Button
                      if (isSelected)
                        const Game3DButton(
                          width: 82,
                          height: 38,
                          borderRadius: 13,
                          label: 'USED',
                          fontSize: 12.5,
                          palette: GameButtonPalette.green,
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          onTap: null,
                        )
                      else if (isUnlocked)
                        Game3DButton(
                          width: 82,
                          height: 38,
                          borderRadius: 13,
                          label: 'SELECT',
                          fontSize: 12.5,
                          palette: GameButtonPalette.aqua,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          onTap: () {
                            setState(() {
                              _playerData.selectCharacter(char.id);
                            });
                          },
                        )
                      else
                        Game3DButton(
                          width: 82,
                          height: 38,
                          borderRadius: 13,
                          palette: GameButtonPalette.orange,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          onTap: () {
                            if (_playerData.unlockCharacter(char.id)) {
                              _audio.playBooster();
                              setState(() {});
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: const Color(0xFFD32F2F),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  content: const Text(
                                    'Not enough Gold! Visit the Shop to get more.',
                                    style: TextStyle(
                                      fontFamily: 'BrandonText',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/sprites/ui/coin-gold-8.png',
                                width: 16,
                                height: 16,
                              ),
                              const SizedBox(width: 4),
                              GameStrokedText(
                                '${char.unlockCostGold}',
                                fontSize: 13.5,
                                strokeColor: GameButtonPalette.orange.textStroke,
                                strokeWidth: 3.4,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
