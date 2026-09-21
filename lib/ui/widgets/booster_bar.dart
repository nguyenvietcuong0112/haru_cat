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

  void _onBoosterTapped(
    BuildContext context, {
    required PlayerData playerData,
    required String boosterKey,
    required String boosterType,
    required String label,
    required String imageAsset,
  }) {
    if (playerData.getBoosterCount(boosterKey) > 0) {
      if (boosterKey == 'wand') {
        controller.useWand();
      } else {
        controller.selectBooster(boosterType);
      }
    } else {
      _showQuickBuyDialog(
        context,
        playerData: playerData,
        boosterKey: boosterKey,
        boosterType: boosterType,
        label: label,
        imageAsset: imageAsset,
      );
    }
  }

  void _showQuickBuyDialog(
    BuildContext context, {
    required PlayerData playerData,
    required String boosterKey,
    required String boosterType,
    required String label,
    required String imageAsset,
  }) {
    const int goldCost = 3;
    final bool canAfford = playerData.goldFish >= goldCost;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9EE),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD6A266), width: 3),
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
              // Icon
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFB300), width: 2),
                ),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.flash_on, color: Colors.orange, size: 36),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                'MUA $label'.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'JandaManatee',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4226),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Bạn đã dùng hết $label.\nMua 1 cái với giá $goldCost Vàng để tiếp tục dùng ngay?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'BrandonText',
                  fontSize: 13,
                  color: Colors.brown.shade600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),

              // Current Gold Status
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Vàng hiện có: ',
                    style: TextStyle(
                      fontFamily: 'BrandonText',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade700,
                    ),
                  ),
                  Image.asset('assets/images/sprites/ui/coin-gold-8.png', width: 18, height: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${playerData.goldFish}',
                    style: const TextStyle(
                      fontFamily: 'JandaManatee',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4226),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Buttons
              if (canAfford) ...[
                GestureDetector(
                  onTap: () {
                    if (playerData.spendGoldFish(goldCost)) {
                      playerData.addBooster(boosterKey, 1);
                      Navigator.pop(ctx);
                      if (boosterKey == 'wand') {
                        controller.useWand();
                      } else {
                        controller.selectBooster(boosterType);
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB300), Color(0xFFF57C00)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Mua & Dùng Ngay (',
                          style: TextStyle(
                            fontFamily: 'JandaManatee',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        Image.asset('assets/images/sprites/ui/coin-gold-8.png', width: 16, height: 16),
                        Text(
                          ' $goldCost)',
                          style: const TextStyle(
                            fontFamily: 'JandaManatee',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(context: context, builder: (_) => const ShopDialog());
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Không đủ Vàng - Đến Cửa Hàng',
                        style: TextStyle(
                          fontFamily: 'JandaManatee',
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Đóng',
                  style: TextStyle(
                    fontFamily: 'BrandonText',
                    fontSize: 14,
                    color: Colors.brown.shade400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PlayerData(),
      builder: (context, _) {
        final playerData = PlayerData();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 3. Hammer (Búa ốc xà cừ - Phá băng 1 hit)
              _buildBoosterItem(
                context,
                type: GameConstants.boosterHammer,
                imageAsset: 'assets/images/sprites/boosters/booster_hammer.png',
                label: 'Búa',
                count: playerData.getBoosterCount('hammer'),
                isSelected: controller.activeBooster == GameConstants.boosterHammer,
                onTap: () => _onBoosterTapped(
                  context,
                  playerData: playerData,
                  boosterKey: 'hammer',
                  boosterType: GameConstants.boosterHammer,
                  label: 'Búa',
                  imageAsset: 'assets/images/sprites/boosters/booster_hammer.png',
                ),
              ),

              // 4. Wand (Đũa sao biển - Biến đổi các con cá cho thông thoáng)
              _buildBoosterItem(
                context,
                type: GameConstants.boosterWand,
                imageAsset: 'assets/images/sprites/boosters/booster_magic_wand.png',
                label: 'Đũa thần',
                count: playerData.getBoosterCount('wand'),
                isSelected: false,
                onTap: () => _onBoosterTapped(
                  context,
                  playerData: playerData,
                  boosterKey: 'wand',
                  boosterType: GameConstants.boosterWand,
                  label: 'Đũa thần',
                  imageAsset: 'assets/images/sprites/boosters/booster_magic_wand.png',
                ),
              ),

              // 5. Net (Vợt bắt cá - Thu thập dần các con cá để thông thoáng)
              _buildBoosterItem(
                context,
                type: GameConstants.boosterNet,
                imageAsset: 'assets/images/sprites/boosters/booster_magnet.png',
                label: 'Vợt',
                count: playerData.getBoosterCount('net'),
                isSelected: controller.activeBooster == GameConstants.boosterNet,
                onTap: () => _onBoosterTapped(
                  context,
                  playerData: playerData,
                  boosterKey: 'net',
                  boosterType: GameConstants.boosterNet,
                  label: 'Vợt',
                  imageAsset: 'assets/images/sprites/boosters/booster_magnet.png',
                ),
              ),
            ],
          ),
        );
      },
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
              // Wooden Base Plate
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? Colors.amber.withValues(alpha: 0.6)
                          : Colors.black.withValues(alpha: 0.18),
                      blurRadius: isSelected ? 10 : 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Plate background
                    Image.asset(
                      'assets/images/sprites/boosters/booster_plate_base.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFD7A15C),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    // Selection ring
                    if (isSelected)
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amber, width: 3),
                        ),
                      ),

                    // Booster icon
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Image.asset(
                        imageAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => const Icon(Icons.flash_on, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),

              // Quantity or Plus Badge
              Positioned(
                right: -2,
                bottom: -2,
                child: count > 0
                    ? Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 3,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontFamily: 'BrandonText',
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Image.asset(
                        'assets/images/sprites/boosters/badge_plus.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text('+', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
