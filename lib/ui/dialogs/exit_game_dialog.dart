import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/game_popup_kit.dart';

class ExitGameDialog extends StatelessWidget {
  final VoidCallback? onExit;

  const ExitGameDialog({
    super.key,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return GamePopupFrame(
      title: 'EXIT GAME?',
      bannerPalette: GameButtonPalette.coral,
      maxWidth: 340,
      onClose: () => Navigator.of(context).pop(false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),

          // Mascot Showcase Medallion
          Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFC7F1FA),
                ],
              ),
              border: Border.all(color: const Color(0xFF66BFD4), width: 2.8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF15697D).withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/sprites/ui/Haru_sad.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.pets_rounded,
                size: 48,
                color: Color(0xFF26C6DA),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Ocean Message Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFD7F3FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF81CBE0), width: 1.8),
            ),
            child: const Text(
              'Bạn có chắc muốn rời bể cá và thoát trò chơi không?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'BrandonText',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF144E5E),
                height: 1.32,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Action Buttons: EXIT (Coral) & STAY (Lime Green)
          Row(
            children: [
              Expanded(
                child: Game3DButton(
                  label: 'EXIT',
                  icon: Icons.exit_to_app_rounded,
                  palette: GameButtonPalette.coral,
                  height: 50,
                  fontSize: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onTap: () {
                    Navigator.of(context).pop(true);
                    if (onExit != null) {
                      onExit!();
                    } else {
                      SystemNavigator.pop();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Game3DButton(
                  label: 'STAY',
                  icon: Icons.play_arrow_rounded,
                  palette: GameButtonPalette.green,
                  height: 50,
                  fontSize: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
