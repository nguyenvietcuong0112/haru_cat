import 'package:flutter/material.dart';

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
      'title': 'Slide Left or Right',
      'desc': 'Slide cat blocks horizontally to fill empty spaces in the board.',
      'image': 'assets/images/sprites/cats/next_block_cat_01_2cell.png',
      'tip': 'Cats can move as far as the path is open!',
    },
    {
      'title': 'Blocks Drop Down',
      'desc': 'Whenever empty gaps appear beneath a cat, gravity will drop them down.',
      'image': 'assets/images/sprites/cats/next_block_cat_02_3cell.png',
      'tip': 'Plan ahead to trigger chain reaction drops!',
    },
    {
      'title': 'Make Full Rows',
      'desc': 'Complete an entire 8-cell horizontal row to blast it and score points!',
      'image': 'assets/images/sprites/cats/next_block_cat_03_4cell.png',
      'tip': 'Clearing consecutive lines triggers Combo multipliers!',
    },
    {
      'title': 'No Color Matching Needed',
      'desc': 'Just remember: Any cat color works! The game ends when cats reach the top.',
      'image': 'assets/images/characters/newportrait_haru.png',
      'tip': 'Use special boosters and character skills when in trouble!',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 480),
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
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 32),
                const Text(
                  'HOW TO PLAY',
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
            const SizedBox(height: 10),

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
                        height: 110,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF0E6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Image.asset(
                          step['image']!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 60, color: Colors.orange),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        step['title']!,
                        style: const TextStyle(
                          fontFamily: 'JandaManatee',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4226),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step['desc']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'BrandonText',
                          fontSize: 13,
                          color: Color(0xFF8B5A2B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '💡 ${step['tip']}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'BrandonText',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown.shade700,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Page Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (index) {
                final isSelected = index == _currentPage;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Navigation Button
            GestureDetector(
              onTap: () {
                if (_currentPage < _steps.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  Navigator.pop(context);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    _currentPage < _steps.length - 1 ? 'NEXT' : 'LET\'S PLAY!',
                    style: const TextStyle(
                      fontFamily: 'JandaManatee',
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
