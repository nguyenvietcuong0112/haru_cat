import 'package:flutter/material.dart';
import '../../logic/game_controller.dart';
import '../../models/player_data.dart';
import '../../utils/constants.dart';
import '../dialogs/shop_dialog.dart';

class BoosterBar extends StatelessWidget {
  final GameController controller;

  const BoosterBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final playerData = PlayerData();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBoosterItem(
            context,
            type: GameConstants.boosterHammer,
            imageAsset: 'assets/images/sprites/boosters/booster_hammer.png',
            label: 'Hammer',
            count: playerData.getBoosterCount('hammer'),
            isSelected: controller.activeBooster == GameConstants.boosterHammer,
            onTap: () {
              if (playerData.getBoosterCount('hammer') > 0) {
                controller.selectBooster(GameConstants.boosterHammer);
              } else {
                showDialog(context: context, builder: (_) => const ShopDialog());
              }
            },
          ),
          _buildBoosterItem(
            context,
            type: GameConstants.boosterMagnet,
            imageAsset: 'assets/images/sprites/boosters/booster_magnet.png',
            label: 'Magnet',
            count: playerData.getBoosterCount('magnet'),
            isSelected: false,
            onTap: () {
              if (playerData.getBoosterCount('magnet') > 0) {
                controller.useMagnet();
              } else {
                showDialog(context: context, builder: (_) => const ShopDialog());
              }
            },
          ),
          _buildBoosterItem(
            context,
            type: GameConstants.boosterWand,
            imageAsset: 'assets/images/sprites/boosters/booster_magic_wand.png',
            label: 'Wand',
            count: playerData.getBoosterCount('wand'),
            isSelected: controller.activeBooster == GameConstants.boosterWand,
            onTap: () {
              if (playerData.getBoosterCount('wand') > 0) {
                controller.selectBooster(GameConstants.boosterWand);
              } else {
                showDialog(context: context, builder: (_) => const ShopDialog());
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBoosterItem(
    BuildContext context, {
    required String type,
    required String imageAsset,
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFD54F) : const Color(0xFFFFF8E1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.orange : const Color(0xFFD7CCC8),
                    width: isSelected ? 3 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? Colors.orange.withOpacity(0.5)
                          : Colors.black.withOpacity(0.12),
                      blurRadius: isSelected ? 8 : 4,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.flash_on, color: Colors.orange),
                ),
              ),

              // Quantity or Plus Badge
              Positioned(
                right: -4,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: count > 0 ? const Color(0xFFD32F2F) : Colors.green,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    count > 0 ? '$count' : '+',
                    style: const TextStyle(
                      fontFamily: 'BrandonText',
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'BrandonText',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4E342E),
            ),
          ),
        ],
      ),
    );
  }
}
