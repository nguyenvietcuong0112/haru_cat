import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../audio/audio_manager.dart';
import '../../models/player_data.dart';
import '../../logic/game_controller.dart';
import 'game_screen.dart';
import '../dialogs/settings_dialog.dart';
import '../dialogs/shop_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final AudioManager _audio = AudioManager();
  final PlayerData _playerData = PlayerData();

  late AnimationController _swimController;

  @override
  void initState() {
    super.initState();
    _playerData.init();
    _swimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _audio.playBgm();
  }

  @override
  void dispose() {
    _swimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _playerData,
      builder: (context, _) {
        return Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final btnWidth = (w * 0.46).clamp(160.0, 220.0);
              final btnHeight = btnWidth / 2.466;

              return SizedBox(
                width: w,
                height: h,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Background Underwater Scene
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/backgrounds/bg_home.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: const Color(0xFFCBEBFA)),
                      ),
                    ),

                    // 2. Animated Swimming Fish in Ambient Aquarium
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _swimController,
                        builder: (context, _) {
                          final t = _swimController.value * 2 * math.pi;

                          return Stack(
                            children: [
                              // Fish 1 (Top Center: Green 4-cell eel)
                              Positioned(
                                top: h * 0.285 + math.sin(t) * 4.0,
                                left: (w - (w * 0.68)) / 2 + math.cos(t * 0.8) * 3.0,
                                width: w * 0.68,
                                child: Transform.rotate(
                                  angle: math.sin(t) * 0.015,
                                  child: Image.asset(
                                    'assets/images/sprites/fish/fish_4cell_a.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                              // Fish 2 (Middle Left: Pink 3-cell fish)
                              Positioned(
                                top: h * 0.425 + math.sin(t + 1.2) * 4.0,
                                left: w * 0.02 + math.cos(t * 0.9 + 1.0) * 3.0,
                                width: w * 0.42,
                                child: Transform.rotate(
                                  angle: math.sin(t + 1.2) * 0.02,
                                  child: Image.asset(
                                    'assets/images/sprites/fish/fish_3cell_b.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                              // Fish 3 (Middle Right: Small Yellow 2-cell fish)
                              Positioned(
                                top: h * 0.425 + math.sin(t + 2.5) * 3.5,
                                right: w * 0.09 + math.cos(t + 2.0) * 3.0,
                                width: w * 0.20,
                                child: Transform.rotate(
                                  angle: math.sin(t + 2.5) * 0.025,
                                  child: Image.asset(
                                    'assets/images/sprites/fish/fish_2cell_a.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                              // Fish 4 (Lower Middle Right: Red 4-cell fish, flipped horizontally)
                              Positioned(
                                top: h * 0.525 + math.sin(t + 3.8) * 4.5,
                                right: w * 0.01 + math.cos(t * 0.7 + 3.0) * 4.0,
                                width: w * 0.56,
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
                                  child: Transform.rotate(
                                    angle: math.sin(t + 3.8) * 0.018,
                                    child: Image.asset(
                                      'assets/images/sprites/fish/fish_4cell_b.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),

                              // Fish 5 (Lower Left: Small Yellow 2-cell fish)
                              Positioned(
                                top: h * 0.605 + math.sin(t + 5.0) * 3.5,
                                left: w * 0.16 + math.cos(t + 4.5) * 3.0,
                                width: w * 0.24,
                                child: Transform.rotate(
                                  angle: math.sin(t + 5.0) * 0.02,
                                  child: Image.asset(
                                    'assets/images/sprites/fish/fish_2cell_a.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // 3. Top Header Bar: Silver Pill, Gold Pill (+), Settings Gear Button
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          child: Row(
                            children: [
                              // Silver Fish Pill
                              _buildSilverPill(),

                              const Spacer(),

                              // Gold Fish Pill (with green plus)
                              _buildGoldPill(context),

                              const SizedBox(width: 10),

                              // Settings Gear Button
                              _buildSettingsButton(context),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 4. Bottom Action Buttons: Play & Shop
                    Positioned(
                      bottom: (h * 0.09).clamp(50.0, 95.0),
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Play Button
                            _ScaleButton(
                              onTap: () async {
                                _audio.playClick();
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const GameScreen(mode: GameMode.endless),
                                  ),
                                );
                                if (mounted) setState(() {});
                              },
                              child: _buildPlayButton(width: btnWidth, height: btnHeight),
                            ),

                            SizedBox(height: (h * 0.016).clamp(10.0, 16.0)),

                            // Shop Button
                            _ScaleButton(
                              onTap: () {
                                _audio.playClick();
                                showDialog(
                                  context: context,
                                  builder: (_) => const ShopDialog(),
                                );
                              },
                              child: _buildShopButton(width: btnWidth, height: btnHeight),
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
        );
      },
    );
  }

  // --- Top Bar Widgets ---

  Widget _buildSilverPill() {
    return Container(
      constraints: const BoxConstraints(minWidth: 95, maxHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6DC4D8), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5AA5B8).withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/sprites/ui/coin-silver-8.png',
            width: 22,
            height: 22,
            errorBuilder: (_, __, ___) => const Icon(Icons.circle, size: 18, color: Colors.grey),
          ),
          const SizedBox(width: 5),
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Text(
              '${_playerData.silverFish}',
              style: const TextStyle(
                fontFamily: 'BrandonText',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Color(0xFF333333),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldPill(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _audio.playClick();
        showDialog(context: context, builder: (_) => const ShopDialog());
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 95, maxHeight: 34),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6DC4D8), width: 2.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5AA5B8).withOpacity(0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  'assets/images/sprites/ui/coin-gold-8.png',
                  width: 22,
                  height: 22,
                  errorBuilder: (_, __, ___) => const Icon(Icons.circle, size: 18, color: Colors.amber),
                ),
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 8, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 5),
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Text(
                '${_playerData.goldFish}',
                style: const TextStyle(
                  fontFamily: 'BrandonText',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF333333),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _audio.playClick();
        showDialog(context: context, builder: (_) => const SettingsDialog());
      },
      child: Image.asset(
        'assets/images/button/Btn_Settings.png',
        width: 38,
        height: 38,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFB3E5FC),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF6DC4D8), width: 2),
          ),
          child: const Icon(Icons.settings, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  // --- Bottom Button Widgets ---

  Widget _buildPlayButton({required double width, required double height}) {
    final fontSize = (width * 0.18).clamp(26.0, 36.0);

    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/button/Btn_Play.png'),
          fit: BoxFit.contain,
        ),
      ),
      alignment: const Alignment(0, -0.22),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dark green stroke outline
          Text(
            'Play',
            style: TextStyle(
              fontFamily: 'JandaManatee',
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 5.5
                ..color = const Color(0xFF265814),
              shadows: const [
                Shadow(
                  offset: Offset(0, 3),
                  blurRadius: 4,
                  color: Color(0xFF14300A),
                ),
              ],
            ),
          ),
          // White fill
          Text(
            'Play',
            style: TextStyle(
              fontFamily: 'JandaManatee',
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopButton({required double width, required double height}) {
    final fontSize = (width * 0.17).clamp(24.0, 34.0);

    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/button/Btn_Shop.png'),
          fit: BoxFit.contain,
        ),
      ),
      alignment: const Alignment(0, -0.22),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dark golden/brown stroke outline
          Text(
            'Shop',
            style: TextStyle(
              fontFamily: 'JandaManatee',
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 5.5
                ..color = const Color(0xFF6D4D0D),
              shadows: const [
                Shadow(
                  offset: Offset(0, 3),
                  blurRadius: 4,
                  color: Color(0xFF402D06),
                ),
              ],
            ),
          ),
          // White fill
          Text(
            'Shop',
            style: TextStyle(
              fontFamily: 'JandaManatee',
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive button with smooth scale feedback on tap
class _ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleButton({required this.child, required this.onTap});

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
