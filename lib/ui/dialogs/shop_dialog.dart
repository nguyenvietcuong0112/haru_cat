import 'package:flutter/material.dart';
import '../../models/player_data.dart';
import '../../audio/audio_manager.dart';
import '../widgets/game_popup_kit.dart';

class ShopDialog extends StatefulWidget {
  const ShopDialog({super.key});

  @override
  State<ShopDialog> createState() => _ShopDialogState();
}

class _ShopDialogState extends State<ShopDialog> {
  final PlayerData _playerData = PlayerData();
  final AudioManager _audio = AudioManager();

  void _showNotice(String msg, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          msg,
          style: const TextStyle(
            fontFamily: 'BrandonText',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isSuccess ? const Color(0xFF00838F) : const Color(0xFFD32F2F),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GamePopupFrame(
      title: 'SHOP',
      bannerPalette: GameButtonPalette.gold,
      maxWidth: 395,
      maxHeight: 575,
      onClose: () => Navigator.pop(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Synchronized Wallet Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GameWalletPill(
                iconAsset: 'assets/images/sprites/ui/coin-silver-8.png',
                amount: '${_playerData.silverFish}',
              ),
              const SizedBox(width: 12),
              GameWalletPill(
                iconAsset: 'assets/images/sprites/ui/coin-gold-8.png',
                amount: '${_playerData.goldFish}',
              ),
            ],
          ),
          const SizedBox(height: 12),

          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                _buildSectionHeader('BOOSTER PACKS'),
                const SizedBox(height: 8),

                _buildBoosterCard(
                  title: '3x Shell Hammer',
                  desc: 'Shatters any ice block in a single hit!',
                  imageAsset: 'assets/images/sprites/boosters/booster_hammer.png',
                  goldCost: 8,
                  onBuy: () {
                    if (_playerData.spendGoldFish(8)) {
                      _playerData.addBooster('hammer', 3);
                      _audio.playBooster();
                      setState(() {});
                      _showNotice('Purchased +3 Shell Hammers!');
                    } else {
                      _showNotice('Not enough Gold!', isSuccess: false);
                    }
                  },
                ),
                const SizedBox(height: 8),

                _buildBoosterCard(
                  title: '3x Starfish Wand',
                  desc: 'Splits large fish into tiny 1-cell fish!',
                  imageAsset: 'assets/images/sprites/boosters/booster_magic_wand.png',
                  goldCost: 8,
                  onBuy: () {
                    if (_playerData.spendGoldFish(8)) {
                      _playerData.addBooster('wand', 3);
                      _audio.playBooster();
                      setState(() {});
                      _showNotice('Purchased +3 Starfish Wands!');
                    } else {
                      _showNotice('Not enough Gold!', isSuccess: false);
                    }
                  },
                ),
                const SizedBox(height: 8),

                _buildBoosterCard(
                  title: '3x Scoop Net',
                  desc: 'Scoops any single fish out of the tank!',
                  imageAsset: 'assets/images/sprites/boosters/booster_magnet.png',
                  goldCost: 8,
                  onBuy: () {
                    if (_playerData.spendGoldFish(8)) {
                      _playerData.addBooster('net', 3);
                      _audio.playBooster();
                      setState(() {});
                      _showNotice('Purchased +3 Scoop Nets!');
                    } else {
                      _showNotice('Not enough Gold!', isSuccess: false);
                    }
                  },
                ),
                const SizedBox(height: 14),

                _buildSectionHeader('FISH EXCHANGE'),
                const SizedBox(height: 8),

                _buildExchangeCard(
                  fromIcon: 'assets/images/sprites/ui/coin-silver-8.png',
                  toIcon: 'assets/images/sprites/ui/coin-gold-8.png',
                  title: '50 SILVER -> 1 GOLD',
                  subtitle:
                      'Exchanged: ${_playerData.goldExchangedFromSilver}/${_playerData.maxGoldExchange} Gold',
                  buttonText: _playerData.goldExchangedFromSilver >= _playerData.maxGoldExchange
                      ? 'MAX'
                      : '50',
                  buttonCoinAsset: _playerData.goldExchangedFromSilver >= _playerData.maxGoldExchange
                      ? null
                      : 'assets/images/sprites/ui/coin-silver-8.png',
                  isEnabled: _playerData.goldExchangedFromSilver < _playerData.maxGoldExchange,
                  onTap: () {
                    if (_playerData.goldExchangedFromSilver >= _playerData.maxGoldExchange) {
                      _showNotice('Max limit of 10 Gold exchanged reached!', isSuccess: false);
                      return;
                    }
                    if (_playerData.exchangeSilverForGold(silverCost: 50)) {
                      _audio.playWin();
                      setState(() {});
                      _showNotice(
                        'Exchanged +1 Gold (${_playerData.goldExchangedFromSilver}/${_playerData.maxGoldExchange})!',
                      );
                    } else {
                      _showNotice('Not enough Silver (need 50 Silver)!', isSuccess: false);
                    }
                  },
                ),
                const SizedBox(height: 8),

                _buildExchangeCard(
                  fromIcon: 'assets/images/sprites/ui/coin-gold-8.png',
                  toIcon: 'assets/images/sprites/ui/coin-silver-8.png',
                  title: '10 GOLD -> 350 SILVER',
                  subtitle: 'Get a huge pouch of Silver Fish!',
                  buttonText: '10',
                  buttonCoinAsset: 'assets/images/sprites/ui/coin-gold-8.png',
                  isEnabled: true,
                  onTap: () {
                    if (_playerData.spendGoldFish(10)) {
                      _playerData.addSilverFish(350);
                      _audio.playWin();
                      setState(() {});
                      _showNotice('Exchanged +350 Silver!');
                    } else {
                      _showNotice('Not enough Gold!', isSuccess: false);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFC9EEF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF78C0D4), width: 1.5),
      ),
      alignment: Alignment.center,
      child: GameStrokedText(
        text,
        fontSize: 13.5,
        fillColor: const Color(0xFFFFF59D),
        strokeColor: const Color(0xFF135060),
        strokeWidth: 3.5,
      ),
    );
  }

