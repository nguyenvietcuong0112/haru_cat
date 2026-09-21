import 'package:flutter/material.dart';
import '../../logic/game_controller.dart';
import '../../models/level_data.dart';
import '../../utils/level_loader.dart';
import '../widgets/game_board.dart';
import '../widgets/score_header.dart';
import '../widgets/booster_bar.dart';
import '../dialogs/pause_dialog.dart';
import '../dialogs/game_over_dialog.dart';
import '../dialogs/continue_dialog.dart';
import '../dialogs/level_complete_dialog.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final LevelData? levelData;
  final String? category;
  final int? levelNumber;

  const GameScreen({
    super.key,
    required this.mode,
    this.levelData,
    this.category,
    this.levelNumber,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController _controller;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _controller = GameController(
      mode: widget.mode,
      levelData: widget.levelData,
    );
    _controller.addListener(_onGameStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onGameStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onGameStateChanged() {
    if (!mounted) return;

    // 1. Continue Revive Prompt
    if (_controller.isContinuePrompting && !_dialogShown) {
      _dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => ContinueDialog(
          onRevive: () {
            Navigator.pop(ctx);
            _dialogShown = false;
            _controller.reviveContinue();
          },
          onGiveUp: () {
            Navigator.pop(ctx);
            _dialogShown = false;
            _controller.declineContinue();
          },
        ),
      );
      return;
    }

    // 2. Game Over Prompt
    if (_controller.isGameOver && !_dialogShown) {
      _dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => GameOverDialog(
          score: _controller.score,
          bestScore: _controller.bestScore,
          linesCleared: _controller.linesClearedTotal,
          specialBlocksCleared: _controller.specialBlocksCleared,
          maxCombo: _controller.maxCombo,
          silverEarned: _controller.silverEarned,
          onReplay: () {
            Navigator.pop(ctx);
            _dialogShown = false;
            _controller.initGame();
          },
          onHome: () {
            Navigator.pop(ctx);
            Navigator.pop(context);
          },
        ),
      );
      return;
    }

    // 3. Level Completed Prompt
    if (_controller.isLevelCompleted && !_dialogShown) {
      _dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => LevelCompleteDialog(
          stars: _controller.starsEarned,
          moves: _controller.moves,
          onNextLevel: () async {
            Navigator.pop(ctx);
            _dialogShown = false;

            final currentNum = widget.levelNumber ?? 1;
            final cat = widget.category ?? 'Easy';
            final nextData = await LevelLoader.loadLevel(cat, currentNum + 1);

            if (nextData != null && mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => GameScreen(
                    mode: GameMode.level,
                    levelData: nextData,
                    category: cat,
                    levelNumber: currentNum + 1,
                  ),
                ),
              );
            } else if (mounted) {
              Navigator.pop(context);
            }
          },
          onHome: () {
            Navigator.pop(ctx);
            if (mounted) Navigator.pop(context);
          },
        ),
      );
    }
  }

  void _showPauseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PauseDialog(
        onResume: () => Navigator.pop(ctx),
        onRestart: () {
          Navigator.pop(ctx);
          _controller.initGame();
        },
        onHome: () {
          Navigator.pop(ctx);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Wallpaper
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/bg_ingame.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF3E5D8)),
            ),
          ),

          // Main Game Layout
          SafeArea(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, child) {
                return Column(
                  children: [
                    // Header Bar (Score, Moves/Best, Skill, Mascot Speech, Pause)
                    ScoreHeader(
                      controller: _controller,
                      onPause: _showPauseDialog,
                    ),

                    // Combo Notification
                    if (_controller.combo > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${_controller.combo}x COMBO! 🐾',
                          style: const TextStyle(
                            fontFamily: 'JandaManatee',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),

                    // Game Board (8x10)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: GameBoard(controller: _controller),
                      ),
                    ),

                    // Bottom Booster Bar
                    BoosterBar(controller: _controller),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
