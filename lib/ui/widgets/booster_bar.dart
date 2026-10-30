import 'package:flutter/material.dart';
import '../../logic/game_controller.dart';
import '../../models/player_data.dart';
import '../../utils/constants.dart';
import '../dialogs/shop_dialog.dart';
import 'game_popup_kit.dart';

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
      builder: (ctx) => GamePopupFrame(
        title: 'MUA ${label.toUpperCase()}',
        bannerPalette: GameButtonPalette.orange,
        maxWidth: 335,
        onClose: () => Navigator.pop(ctx),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current Gold Wallet Pill
            Align(
              alignment: Alignment.centerRight,
              child: GameWalletPill(
                iconAsset: 'assets/images/sprites/ui/coin-gold-8.png',
                amount: '${playerData.goldFish}',
              ),
            ),
            const SizedBox(height: 6),

            // 3D Booster Showcase Medallion
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFC2F1FA),
                  ],
                ),
                border: Border.all(color: const Color(0xFF56B8CE), width: 3.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF15697D).withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/sprites/boosters/booster_plate_base.png',
                    width: 68,
                    height: 68,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.flash_on_rounded,
                        color: Color(0xFFFF9800),
                        size: 38,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Ocean Info Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFD7F3FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF83C7D8), width: 1.8),
              ),
              child: Column(
                children: [
                  GameStrokedText(
                    'HẾT ${label.toUpperCase()}!',
                    fontSize: 15.5,
                    fillColor: const Color(0xFFFFF59D),
                    strokeColor: const Color(0xFF134E5E),
                    strokeWidth: 3.6,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    canAfford
                        ? 'Mua ngay 1 $label để tiếp tục giải cứu bể cá?'
                        : 'Bạn cần $goldCost Cá Vàng để mua $label. Ghé Cửa Hàng đổi thêm nhé!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'BrandonText',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF144E5E),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Primary Action Button
            if (canAfford)
              Game3DButton(
                palette: GameButtonPalette.green,
                height: 52,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const GameStrokedText(
                      'MUA NGAY',
                      fontSize: 16.5,
                      strokeColor: Color(0xFF214D10),
                      strokeWidth: 4.2,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF245312).withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/sprites/ui/coin-gold-8.png',
                            width: 18,
                            height: 18,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.monetization_on_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const GameStrokedText(
                            '$goldCost',
                            fontSize: 15.5,
                            strokeColor: Color(0xFF214D10),
                            strokeWidth: 3.8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Game3DButton(
                label: 'ĐẾN CỬA HÀNG',
                icon: Icons.storefront_rounded,
                palette: GameButtonPalette.gold,
                height: 52,
                fontSize: 16,
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(context: context, builder: (_) => const ShopDialog());
                },
              ),
            const SizedBox(height: 10),

            // Secondary Dismiss Button
            Game3DButton(
              label: 'ĐỂ SAU',
              palette: GameButtonPalette.slate,
              height: 42,
              fontSize: 14.5,
              onTap: () => Navigator.pop(ctx),
            ),
          ],
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
    return GameTapScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Booster Base Plate
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? Colors.amber.withValues(alpha: 0.65)
                          : Colors.black.withValues(alpha: 0.2),
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
                        errorBuilder: (ctx, err, stack) =>
                            const Icon(Icons.flash_on, color: Colors.orange),
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
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFF7A7A), Color(0xFFE53935)],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF681313),
                            width: 1.8,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 3,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: GameStrokedText(
                          '$count',
                          fontSize: 11.5,
                          strokeColor: const Color(0xFF631010),
                          strokeWidth: 2.8,
                        ),
                      )
                    : Image.asset(
                        'assets/images/sprites/boosters/badge_plus.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF96E832), Color(0xFF7ED31B)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF245312),
                              width: 1.8,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const GameStrokedText(
                            '+',
                            fontSize: 13,
                            strokeColor: Color(0xFF214D10),
                            strokeWidth: 2.8,
                          ),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          GameStrokedText(
            label,
            fontSize: 13,
            fillColor: Colors.white,
            strokeColor: const Color(0xFF134B5A),
            strokeWidth: 3.4,
          ),
        ],
      ),
    );
  }
}
