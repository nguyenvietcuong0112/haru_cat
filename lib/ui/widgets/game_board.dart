import 'package:flutter/material.dart';
import '../../logic/game_controller.dart';
import '../../utils/constants.dart';
import 'cat_block_widget.dart';

class GameBoard extends StatelessWidget {
  final GameController controller;

  const GameBoard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isEndless = controller.mode == GameMode.endless;

        // Calculate available space
        const outerPadding = 5.0;
        const outerBorder = 3.0;
        const extraSpace = (outerPadding + outerBorder) * 2; // 16.0

        final availableW = constraints.maxWidth - extraSpace - 8;
        final availableH = constraints.maxHeight - extraSpace - 16;

        // In endless mode: 10 active rows (0..9) + 1 preview row (-1) = 11 total rows
        final totalRows = isEndless ? (GameConstants.boardRows + 1) : GameConstants.boardRows;

        final cellByWidth = availableW / GameConstants.boardCols;
        final cellByHeight = availableH / totalRows;
        final cellSize = (cellByWidth < cellByHeight ? cellByWidth : cellByHeight).floorToDouble();

        final boardW = cellSize * GameConstants.boardCols;
        final boardH = cellSize * totalRows;

        return Center(
          child: Container(
            padding: const EdgeInsets.all(outerPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF80DEEA), width: outerBorder),
              color: const Color(0xFFE0F7FA).withValues(alpha: 0.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF006064).withValues(alpha: 0.18),
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
                                      ? const Color(0xFF006064).withValues(alpha: 0.28) // Submerged seabed tint
                                      : Colors.white.withValues(alpha: 0.22),
                                  border: Border.all(
                                    color: const Color(0xFF80DEEA).withValues(alpha: 0.45),
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
                              color: Colors.black.withValues(alpha: 0.35),
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
                        color: Colors.red.withValues(alpha: 0.45),
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
                            color: Colors.black.withValues(alpha: 0.45),
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

                  // 6. Preview Cat Blocks (Row -1) - IDENTICAL UI, SIZE & ARTWORK!
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

                  // 7. Luminous Row Clearing Beam Overlay (Edge-to-edge row clear effect)
                  if (controller.clearingRowIndex != null)
                    Positioned(
                      top: (GameConstants.boardRows - 1 - controller.clearingRowIndex!) * cellSize,
                      left: 0,
                      right: 0,
                      height: cellSize,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.65),
                                const Color(0xFF00E5FF).withValues(alpha: 0.45),
                                Colors.white.withValues(alpha: 0.65),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.7),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
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
                          color: Colors.black.withValues(alpha: 0.75),
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
        );
      },
    );
  }
}
