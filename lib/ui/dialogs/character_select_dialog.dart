import 'package:flutter/material.dart';
import '../../models/player_data.dart';
import '../../audio/audio_manager.dart';

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
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Gold display
                Row(
                  children: [
                    Image.asset('assets/images/sprites/ui/coin-gold-8.png', width: 22, height: 22),
                    const SizedBox(width: 4),
                    Text(
                      '${_playerData.goldFish}',
                      style: const TextStyle(
                        fontFamily: 'JandaManatee',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B4226),
                      ),
                    ),
                  ],
                ),
                const Text(
                  'CHARACTERS',
                  style: TextStyle(
                    fontFamily: 'JandaManatee',
                    fontSize: 20,
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
            const SizedBox(height: 12),

            // Character List
            Expanded(
              child: ListView.separated(
                itemCount: PlayerData.allCharacters.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final char = PlayerData.allCharacters[index];
                  final isUnlocked = _playerData.unlockedCharacters.contains(char.id);
                  final isSelected = _playerData.selectedCharacter == char.id;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFFF0D4) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? Colors.orange : const Color(0xFFE2C4A2),
                        width: isSelected ? 2.5 : 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 60,
                          height: 60,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF0E6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Image.asset(
                            char.imageAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.pets,
                              color: Colors.orange,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                char.name,
                                style: const TextStyle(
                                  fontFamily: 'JandaManatee',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B4226),
                                ),
                              ),
                              Text(
                                char.skillTitle,
                                style: const TextStyle(
                                  fontFamily: 'BrandonText',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              ),
                              Text(
                                char.skillDescription,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'BrandonText',
                                  fontSize: 11,
                                  color: Colors.brown.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Action Button
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'SELECTED',
                              style: TextStyle(
                                fontFamily: 'BrandonText',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        else if (isUnlocked)
                          GestureDetector(
                            onTap: () {
                              _audio.playClick();
                              setState(() {
                                _playerData.selectCharacter(char.id);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'SELECT',
                                style: TextStyle(
                                  fontFamily: 'BrandonText',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () {
                              _audio.playClick();
                              if (_playerData.unlockCharacter(char.id)) {
                                _audio.playBooster();
                                setState(() {});
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Not enough Gold Fish! Visit the Shop to exchange.'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B4226),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset('assets/images/sprites/ui/coin-gold-8.png', width: 16, height: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${char.unlockCostGold}',
                                    style: const TextStyle(
                                      fontFamily: 'BrandonText',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
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
      ),
    );
  }
}
