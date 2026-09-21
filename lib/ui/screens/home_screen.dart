import 'package:flutter/material.dart';
import '../../audio/audio_manager.dart';
import '../../models/player_data.dart';
import '../../logic/game_controller.dart';
import '../dialogs/daily_reward_dialog.dart';
import '../dialogs/lucky_draw_dialog.dart';
import '../dialogs/character_select_dialog.dart';
import '../dialogs/shop_dialog.dart';
import '../dialogs/how_to_play_dialog.dart';
import '../dialogs/pause_dialog.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final AudioManager _audio = AudioManager();
  final PlayerData _playerData = PlayerData();

  late AnimationController _animController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _playerData.init();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _audio.playBgm();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _playerData,
      builder: (context, _) {
        final currentChar = _playerData.currentCharacter;
        final canDaily = _playerData.canClaimDailyReward();
        final canSpin = _playerData.canFreeSpin();

        return Scaffold(
          body: Stack(
            children: [
              // Background Wallpaper
              Positioned.fill(
                child: Image.asset(
                  'assets/images/backgrounds/bg_ingame.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF3E5D8)),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // Top Bar: Settings, Silver Fish, Gold Fish
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Settings Button
                          _buildCircleButton(
                            icon: Icons.settings_rounded,
                            onTap: () {
                              _audio.playClick();
                              showDialog(
                                context: context,
                                builder: (_) => PauseDialog(
                                  onResume: () => Navigator.pop(context),
                                  onRestart: () => Navigator.pop(context),
                                  onHome: () => Navigator.pop(context),
                                ),
                              );
                            },
                          ),

                          // Currency Wallets
                          Row(
                            children: [
                              // Silver Fish
                              _buildCurrencyChip(
                                iconAsset: 'assets/images/sprites/ui/coin-silver-8.png',
                                amount: '${_playerData.silverFish}',
                                onTap: () {
                                  _audio.playClick();
                                  showDialog(context: context, builder: (_) => const ShopDialog());
                                },
                              ),
                              const SizedBox(width: 8),

                              // Gold Fish
                              _buildCurrencyChip(
                                iconAsset: 'assets/images/sprites/ui/coin-gold-8.png',
                                amount: '${_playerData.goldFish}',
                                onTap: () {
                                  _audio.playClick();
                                  showDialog(context: context, builder: (_) => const ShopDialog());
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 1),

                    // Game Logo
                    Image.asset(
                      'assets/images/logo/logo.png',
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Text(
                        'HARU CATS',
                        style: TextStyle(
                          fontFamily: 'JandaManatee',
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Mascot with Speech Bubble
                    Stack(
                      alignment: Alignment.topCenter,
                      clipBehavior: Clip.none,
                      children: [
                        // Speech bubble
                        Positioned(
                          top: -30,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFD6A266), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Meow! Welcome back!',
                              style: const TextStyle(
                                fontFamily: 'BrandonText',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6B4226),
                              ),
                            ),
                          ),
                        ),

                        // Animated Mascot
                        AnimatedBuilder(
                          animation: _bounceAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _bounceAnimation.value),
                              child: child,
                            );
                          },
                          child: Image.asset(
                            currentChar.imageAsset,
                            height: 130,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.pets,
                              size: 90,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // High Score Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D4037),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD54F), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'BEST: ${_playerData.bestScore}',
                            style: const TextStyle(
                              fontFamily: 'JandaManatee',
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 1),

                    // Primary Play Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          // PLAY ENDLESS
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                _audio.playClick();
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const GameScreen(mode: GameMode.endless),
                                  ),
                                );
                                setState(() {});
                              },
                              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                              label: const Text(
                                'PLAY ENDLESS',
                                style: TextStyle(
                                  fontFamily: 'JandaManatee',
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF9800),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                elevation: 5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // LEVEL SELECT
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _audio.playClick();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LevelSelectScreen()),
                                );
                              },
                              icon: const Icon(Icons.map_rounded, color: Colors.white, size: 22),
                              label: const Text(
                                'LEVEL SELECT',
                                style: TextStyle(
                                  fontFamily: 'JandaManatee',
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                elevation: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 1),

                    // Bottom Meta Navigation Bar: Daily, Lucky, Characters, Shop, How To Play
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9EE),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFD6A266), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Daily Reward
                          _buildBottomMenuItem(
                            icon: Icons.calendar_month_rounded,
                            label: 'Daily',
                            hasBadge: canDaily,
                            badgeText: '!',
                            onTap: () {
                              _audio.playClick();
                              showDialog(context: context, builder: (_) => const DailyRewardDialog());
                            },
                          ),

                          // Lucky Draw
                          _buildBottomMenuItem(
                            icon: Icons.rotate_right_rounded,
                            label: 'Lucky',
                            hasBadge: canSpin,
                            badgeText: 'FREE',
                            onTap: () {
                              _audio.playClick();
                              showDialog(context: context, builder: (_) => const LuckyDrawDialog());
                            },
                          ),

                          // Characters
                          _buildBottomMenuItem(
                            icon: Icons.pets_rounded,
                            label: 'Costume',
                            hasBadge: false,
                            onTap: () {
                              _audio.playClick();
                              showDialog(context: context, builder: (_) => const CharacterSelectDialog());
                            },
                          ),

                          // Shop
                          _buildBottomMenuItem(
                            icon: Icons.storefront_rounded,
                            label: 'Shop',
                            hasBadge: false,
                            onTap: () {
                              _audio.playClick();
                              showDialog(context: context, builder: (_) => const ShopDialog());
                            },
                          ),

                          // How To Play
                          _buildBottomMenuItem(
                            icon: Icons.help_outline_rounded,
                            label: 'Rules',
                            hasBadge: false,
                            onTap: () {
                              _audio.playClick();
                              showDialog(context: context, builder: (_) => const HowToPlayDialog());
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E7),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD6A266), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF5D4037), size: 22),
      ),
    );
  }

  Widget _buildCurrencyChip({
    required String iconAsset,
    required String amount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD6A266), width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconAsset,
              width: 20,
              height: 20,
              errorBuilder: (_, __, ___) => const Icon(Icons.circle, size: 16, color: Colors.amber),
            ),
            const SizedBox(width: 4),
            Text(
              amount,
              style: const TextStyle(
                fontFamily: 'JandaManatee',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.add_circle, size: 14, color: Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomMenuItem({
    required IconData icon,
    required String label,
    required bool hasBadge,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.orange.shade800, size: 22),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'BrandonText',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4226),
                ),
              ),
            ],
          ),
          if (hasBadge)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText ?? '!',
                  style: const TextStyle(
                    fontFamily: 'BrandonText',
                    fontSize: 9,
                    color: Colors.white,
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
