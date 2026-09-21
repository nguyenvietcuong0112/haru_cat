import 'package:flutter/material.dart';
import '../../models/player_data.dart';
import '../../audio/audio_manager.dart';

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
        content: Text(msg),
        backgroundColor: isSuccess ? Colors.green : Colors.redAccent,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
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
            // Header with Wallets
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Wallets
                Row(
                  children: [
                    Image.asset('assets/images/sprites/ui/coin-silver-8.png', width: 22, height: 22),
                    const SizedBox(width: 4),
                    Text(
                      '${_playerData.silverFish}',
                      style: const TextStyle(
                        fontFamily: 'JandaManatee',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B4226),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Image.asset('assets/images/sprites/ui/coin-gold-8.png', width: 22, height: 22),
                    const SizedBox(width: 4),
                    Text(
                      '${_playerData.goldFish}',
                      style: const TextStyle(
                        fontFamily: 'JandaManatee',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B4226),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF6B4226)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Text(
              'HARU SHOP',
              style: TextStyle(
                fontFamily: 'JandaManatee',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4226),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: [
                  // --- BOOSTERS SECTION ---
                  const Text(
                    'BOOSTER PACKS',
                    style: TextStyle(
                      fontFamily: 'JandaManatee',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B5A2B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildBoosterItem(
                    title: '3x Búa Ốc',
                    desc: 'Phá băng, chỉ cần phá 1 lần',
                    imageAsset: 'assets/images/sprites/boosters/booster_hammer.png',
                    goldCost: 8,
                    onBuy: () {
                      if (_playerData.spendGoldFish(8)) {
                        _playerData.addBooster('hammer', 3);
                        _audio.playBooster();
                        setState(() {});
                        _showNotice('Đã mua 3 Búa!');
                      } else {
                        _showNotice('Không đủ Vàng!', isSuccess: false);
                      }
                    },
                  ),
                  const SizedBox(height: 8),

                  _buildBoosterItem(
                    title: '3x Đũa Sao Biển',
                    desc: 'Biến đổi các con cá cho thông thoáng',
                    imageAsset: 'assets/images/sprites/boosters/booster_magic_wand.png',
                    goldCost: 8,
                    onBuy: () {
                      if (_playerData.spendGoldFish(8)) {
                        _playerData.addBooster('wand', 3);
                        _audio.playBooster();
                        setState(() {});
                        _showNotice('Đã mua 3 Đũa thần!');
                      } else {
                        _showNotice('Không đủ Vàng!', isSuccess: false);
                      }
                    },
                  ),
                  const SizedBox(height: 8),

                  _buildBoosterItem(
                    title: '3x Vợt Cá',
                    desc: 'Thu thập dần các con cá để cho thông thoáng',
                    imageAsset: 'assets/images/sprites/boosters/booster_magnet.png',
                    goldCost: 8,
                    onBuy: () {
                      if (_playerData.spendGoldFish(8)) {
                        _playerData.addBooster('net', 3);
                        _audio.playBooster();
                        setState(() {});
                        _showNotice('Đã mua 3 Vợt!');
                      } else {
                        _showNotice('Không đủ Vàng!', isSuccess: false);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- FISH EXCHANGE SECTION ---
                  const Text(
                    'FISH EXCHANGE',
                    style: TextStyle(
                      fontFamily: 'JandaManatee',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B5A2B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildExchangeCard(
                    title: '50 Bạc ➔ 1 Vàng',
                    subtitle: 'Đổi Bạc lấy Vàng (Tối đa: ${_playerData.goldExchangedFromSilver}/${_playerData.maxGoldExchange} Vàng)',
                    buttonText: _playerData.goldExchangedFromSilver >= _playerData.maxGoldExchange
                        ? 'Hết lượt'
                        : '50 Bạc',
                    onTap: () {
                      if (_playerData.goldExchangedFromSilver >= _playerData.maxGoldExchange) {
                        _showNotice('Đã đạt giới hạn đổi tối đa 10 Vàng!', isSuccess: false);
                        return;
                      }
                      if (_playerData.exchangeSilverForGold(silverCost: 50)) {
                        _audio.playWin();
                        setState(() {});
                        _showNotice('Đổi thành công 50 Bạc lấy 1 Vàng (${_playerData.goldExchangedFromSilver}/${_playerData.maxGoldExchange})!');
                      } else {
                        _showNotice('Không đủ Bạc (cần 50 Bạc)!', isSuccess: false);
                      }
                    },
                  ),
                  const SizedBox(height: 8),

                  _buildExchangeCard(
                    title: '10 Gold ➔ 350 Silver',
                    subtitle: 'Get a big pile of silver fish',
                    buttonText: '10 Gold',
                    onTap: () {
                      if (_playerData.spendGoldFish(10)) {
                        _playerData.addSilverFish(350);
                        _audio.playWin();
                        setState(() {});
                        _showNotice('Exchanged 10 Gold for 350 Silver!');
                      } else {
                        _showNotice('Not enough Gold Fish!', isSuccess: false);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoosterItem({
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2C4A2)),
      ),
      child: Row(
        children: [
          Image.asset(
            imageAsset,
            width: 44,
            height: 44,
            errorBuilder: (_, __, ___) => const Icon(Icons.flash_on, color: Colors.orange, size: 36),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'JandaManatee',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B4226),
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontFamily: 'BrandonText',
                    fontSize: 11,
                    color: Colors.brown.shade400,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onBuy,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Image.asset('assets/images/sprites/ui/coin-gold-8.png', width: 16, height: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$goldCost',
                    style: const TextStyle(
                      fontFamily: 'BrandonText',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeCard({
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2C4A2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'JandaManatee',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4226),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'BrandonText',
                  fontSize: 11,
                  color: Colors.brown.shade400,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6B4226),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontFamily: 'BrandonText',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
