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
        const outerPadding = 3.5;
        const outerBorder = 2.5;
        const extraSpace = (outerPadding + outerBorder) * 2; // 12.0
        const boatHeight = 44.0;

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
              // 0. Cute Floating Boat Mascot on elliptical water surface of the aquarium tank
              _FloatingBoatWidget(
                isHappy: controller.clearingRowIndex != null,
                height: boatHeight,
                tankWidth: boardW + extraSpace,
              ),

              // 1. Glass Aquarium Water Tank Board
              Container(
                padding: const EdgeInsets.all(outerPadding),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.all(color: const Color(0xFF63A1B2), width: outerBorder),
                  color: Colors.white.withOpacity(0.58),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF004D5A).withOpacity(0.20),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
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
                        Color(0xFFD6F7FC), // Sunlit crystal water surface
                        Color(0xFFB3ECF5), // Mid aquarium aqua
                        Color(0xFF9DE3EE), // Deeper aquarium bottom
                      ],
                      stops: [0.0, 0.65, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(11),
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

/// Floating Boat Mascot that bobs gently on an elliptical water-tank surface rim
class _FloatingBoatWidget extends StatefulWidget {
  final bool isHappy;
  final double height;
  final double tankWidth;

  const _FloatingBoatWidget({
    required this.isHappy,
    this.height = 44.0,
    required this.tankWidth,
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
      width: widget.tankWidth,
      height: widget.height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Curved elliptical water surface crown at top of tank
          Positioned(
            bottom: -5,
            left: 2,
            right: 2,
            child: IgnorePointer(
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFB8EEF7),
                      Color(0xFFDCF9FE),
                      Color(0xFFB8EEF7),
                    ],
                  ),
                  borderRadius: const BorderRadius.all(Radius.elliptical(180, 10)),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.85),
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),

          // Bobbing boat mascot
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final phase = _animController.value * 2 * pi;
              final waveY = sin(phase) * 2.0 + (widget.isHappy ? -4.0 : 0.0);
              final tilt = sin(phase * 0.8) * 0.025;

              return Transform.translate(
                offset: Offset(0, waveY - 1.0),
                child: Transform.rotate(
                  angle: tilt,
                  child: Image.asset(
                    'assets/images/sprites/ui/boat_mascot.png',
                    height: widget.height - 2.0,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
