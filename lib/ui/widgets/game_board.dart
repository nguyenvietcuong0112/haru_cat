import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../game/haru_slide_game.dart';
import '../../logic/game_controller.dart';
import '../../utils/constants.dart';

class GameBoard extends StatefulWidget {
  final GameController controller;

  const GameBoard({
    super.key,
    required this.controller,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  HaruSlideGame? _game;
  double _lastCellSize = 0.0;
  double _lastW = 0.0;
  double _lastH = 0.0;
  GameController? _lastController;

  HaruSlideGame _getOrCreateGame({
    required GameController controller,
    required double cellSize,
    required double boardW,
    required double boardH,
    required int totalRows,
    required bool isEndless,
  }) {
    if (_game == null ||
        _lastCellSize != cellSize ||
        _lastW != boardW ||
        _lastH != boardH ||
        _lastController != controller) {
      _lastCellSize = cellSize;
      _lastW = boardW;
      _lastH = boardH;
      _lastController = controller;

      _game = HaruSlideGame(
        controller: controller,
        cellSize: cellSize,
        boardWidth: boardW,
        boardHeight: boardH,
        totalRows: totalRows,
        isEndless: isEndless,
      );
    }
    return _game!;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isEndless = controller.mode == GameMode.endless;

        // Calculate available space, reserving space for top boat mascot
        const outerPadding = 4.0;
        const outerBorder = 3.0;
        const extraSpace = (outerPadding + outerBorder) * 2; // 14.0
        const boatHeight = 36.0;

        // Safety margin of 12.0px to prevent any fractional subpixel rounding overflow
        final availableW = constraints.maxWidth - extraSpace - 8.0;
        final availableH = constraints.maxHeight - extraSpace - boatHeight - 12.0;

        // In endless mode: 10 active rows (0..9) + 1 preview row (-1) = 11 total rows
        final totalRows = isEndless ? (GameConstants.boardRows + 1) : GameConstants.boardRows;

        final cellByWidth = availableW / GameConstants.boardCols;
        final cellByHeight = availableH / totalRows;
        final cellSize = (cellByWidth < cellByHeight ? cellByWidth : cellByHeight).floorToDouble();

        final boardW = cellSize * GameConstants.boardCols;
        final boardH = cellSize * totalRows;

        final game = _getOrCreateGame(
          controller: controller,
          cellSize: cellSize,
          boardW: boardW,
          boardH: boardH,
          totalRows: totalRows,
          isEndless: isEndless,
        );

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 0. Cute Floating Boat Mascot on surface of water tank
              _FloatingBoatWidget(
                isHappy: controller.clearingRowIndex != null,
                height: boatHeight,
              ),

              // 1. Water Tank Board
              Container(
                padding: const EdgeInsets.all(outerPadding),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF80DEEA), width: outerBorder),
                  color: const Color(0xFFE0F7FA).withOpacity(0.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF006064).withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Container(
                  width: boardW,
                  height: boardH,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFE0F7FA), // Light crystal water top
                        Color(0xFFB2EBF2), // Deeper aqua water bottom
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Flame Game Engine Grid & Physics Canvas
                      GameWidget(
                        key: ValueKey('flame_${boardW.toInt()}_${boardH.toInt()}_${controller.hashCode}'),
                        game: game,
                      ),

                      // Preview Indicator Badge in bottom-left
                      if (isEndless)
                        Positioned(
                          top: (totalRows - 1) * cellSize + 2,
                          left: 4,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'TIẾP THEO 🐾',
                                style: TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Booster Selection Overlay Notice
                      if (controller.activeBooster != null)
                        Positioned(
                          top: 12,
                          left: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              controller.activeBooster == GameConstants.boosterHammer
                                  ? '🐚 Chạm vào khối băng để phá tan chỉ trong 1 lần đập!'
                                  : (controller.activeBooster == GameConstants.boosterNet
                                      ? '🏸 Chạm vào bất kỳ con cá nào để vớt thu thập!'
                                      : '⭐ Chạm vào khối cá để biến đổi!'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Floating Boat Mascot that bobs gently on the water tank waves
class _FloatingBoatWidget extends StatefulWidget {
  final bool isHappy;
  final double height;

  const _FloatingBoatWidget({
    required this.isHappy,
    this.height = 36.0,
  });

  @override
  State<_FloatingBoatWidget> createState() => _FloatingBoatWidgetState();
}

class _FloatingBoatWidgetState extends State<_FloatingBoatWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          final phase = _animController.value * 2 * pi;
          final waveY = sin(phase) * 2.0 + (widget.isHappy ? -4.0 : 0.0);
          final tilt = sin(phase * 0.8) * 0.025;

          return Transform.translate(
            offset: Offset(0, waveY),
            child: Transform.rotate(
              angle: tilt,
              child: Image.asset(
                'assets/images/sprites/ui/boat_mascot.png',
                height: widget.height,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          );
        },
      ),
    );
  }
}
