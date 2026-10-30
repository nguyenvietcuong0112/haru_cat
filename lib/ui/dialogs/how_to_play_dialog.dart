import 'package:flutter/material.dart';
import '../widgets/game_popup_kit.dart';

class HowToPlayDialog extends StatefulWidget {
  const HowToPlayDialog({super.key});

  @override
  State<HowToPlayDialog> createState() => _HowToPlayDialogState();
}

class _HowToPlayDialogState extends State<HowToPlayDialog> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<Map<String, String>> _steps = [
    {
      'title': 'TRƯỢT CÁ TRÁI / PHẢI',
      'desc': 'Kéo các chú cá trượt ngang sang trái hoặc phải để lấp vào các khoảng trống.',
      'image': 'assets/images/sprites/fish/fish_3cell_b.png',
      'tip': 'Có bóng mờ phía dưới báo trước vị trí cá sẽ rơi xuống!',
    },
    {
      'title': 'RƠI TỰ DO & LẤP ĐẦY',
      'desc': 'Khi phía dưới trống, các chú cá bên trên sẽ từ từ trôi xuống bể theo trọng lực.',
      'image': 'assets/images/sprites/fish/fish_4cell_a.png',
      'tip': 'Lấp kín toàn bộ 8 ô trên 1 hàng ngang để ăn điểm!',
    },
    {
      'title': 'COMBO TỪ TRÊN XUỐNG',
      'desc': 'Hàng đầy sẽ ăn lần lượt từ trên xuống dưới, kéo theo chuỗi rơi liên hoàn!',
      'image': 'assets/images/sprites/fish/ice_2cell.png',
      'tip': 'Cá đóng băng cần ăn 2 lần (hoặc đập 1 nhát bằng Búa Ốc)!',
    },
    {
      'title': 'ĐẠO CỤ ĐẠI DƯƠNG',
      'desc': 'Sử dụng Búa Ốc, Đũa Sao Biển và Vợt Cá khi bể sắp chạm vạch cảnh báo đỏ!',
      'image': 'assets/images/sprites/boosters/booster_hammer.png',
      'tip': 'Săn Hộp Quà trong bể để nhận Vàng, Bạc & Đạo cụ miễn phí!',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GamePopupFrame(
      title: 'HOW TO PLAY',
      bannerPalette: GameButtonPalette.aqua,
      maxWidth: 365,
      maxHeight: 470,
      onClose: () => Navigator.pop(context),
      child: Column(
        children: [
          const SizedBox(height: 6),

          // Carousel Pages
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _steps.length,
              onPageChanged: (idx) {
                setState(() {
                  _currentPage = idx;
                });
              },
              itemBuilder: (context, idx) {
                final step = _steps[idx];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 104,
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFD5F5FC), Color(0xFFB3EBF7)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF72C2D6),
                          width: 2.0,
                        ),
                      ),
                      child: Image.asset(
                        step['image']!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.waves_rounded,
                          size: 54,
                          color: Color(0xFF00ACC1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GameStrokedText(
                      step['title']!,
                      fontSize: 18,
                      strokeColor: const Color(0xFF134B5A),
                      strokeWidth: 4.0,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        step['desc']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'BrandonText',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D5A6B),
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8DC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFFFCA28),
                          width: 1.6,
                        ),
                      ),
                      child: Text(
                        '💡 ${step['tip']}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'BrandonText',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4800),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Ocean Page Indicator Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_steps.length, (index) {
              final isSelected = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isSelected ? 22 : 9,
                height: 9,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00ACC1)
                      : const Color(0xFFB2DFEA),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF135261)
                        : const Color(0xFF7CB9C9),
                    width: 1.2,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),

          // 3D Next / Play Button
          Game3DButton(
            label: _currentPage < _steps.length - 1 ? 'NEXT' : 'LET\'S PLAY!',
            icon: _currentPage < _steps.length - 1
                ? Icons.arrow_forward_rounded
                : Icons.play_arrow_rounded,
            palette: _currentPage < _steps.length - 1
                ? GameButtonPalette.aqua
                : GameButtonPalette.green,
            height: 48,
            fontSize: 17,
            onTap: () {
              if (_currentPage < _steps.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
