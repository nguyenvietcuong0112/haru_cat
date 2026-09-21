import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haru_cats/logic/game_controller.dart';
import 'package:haru_cats/models/block.dart';
import 'package:haru_cats/ui/widgets/game_board.dart';

void main() {
  testWidgets('Capture GameBoard screenshot', (tester) async {
    final controller = GameController(mode: GameMode.endless);

    // Setup some sample blocks
    controller.blocks.clear();
    controller.blocks.addAll([
      CatBlock(id: 'b1', col: 0, row: 0, width: 2, type: BlockType.cat3),
      CatBlock(id: 'b2', col: 4, row: 0, width: 4, type: BlockType.cat1),
      CatBlock(id: 'b3', col: 1, row: 1, width: 2, type: BlockType.lightning),
      CatBlock(id: 'b4', col: 4, row: 1, width: 2, type: BlockType.cat1),
      CatBlock(id: 'b5', col: 6, row: 1, width: 2, type: BlockType.cat2),
    ]);

    // Set sample next row
    controller.nextRowBlocks.clear();
    controller.nextRowBlocks.addAll([
      CatBlock(id: 'n1', col: 0, row: 0, width: 2, type: BlockType.cat2),
      CatBlock(id: 'n2', col: 3, row: 0, width: 1, type: BlockType.cat1),
      CatBlock(id: 'n3', col: 4, row: 0, width: 2, type: BlockType.cat1),
      CatBlock(id: 'n4', col: 7, row: 0, width: 1, type: BlockType.lightning),
    ]);

    final repaintKey = GlobalKey();

    await tester.binding.setSurfaceSize(const Size(400, 700));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF5D4037),
          body: Center(
            child: RepaintBoundary(
              key: repaintKey,
              child: SizedBox(
                width: 380,
                height: 550,
                child: GameBoard(controller: controller),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final file = File(r'C:\Users\cuong\.gemini\antigravity\brain\33b67799-850b-4d81-9994-9a94a7f71db3\.tempmediaStorage\current_flutter_board.png');
    await file.writeAsBytes(pngBytes);
    print('Board screenshot captured to current_flutter_board.png');
  });
}
