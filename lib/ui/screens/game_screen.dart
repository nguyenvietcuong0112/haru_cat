import 'package:flutter/material.dart';
import '../../logic/game_controller.dart';
import '../../models/level_data.dart';
import '../../utils/level_loader.dart';
import '../widgets/game_board.dart';
import '../widgets/game_popup_kit.dart';
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
        builder: (ctx) => PopScope(
          canPop: false,
          child: ContinueDialog(
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
        builder: (ctx) => PopScope(
          canPop: false,
          child: GameOverDialog(
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
        builder: (ctx) => PopScope(
          canPop: false,
          child: LevelCompleteDialog(
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
        children: [
          // Synchronized Underwater Ocean & Seabed Background (matches HomeScreen)
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/bg_home.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFC8F3FE),
                      Color(0xFF93E2F6),
                      Color(0xFFE7EFD7),
                    ],
                    stops: [0.0, 0.68, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Subtle sunlit water-surface sheen & calm ocean depth balance
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.14),
                      const Color(0xFF00ACC1).withOpacity(0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
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

                    // Game Board (8x10) + Non-layout-shifting Floating Combo Badge
                    Expanded(
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: GameBoard(controller: _controller),
                          ),
                          Positioned(
                            top: 0,
                            child: IgnorePointer(
                              child: AnimatedScale(
                                scale: _controller.combo > 1 ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutBack,
                                child: Container(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  decoration: BoxDecoration(
                                    color: GameButtonPalette.orange.bottomBevel,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: GameButtonPalette.orange.borderColor,
                                      width: 2.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF6D00).withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          GameButtonPalette.orange.faceTop,
                                          GameButtonPalette.orange.faceBottom,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: GameStrokedText(
                                      '${_controller.combo > 1 ? _controller.combo : 2}x COMBO!',
                                      fontSize: 14.5,
                                      strokeColor: GameButtonPalette.orange.textStroke,
                                      strokeWidth: 3.8,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
    ),
    );
  }
}