  Widget _buildBoosterCard({
    required String title,
    required String desc,
    required String imageAsset,
    required int goldCost,
    required VoidCallback onBuy,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF83C7D9), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF166175).withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Medallion Icon
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/sprites/boosters/booster_plate_base.png',
                  width: 50,
                  height: 50,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.flash_on, color: Colors.orange, size: 30),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GameStrokedText(
                    title,
                    fontSize: 15,
                    fillColor: Colors.white,
                    strokeColor: const Color(0xFF154E5E),
                    strokeWidth: 3.6,
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: 'BrandonText',
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E6B7B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Game3DButton(
            width: 78,
            height: 40,
            borderRadius: 14,
            palette: GameButtonPalette.green,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onTap: onBuy,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/sprites/ui/coin-gold-8.png',
                  width: 17,
                  height: 17,
                ),
                const SizedBox(width: 4),
                GameStrokedText(
                  '$goldCost',
                  fontSize: 14.5,
                  strokeColor: GameButtonPalette.green.textStroke,
                  strokeWidth: 3.5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeCard({
    required String fromIcon,
    required String toIcon,
    required String title,
    required String subtitle,
    required String buttonText,
    String? buttonCoinAsset,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF83C7D9), width: 2.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF80DEEA), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(fromIcon, width: 20, height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF00838F)),
                ),
                Image.asset(toIcon, width: 20, height: 20),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GameStrokedText(
                    title,
                    fontSize: 14,
                    strokeColor: const Color(0xFF154E5E),
                    strokeWidth: 3.4,
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'BrandonText',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E6B7B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Game3DButton(
            width: 82,
            height: 40,
            borderRadius: 14,
            palette: isEnabled ? GameButtonPalette.orange : GameButtonPalette.slate,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            onTap: isEnabled ? onTap : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (buttonCoinAsset != null) ...[
                  Image.asset(buttonCoinAsset, width: 16, height: 16),
                  const SizedBox(width: 4),
                ],
                GameStrokedText(
                  buttonText,
                  fontSize: 13.5,
                  strokeColor: isEnabled
                      ? GameButtonPalette.orange.textStroke
                      : GameButtonPalette.slate.textStroke,
                  strokeWidth: 3.4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
