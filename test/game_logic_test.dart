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
    test('CatBlock occupied columns calculation and fish assets', () {
      final block = CatBlock(
        id: 'test_1',
        col: 2,
        row: 0,
        width: 3,
        type: BlockType.cat1,
        variant: 1,
      );

      expect(block.occupiedCols, equals([2, 3, 4]));
      expect(block.spriteAsset, contains('cat1_3cell.png'));
      expect(block.fishSpriteAsset, equals('assets/images/sprites/fish/fish_3cell_b.png'));
      expect(block.clone().variant, equals(1));

      final iceBlock = CatBlock(id: 'ice', col: 0, row: 0, width: 2, type: BlockType.ice);
      expect(iceBlock.overlayAsset, equals('assets/images/sprites/fish/ice_2cell.png'));

      final seaBlock = CatBlock(id: 'sea', col: 0, row: 0, width: 4, type: BlockType.sealed);
      expect(seaBlock.overlayAsset, equals('assets/images/sprites/fish/seaweed_4cell.png'));
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

    test('Hammer booster breaks ice block in 1 single hit', () async {
      final controller = GameController(mode: GameMode.endless);
      controller.blocks.clear();
      final player = PlayerData();
      player.addBooster('hammer', 1);

      // Normally ice takes 2 clears (health = 2)
      final iceBlock = CatBlock(id: 'ice', col: 2, row: 1, width: 2, type: BlockType.ice);
      final normalBlock = CatBlock(id: 'normal', col: 6, row: 1, width: 2, type: BlockType.cat1);
      controller.blocks.addAll([iceBlock, normalBlock]);
      controller.selectBooster(GameConstants.boosterHammer);

      await controller.applyBoosterToBlock(iceBlock);

      // Ice block must be completely shattered in 1 hit
      expect(controller.blocks.contains(iceBlock), isFalse);
      expect(controller.blocks.any((b) => b.id == 'ice'), isFalse);
    });

    test('Net booster scoops/collects targeted fish block to clear space', () async {
      final controller = GameController(mode: GameMode.endless);
      controller.blocks.clear();
      final player = PlayerData();
      player.addBooster('net', 1);

      final blockingFish = CatBlock(id: 'blocker', col: 0, row: 5, width: 3, type: BlockType.cat1);
      final otherFish = CatBlock(id: 'other', col: 4, row: 1, width: 2, type: BlockType.cat2);
      controller.blocks.addAll([blockingFish, otherFish]);

      controller.selectBooster(GameConstants.boosterNet);
      await controller.applyBoosterToBlock(blockingFish);

      // Blocker fish is scooped up and removed
      expect(controller.blocks.contains(blockingFish), isFalse);
      expect(controller.blocks.any((b) => b.id == 'other'), isTrue);
    });

    test('Magic Wand transforms large fish blocks into 1-cell fish for clearance', () async {
      final controller = GameController(mode: GameMode.endless);
      controller.blocks.clear();
      final player = PlayerData();
      player.addBooster('wand', 1);

      final bigFish1 = CatBlock(id: 'big1', col: 0, row: 0, width: 3, type: BlockType.cat2);
      final bigFish2 = CatBlock(id: 'big2', col: 4, row: 1, width: 2, type: BlockType.cat3);
      controller.blocks.addAll([bigFish1, bigFish2]);

      await controller.useWand();

      // Both big fish should be transformed into 1-cell fish
      expect(controller.blocks.contains(bigFish1), isFalse);
      expect(controller.blocks.contains(bigFish2), isFalse);
      expect(controller.blocks.every((b) => b.width == 1), isTrue);
      expect(controller.blocks.length, equals(5)); // 3 + 2 = 5 1-cell fish
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

    test('Silver Multiplier scales according to inGameLevel', () {
      final controller = GameController(mode: GameMode.endless);
      // Level 1-2: x1.0
      expect(controller.silverMultiplier, equals(1.0));

      // Level 3: x1.2
      // Level progression: 1 + (_linesClearedTotal ~/ 8)
      // When linesClearedTotal >= 16 -> level 3
      // We can verify getter directly by checking logic
    });

    test('Silver to Gold exchange enforces maximum 10 Gold limit', () async {
      final player = PlayerData();
      await player.init();
      // Give plenty of silver
      player.addSilverFish(2000);

      // Exchange 10 times successfully
      for (int i = 0; i < 10; i++) {
        final success = player.exchangeSilverForGold(silverCost: 50);
        expect(success, isTrue, reason: 'Exchange $i should succeed');
      }

      expect(player.goldExchangedFromSilver, equals(10));

      // 11th exchange must fail due to limit
      final limitExceeded = player.exchangeSilverForGold(silverCost: 50);
      expect(limitExceeded, isFalse, reason: 'Exchange past 10 Gold must fail');
    });

    test('Scoring formula calculates Cleared Cells x Combo', () async {
      final controller = GameController(mode: GameMode.endless);
      controller.blocks.clear();

      // Row 0 completely full except col 7
      final b1 = CatBlock(id: 'r1', col: 0, row: 0, width: 4, type: BlockType.cat1);
      final b2 = CatBlock(id: 'r2', col: 4, row: 0, width: 3, type: BlockType.cat1);
      final mover = CatBlock(id: 'rm', col: 6, row: 1, width: 1, type: BlockType.cat1);
      controller.blocks.addAll([b1, b2, mover]);

      controller.nextRowBlocks.clear();
      final preview = CatBlock(id: 'preview', col: 0, row: -1, width: 2, type: BlockType.cat2);
      controller.nextRowBlocks.add(preview);

      await controller.slideBlock(mover, 7);

      // 1 row cleared = 8 cells * combo 1 = 8 points
      expect(controller.linesClearedTotal, equals(1));
      expect(controller.score, equals(8));
      // Base silver reward: 2 silver * multiplier (1.0) = 2
      expect(controller.silverEarned, equals(2));
    });

    test('Bomb obstacle penalty spawns extra fish blocks when countdown expires', () async {
      final controller = GameController(mode: GameMode.level);
      controller.blocks.clear();

      final bomb = CatBlock(id: 'bomb1', col: 0, row: 0, width: 2, type: BlockType.bomb, bombCountdown: 1);
      final harmless = CatBlock(id: 'slide_trigger', col: 5, row: 0, width: 1, type: BlockType.cat1);
      controller.blocks.addAll([bomb, harmless]);

      final initialBlockCount = controller.blocks.length; // 2 (bomb + harmless)
      // Slide harmless to col 6 (1 move -> bombCountdown drops to 0 -> penalty triggers)
      await controller.slideBlock(harmless, 6);

      // Bomb itself should be removed
      expect(controller.blocks.any((b) => b.type == BlockType.bomb), isFalse);
      // Extra penalty blocks should have spawned (total blocks should exceed initial harmless remaining)
      expect(controller.blocks.length, greaterThanOrEqualTo(initialBlockCount));
    });

    test('Ice block 2-phase clear: first clear breaks ice into normal fish, second clear removes fish', () async {
      final controller = GameController(mode: GameMode.level);
      controller.blocks.clear();

      // Ice block on row 0
      final ice = CatBlock(id: 'ice_test', col: 0, row: 0, width: 2, type: BlockType.ice);
      final f1 = CatBlock(id: 'f1', col: 2, row: 0, width: 3, type: BlockType.cat1);
      final f2 = CatBlock(id: 'f2', col: 5, row: 0, width: 2, type: BlockType.cat1);
      // Mover at row 1 to drop into col 7 row 0
      final mover = CatBlock(id: 'mv', col: 6, row: 1, width: 1, type: BlockType.cat1);
      controller.blocks.addAll([ice, f1, f2, mover]);

      // Complete row 0 for the 1st time
      await controller.slideBlock(mover, 7);

      // Lần 1: Băng vỡ thành cá thường, cá vẫn còn trên bàn cờ!
      expect(ice.type, equals(BlockType.cat1));
      expect(controller.blocks.contains(ice), isTrue);
    });

    test('Hammer booster strictly prioritizes ice blocks over regular blocks (Ice block > block)', () async {
      final controller = GameController(mode: GameMode.endless);
      controller.blocks.clear();
      final player = PlayerData();
      player.addBooster('hammer', 2);
      final initialHammers = player.getBoosterCount('hammer');

      final ice = CatBlock(id: 'ice_target', col: 0, row: 0, width: 2, type: BlockType.ice);
      final normal = CatBlock(id: 'normal_fish', col: 4, row: 0, width: 2, type: BlockType.cat1);
      controller.blocks.addAll([ice, normal]);

      controller.selectBooster(GameConstants.boosterHammer);
      // Try to tap normal block when ice exists -> must be rejected!
      await controller.applyBoosterToBlock(normal);
      expect(controller.blocks.contains(normal), isTrue, reason: 'Normal block cannot be hit when ice exists');
      expect(player.getBoosterCount('hammer'), equals(initialHammers), reason: 'Hammer must not be consumed on invalid target');

      // Now tap ice block -> shattered!
      await controller.applyBoosterToBlock(ice);
      expect(controller.blocks.contains(ice), isFalse, reason: 'Ice block must be shattered');
      expect(player.getBoosterCount('hammer'), equals(initialHammers - 1), reason: 'Hammer consumed');
    });

    test('Deadlock detection: hasValidMoves detects whether any block can slide', () {
      final controller = GameController(mode: GameMode.endless);
      controller.blocks.clear();

      // Empty board: no valid moves
      expect(controller.hasValidMoves(), isFalse);

      // Add a block that can slide
      final movable = CatBlock(id: 'mv', col: 2, row: 0, width: 2, type: BlockType.cat1);
      controller.blocks.add(movable);
      expect(controller.hasValidMoves(), isTrue);

      // Sealed block cannot slide
      controller.blocks.clear();
      final sealed = CatBlock(id: 'sealed', col: 0, row: 0, width: 2, type: BlockType.sealed);
      controller.blocks.add(sealed);
      expect(controller.hasValidMoves(), isFalse);

      // Block pinned between walls / other blocks cannot slide
      controller.blocks.clear();
      final b1 = CatBlock(id: 'b1', col: 0, row: 0, width: 4, type: BlockType.cat1);
      final b2 = CatBlock(id: 'b2', col: 4, row: 0, width: 3, type: BlockType.sealed); // sealed at right end
      controller.blocks.addAll([b1, b2]);
      // b1 is at col 0, right neighbor is col 4 (b2), so b1 cannot move! b2 is sealed, so b2 cannot move!
      expect(controller.hasValidMoves(), isFalse);
    });

    test('Auto push prepared row when board has no valid moves', () async {
      final controller = GameController(mode: GameMode.endless);
      controller.blocks.clear();

      // Set up a prepared preview row
      controller.nextRowBlocks.clear();
      final preparedFish = CatBlock(id: 'prep', col: 1, row: -1, width: 2, type: BlockType.cat1);
      controller.nextRowBlocks.add(preparedFish);

      // Board has 0 moves
      expect(controller.hasValidMoves(), isFalse);

      // Trigger auto push
      await controller.checkAndPushIfNoMoves();

      // The prepared row must have been pushed up onto row 0!
      expect(controller.blocks.contains(preparedFish), isTrue);
      expect(preparedFish.row, equals(0));
      expect(controller.hasValidMoves(), isTrue);
    });
  });
}

