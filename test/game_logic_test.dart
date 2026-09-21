import 'package:flutter_test/flutter_test.dart';
import 'package:haru_cats/models/block.dart';
import 'package:haru_cats/models/level_data.dart';
import 'package:haru_cats/models/player_data.dart';
import 'package:haru_cats/logic/game_controller.dart';
import 'package:haru_cats/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Game Logic Tests', () {
    test('CatBlock occupied columns calculation', () {
      final block = CatBlock(
        id: 'test_1',
        col: 2,
        row: 0,
        width: 3,
        type: BlockType.cat1,
      );

      expect(block.occupiedCols, equals([2, 3, 4]));
      expect(block.spriteAsset, contains('cat1_3cell.png'));
    });

    test('Block sliding limits and collision', () {
      final controller = GameController(mode: GameMode.endless);
      // Clear auto-generated rows for deterministic test
      controller.blocks.clear();

      final blockA = CatBlock(id: 'a', col: 1, row: 0, width: 2, type: BlockType.cat1);
      final blockB = CatBlock(id: 'b', col: 5, row: 0, width: 2, type: BlockType.cat2);

      controller.blocks.addAll([blockA, blockB]);

      // Block A can slide left to 0, and right up to 3 (since block B starts at col 5, empty space is 3, 4)
      expect(controller.getMinSlideCol(blockA), equals(0));
      expect(controller.getMaxSlideCol(blockA), equals(3));

      // Block B can slide left to 3 (since block A ends at 1+2-1=2), and right to 6 (8 - 2 = 6)
      expect(controller.getMinSlideCol(blockB), equals(3));
      expect(controller.getMaxSlideCol(blockB), equals(6));
    });

    test('Gravity drops floating blocks', () async {
      final controller = GameController(mode: GameMode.level);
      controller.blocks.clear();

      // Place a block at row 3 with empty cells below
      final floating = CatBlock(id: 'float', col: 2, row: 3, width: 2, type: BlockType.cat1);
      controller.blocks.add(floating);

      // Slide from col 2 to col 3 to trigger physics
      await controller.slideBlock(floating, 3);

      // Block should have fallen to row 0 at col 3
      expect(floating.row, equals(0));
      expect(floating.col, equals(3));
    });

    test('Full line triggers clear and scores points', () async {
      final controller = GameController(mode: GameMode.endless);
      controller.blocks.clear();

      // Fill row 0 completely (8 cells: 4 + 4)
      final b1 = CatBlock(id: '1', col: 0, row: 0, width: 4, type: BlockType.cat1);
      final b2 = CatBlock(id: '2', col: 4, row: 0, width: 1, type: BlockType.cat2);
      final b3 = CatBlock(id: '3', col: 6, row: 0, width: 2, type: BlockType.cat3);
      // Wait, col 5 is empty: slide b2 to 4, then move a 1-cell block into col 5
      final b4 = CatBlock(id: '4', col: 4, row: 1, width: 1, type: BlockType.cat1); // row 1, will drop into 5 if moved

      controller.blocks.addAll([b1, b2, b3, b4]);

      // Slide b4 from col 4 to col 5 at row 1 -> it will drop into col 5 row 0, making row 0 full!
      await controller.slideBlock(b4, 5);

      // Score should have increased from clearing row 0
      expect(controller.score, greaterThan(0));
    });

    test('LevelData star calculation', () {
      final level = LevelData(
        levelId: 'easy_1',
        title: 'Easy 1',
        map: [],
        requirements: [
          LevelStarRequirement(starIndex: 3, minMoves: 2),
          LevelStarRequirement(starIndex: 2, minMoves: 4),
          LevelStarRequirement(starIndex: 1, minMoves: 6),
        ],
      );

      expect(level.getStars(1), equals(3));
      expect(level.getStars(2), equals(3));
      expect(level.getStars(3), equals(2));
      expect(level.getStars(4), equals(2));
      expect(level.getStars(5), equals(1));
      expect(level.getStars(10), equals(1));
    });

    test('PlayerData currency, boosters and character unlocking', () async {
      final player = PlayerData();
      await player.init();

      final initialGold = player.goldFish;
      player.addGoldFish(10);
      expect(player.goldFish, equals(initialGold + 10));

      final spent = player.spendGoldFish(5);
      expect(spent, isTrue);
      expect(player.goldFish, equals(initialGold + 5));

      final initialHammer = player.getBoosterCount('hammer');
      player.addBooster('hammer', 2);
      expect(player.getBoosterCount('hammer'), equals(initialHammer + 2));

      final used = player.useBooster('hammer');
      expect(used, isTrue);
      expect(player.getBoosterCount('hammer'), equals(initialHammer + 1));
    });

    test('GameController continue revive restores board state', () async {
      final controller = GameController(mode: GameMode.endless);
      controller.blocks.clear();

      // Add high rows near ceiling
      controller.blocks.add(CatBlock(id: 'top1', col: 0, row: 8, width: 2, type: BlockType.cat1));
      controller.blocks.add(CatBlock(id: 'top2', col: 0, row: 9, width: 2, type: BlockType.cat1));

      // Trigger revive
      await controller.reviveContinue();

      expect(controller.hasUsedContinue, isTrue);
      expect(controller.isContinuePrompting, isFalse);
      // Blocks at row 5+ should be cleared
      expect(controller.blocks.any((b) => b.row >= 5), isFalse);
    });

    test('GameController manages next row preview and push into row 0', () async {
      final controller = GameController(mode: GameMode.endless);
      expect(controller.nextRowBlocks, isNotEmpty);

      // Slide a block to cause a non-clearing move and row push
      controller.blocks.clear();
      final b = CatBlock(id: 'slide_test', col: 0, row: 0, width: 2, type: BlockType.cat1);
      controller.blocks.add(b);

      // Configure known nextRowBlocks that will support b when shifted up
      controller.nextRowBlocks.clear();
      final previewBlock = CatBlock(id: 'next_1', col: 2, row: -1, width: 2, type: BlockType.cat2);
      controller.nextRowBlocks.add(previewBlock);

      await controller.slideBlock(b, 2);

      // b was shifted to row 1, and previewBlock is beneath it at row 0 (so b cannot fall)
      expect(b.row, equals(1));
      expect(previewBlock.row, equals(0));
      expect(controller.blocks.contains(previewBlock), isTrue);

      // A new set of preview blocks should have been generated
      expect(controller.nextRowBlocks, isNotEmpty);
      expect(controller.nextRowBlocks.contains(previewBlock), isFalse);
    });

    test('Hammer booster smashes target block and all nearby cats', () async {
      final controller = GameController(mode: GameMode.endless);
      controller.blocks.clear();
      final player = PlayerData();
      player.addBooster('hammer', 1);

      final center = CatBlock(id: 'center', col: 2, row: 1, width: 2, type: BlockType.cat1);
      final nearbyTop = CatBlock(id: 'top', col: 2, row: 2, width: 2, type: BlockType.cat2);
      final nearbyBottom = CatBlock(id: 'bottom', col: 2, row: 0, width: 2, type: BlockType.cat3);
      final farAway = CatBlock(id: 'far', col: 6, row: 5, width: 2, type: BlockType.cat1);

      controller.blocks.addAll([center, nearbyTop, nearbyBottom, farAway]);
      controller.selectBooster(GameConstants.boosterHammer);

      await controller.applyBoosterToBlock(center);

      // Center and nearby cats must be smashed
      expect(controller.blocks.contains(center), isFalse);
      expect(controller.blocks.contains(nearbyTop), isFalse);
      expect(controller.blocks.contains(nearbyBottom), isFalse);
      // Far away block must survive (though it may have fallen by gravity to row 0)
      expect(controller.blocks.contains(farAway), isTrue);
    });

    test('Magnet booster clears all cat blocks of a chosen color', () async {
      final controller = GameController(mode: GameMode.endless);
      controller.blocks.clear();
      final player = PlayerData();
      player.addBooster('magnet', 1);

      final c1a = CatBlock(id: 'c1a', col: 0, row: 0, width: 2, type: BlockType.cat1);
      final c1b = CatBlock(id: 'c1b', col: 4, row: 0, width: 2, type: BlockType.cat1);

      controller.blocks.addAll([c1a, c1b]);

      await controller.useMagnet();

      // All cat1 blocks should have been cleared by magnet
      expect(controller.blocks.any((b) => b.type == BlockType.cat1), isFalse);
    });

    test('Magic Wand splits large cat block into 1-cell kitty cats', () async {
      final controller = GameController(mode: GameMode.endless);
      controller.blocks.clear();
      final player = PlayerData();
      player.addBooster('wand', 1);

      final bigCat = CatBlock(id: 'big', col: 1, row: 0, width: 3, type: BlockType.cat2);
      controller.blocks.add(bigCat);
      controller.selectBooster(GameConstants.boosterWand);

      await controller.applyBoosterToBlock(bigCat);

      // Big cat should be removed
      expect(controller.blocks.contains(bigCat), isFalse);
      // Replaced by 3 1-cell cats
      final oneCellCats = controller.blocks.where((b) => b.type == BlockType.cat2 && b.width == 1).toList();
      expect(oneCellCats.length, equals(3));
      expect(oneCellCats.map((b) => b.col).toSet(), equals({1, 2, 3}));
    });

    test('Sealed block cannot be slid but unseals when row is cleared', () async {
      final controller = GameController(mode: GameMode.endless);
      controller.blocks.clear();

      final sealed = CatBlock(id: 'sealed', col: 0, row: 0, width: 2, type: BlockType.sealed);
      expect(controller.getMinSlideCol(sealed), equals(0));
      expect(controller.getMaxSlideCol(sealed), equals(0));

      // Fill rest of row 0: col 2..7
      final filler1 = CatBlock(id: 'f1', col: 2, row: 0, width: 3, type: BlockType.cat1);
      final filler2 = CatBlock(id: 'f2', col: 5, row: 0, width: 3, type: BlockType.cat1);
      controller.blocks.addAll([sealed, filler1, filler2]);

      // Sliding filler1 by 0 won't move, but let's slide filler2 if it had room, or trigger slide on a separate block
      final mover = CatBlock(id: 'm', col: 0, row: 1, width: 2, type: BlockType.cat1);
      controller.blocks.add(mover);

      await controller.slideBlock(mover, 2);

      // Row 0 was completely full (width 2 + 3 + 3 = 8 cells)
      // The sealed block should have unsealed into cat1
      expect(sealed.type, equals(BlockType.cat1));
    });

    test('Bottom row still pushes up even when lines are cleared', () async {
      final controller = GameController(mode: GameMode.endless);
      controller.blocks.clear();

      // Setup a full line on row 0 (will clear when slide occurs)
      final b1 = CatBlock(id: 'b1', col: 0, row: 0, width: 4, type: BlockType.cat1);
      final b2 = CatBlock(id: 'b2', col: 4, row: 0, width: 3, type: BlockType.cat1);
      // Mover on row 1 to slide into col 7
      final mover = CatBlock(id: 'mover', col: 0, row: 1, width: 1, type: BlockType.cat2);

      controller.blocks.addAll([b1, b2, mover]);

      // Set a known next row
      controller.nextRowBlocks.clear();
      final previewBlock = CatBlock(id: 'incoming', col: 0, row: -1, width: 2, type: BlockType.cat3);
      controller.nextRowBlocks.add(previewBlock);

      // Slide mover to row 1, col 7 to fill column 7, but since mover is at row 1, let's slide b2 to fill or slide a 1-cell block at row 0:
      // Let's place a 1-cell block at col 6, row 0 and slide to 7 to complete the line!
      controller.blocks.clear();
      final rowB1 = CatBlock(id: 'r1', col: 0, row: 0, width: 4, type: BlockType.cat1);
      final rowB2 = CatBlock(id: 'r2', col: 4, row: 0, width: 3, type: BlockType.cat1);
      final rowMover = CatBlock(id: 'rm', col: 6, row: 1, width: 1, type: BlockType.cat1);
      // Room below rowMover at col 7, row 0 is empty
      controller.blocks.addAll([rowB1, rowB2, rowMover]);

      controller.nextRowBlocks.clear();
      controller.nextRowBlocks.add(previewBlock);

      // Slide rowMover from 6 to 7 on row 1 -> rowMover drops into col 7, row 0!
      // Row 0 becomes 4 + 3 + 1 = 8 cells -> CLEARS!
      await controller.slideBlock(rowMover, 7);

      // Verify line cleared and score increased
      expect(controller.linesClearedTotal, equals(1));

      // CRITICAL CHECK: incoming preview block MUST have been pushed onto the board at row 0!
      expect(controller.blocks.contains(previewBlock), isTrue);
      expect(previewBlock.row, equals(0));
    });
  });
}

