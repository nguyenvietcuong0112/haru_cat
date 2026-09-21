import 'dart:math';
import 'package:flutter/material.dart';
import '../../logic/game_controller.dart';
import '../../utils/constants.dart';
import 'cat_block_widget.dart';
import 'board_effects_overlay.dart';

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
  Offset _shakeOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isEndless = controller.mode == GameMode.endless;

        // Calculate available space, reserving space for top boat mascot
        const outerPadding = 5.0;
        const outerBorder = 3.0;
        const extraSpace = (outerPadding + outerBorder) * 2; // 16.0
        const boatHeight = 38.0;

        final availableW = constraints.maxWidth - extraSpace - 8;
        final availableH = constraints.maxHeight - extraSpace - 16 - boatHeight;

        // In endless mode: 10 active rows (0..9) + 1 preview row (-1) = 11 total rows
        final totalRows = isEndless ? (GameConstants.boardRows + 1) : GameConstants.boardRows;

        final cellByWidth = availableW / GameConstants.boardCols;
        final cellByHeight = availableH / totalRows;
        final cellSize = (cellByWidth < cellByHeight ? cellByWidth : cellByHeight).floorToDouble();

        final boardW = cellSize * GameConstants.boardCols;
        final boardH = cellSize * totalRows;

        return Center(
          child: Transform.translate(
            offset: _shakeOffset,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 0. Cute Floating Boat Mascot on surface of water tank
                _FloatingBoatWidget(
                  isHappy: controller.clearingRowIndex != null,
                  width: min(boardW * 0.42, 130.0),
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
                        // 1. Grid Slots for all rows (10 active + 1 preview if endless)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(totalRows, (r) {
                            final isPreviewRow = isEndless && r == totalRows - 1;
                            return SizedBox(
                              width: boardW,
                              height: cellSize,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(GameConstants.boardCols, (c) {
                                  return SizedBox(
                                    width: cellSize,
                                    height: cellSize,
                                    child: Padding(
                                      padding: const EdgeInsets.all(0.8),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                          color: isPreviewRow
                                              ? const Color(0xFF006064).withOpacity(0.28)
                                              : Colors.white.withOpacity(0.22),
                                          border: Border.all(
                                            color: const Color(0xFF80DEEA).withOpacity(0.45),
                                            width: 0.8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            );
                          }),
                        ),

                        // 2. Preview Divider Bar (Separates active board rows 0-9 from preview row -1)
                        if (isEndless)
                          Positioned(
                            top: GameConstants.boardRows * cellSize - 2,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF006064),
                                    Color(0xFF00838F),
                                    Color(0xFF006064),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    offset: const Offset(0, 2),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // 3. Danger Ceiling Line (Top row warning)
                        Positioned(
                          top: cellSize * 1,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),

                        // 4. Preview Indicator Badge in bottom-left
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

                        // 5. Active Cat Blocks on Board (Rows 0..9)
                        ...controller.blocks.map((block) {
                          return CatBlockWidget(
                            key: ValueKey(block.id),
                            block: block,
                            cellSize: cellSize,
                            controller: controller,
                          );
                        }),

                        // 6. Preview Cat Blocks (Row -1)
                        if (isEndless)
                          ...controller.nextRowBlocks.map((block) {
                            return CatBlockWidget(
                              key: ValueKey(block.id),
                              block: block,
                              cellSize: cellSize,
                              controller: controller,
                              isPreview: true,
                            );
                          }),

                        // 7. Dynamic Board Effects Overlay (Particles, Laser Slices, Floating Scores)
                        Positioned.fill(
                          child: BoardEffectsOverlay(
                            controller: controller,
                            cellSize: cellSize,
                            boardWidth: boardW,
                            boardHeight: boardH,
                            onShakeUpdate: (offset) {
                              if (mounted) {
                                setState(() {
                                  _shakeOffset = offset;
                                });
                              }
                            },
                          ),
                        ),

                        // 8. Booster Selection Overlay Notice
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
          ),
        );
      },
    );
  }
}

/// Floating Boat Mascot that bobs gently on the water tank waves
class _FloatingBoatWidget extends StatefulWidget {
  final bool isHappy;
  final double width;

  const _FloatingBoatWidget({
    required this.isHappy,
    required this.width,
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
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final phase = _animController.value * 2 * pi;
        final waveY = sin(phase) * 2.2 + (widget.isHappy ? -6.0 : 0.0);
        final tilt = sin(phase * 0.8) * 0.025;

        return Transform.translate(
          offset: Offset(0, waveY),
          child: Transform.rotate(
            angle: tilt,
            child: Image.asset(
              'assets/images/sprites/ui/boat_mascot.png',
              width: widget.width,
              height: widget.width * 0.5,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
