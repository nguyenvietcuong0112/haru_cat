import 'package:flutter/material.dart';
import '../../models/block.dart';
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
        final availableW = constraints.maxWidth - 20;
        final availableH = constraints.maxHeight - 20;

        final cellByWidth = availableW / GameConstants.boardCols;
        final cellByHeight = isEndless
            ? (availableH - 30) / (GameConstants.boardRows + 0.55)
            : (availableH - 20) / GameConstants.boardRows;
        final cellSize = (cellByWidth < cellByHeight ? cellByWidth : cellByHeight).floorToDouble();

        final boardW = cellSize * GameConstants.boardCols;
        final boardH = cellSize * GameConstants.boardRows;

        // Authentic trough sizing based on gameplay_main_board_02.png (981x58, groove y: 14..48)
        final troughH = ((boardW + 16) * (58.0 / 981.0)).clamp(20.0, 28.0);
        final troughTopPad = troughH * (14.0 / 58.0);
        final grooveH = troughH * (35.0 / 58.0);

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Main Game Board with authentic wooden frame (gameplay_main_board_01)
              Container(
                width: boardW + 16,
                height: boardH + 16,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/sprites/ui/gameplay_main_board_01.png'),
                    centerSlice: Rect.fromLTRB(20, 20, 140, 140),
                    fit: BoxFit.fill,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Container(
                  width: boardW,
                  height: boardH,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E0CE), // Warm wood inner board tint
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      // 1. Authentic wooden slots for each grid cell
                      Column(
                        children: List.generate(GameConstants.boardRows, (r) {
                          return Row(
                            children: List.generate(GameConstants.boardCols, (c) {
                              return SizedBox(
                                width: cellSize,
                                height: cellSize,
                                child: Padding(
                                  padding: const EdgeInsets.all(0.8),
                                  child: Image.asset(
                                    'assets/images/sprites/ui/gameplay_table_slot.png',
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              );
                            }),
                          );
                        }),
                      ),

                      // 2. Danger Ceiling Line (Top row warning)
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

                      // 3. Cat Blocks
                      ...controller.blocks.map((block) {
                        return CatBlockWidget(
                          key: ValueKey(block.id),
                          block: block,
                          cellSize: cellSize,
                          controller: controller,
                        );
                      }),

                      // 4. Booster Selection Overlay Notice
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
                                  ? '🔨 Chạm vào khối mèo để đập tan nó và mèo xung quanh!'
                                  : '🪄 Chạm vào mèo lớn (2-4 ô) để chia nhỏ thành mèo con!',
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

              // 2. Bottom Preview Trough (Endless mode upcoming row, snugly attached)
              if (isEndless) ...[
                const SizedBox(height: 3),
                Container(
                  width: boardW + 16,
                  height: troughH,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/sprites/ui/gameplay_main_board_02.png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: Stack(
                    children: controller.nextRowBlocks.map((block) {
                      return Positioned(
                        left: 8.0 + block.col * cellSize,
                        width: block.width * cellSize,
                        top: troughTopPad,
                        height: grooveH,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.0),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                block.previewSpriteAsset,
                                fit: BoxFit.fill,
                              ),
                              if (block.type == BlockType.sealed)
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(1.5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF263238),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.lock,
                                      color: Color(0xFFFFD54F),
                                      size: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
