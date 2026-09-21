import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/level_loader.dart';
import '../../logic/game_controller.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, int> _levelStars = {};
  bool _isLoading = true;

  final List<String> _categories = ['Easy', 'Medium', 'Hard'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadStars();
  }

  Future<void> _loadStars() async {
    final prefs = await SharedPreferences.getInstance();
    for (final cat in _categories) {
      final maxL = LevelLoader.getMaxLevels(cat);
      for (int i = 1; i <= maxL; i++) {
        final key = 'level_stars_${cat}_$i';
        _levelStars['${cat}_$i'] = prefs.getInt(key) ?? 0;
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/bg_ingame.png',
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(color: const Color(0xFFF3E5D8)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF5D4037),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'CHỌN MÀN CHƠI',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF5D4037),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40), // Balance back button
                    ],
                  ),
                ),

                // Category Tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7CCC8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFFFF9800),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF5D4037),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    tabs: const [
                      Tab(text: 'DỄ (30)'),
                      Tab(text: 'VỪA (30)'),
                      Tab(text: 'KHÓ (40)'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Levels Grid
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: _categories.map((cat) {
                            return _buildLevelGrid(cat);
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelGrid(String category) {
    final maxLevels = LevelLoader.getMaxLevels(category);

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: maxLevels,
      itemBuilder: (itemContext, index) {
        final levelNum = index + 1;
        final key = '${category}_$levelNum';
        final stars = _levelStars[key] ?? 0;

        return GestureDetector(
          onTap: () async {
            final levelData = await LevelLoader.loadLevel(category, levelNum);
            if (!mounted) return;
            if (levelData != null) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => GameScreen(
                    mode: GameMode.level,
                    levelData: levelData,
                    category: category,
                    levelNumber: levelNum,
                  ),
                ),
              );
              // Refresh stars after returning
              if (mounted) _loadStars();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: stars > 0 ? const Color(0xFFFFB300) : const Color(0xFFBCAAA4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$levelNum',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5D4037),
                  ),
                ),
                const SizedBox(height: 4),

                // Stars Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (s) {
                    return Icon(
                      s < stars ? Icons.star_rounded : Icons.star_border_rounded,
                      color: s < stars ? const Color(0xFFFFB300) : Colors.grey[400],
                      size: 14,
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

