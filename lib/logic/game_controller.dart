import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/block.dart';
import '../models/level_data.dart';
import '../models/player_data.dart';
import '../audio/audio_manager.dart';
import '../utils/constants.dart';

enum GameMode { endless, level }

class ClearedBlockInfo {
  final int col;
  final int width;
  final int points;
  final BlockType blockType;

  ClearedBlockInfo({
    required this.col,
    required this.width,
    required this.points,
    this.blockType = BlockType.cat1,
  });
}

class BrokenObstacleInfo {
  final int col;
  final int width;
  final bool wasIce;

  const BrokenObstacleInfo({
    required this.col,
    required this.width,
    required this.wasIce,
  });
}

class RowClearEvent {
  final int rowIndex;
  final int points;
  final int combo;
  final int timestamp;
  final List<ClearedBlockInfo> blocks;
  final List<BrokenObstacleInfo> brokenObstacles;

  RowClearEvent({
    required this.rowIndex,
    required this.points,
    required this.combo,
    required this.timestamp,
    required this.blocks,
    this.brokenObstacles = const [],
  });
}

class GameController extends ChangeNotifier {
  final GameMode mode;
  final LevelData? levelData;

  final List<CatBlock> _blocks = [];
  List<CatBlock> get blocks => _blocks;

  final List<CatBlock> _nextRowBlocks = [];
  List<CatBlock> get nextRowBlocks => _nextRowBlocks;

  int _score = 0;
  int get score => _score;

  int _bestScore = 0;
  int get bestScore => _bestScore;

  int _moves = 0;
  int get moves => _moves;

  int _combo = 0;
  int get combo => _combo;

  int _inGameLevel = 1;
  int get inGameLevel => _inGameLevel;
  int get scoreMultiplier => _inGameLevel;

  double get silverMultiplier {
    if (_inGameLevel <= 2) return 1.0;
    if (_inGameLevel == 3) return 1.2;
    if (_inGameLevel == 4) return 1.3;
    if (_inGameLevel == 5) return 1.4;
    return 1.5;
  }

  // Character skill meter (0.0 to 1.0)
  double _skillCharge = 0.0;
  double get skillCharge => _skillCharge;
  bool get isSkillReady => _skillCharge >= 1.0;

  // Mascot Speech & Reactions
  String _mascotQuote = 'Meow! Slide left or right to make a line!';
  String get mascotQuote => _mascotQuote;

  // Continue Revive state
  bool _isContinuePrompting = false;
  bool get isContinuePrompting => _isContinuePrompting;
  bool _hasUsedContinue = false;
  bool get hasUsedContinue => _hasUsedContinue;

  // Run statistics
  int _linesClearedTotal = 0;
  int get linesClearedTotal => _linesClearedTotal;
  int _specialBlocksCleared = 0;
  int get specialBlocksCleared => _specialBlocksCleared;
  int _maxCombo = 0;
  int get maxCombo => _maxCombo;
  int _silverEarned = 0;
  int get silverEarned => _silverEarned;

  bool _isGameOver = false;
  bool get isGameOver => _isGameOver;

  bool _isLevelCompleted = false;
  bool get isLevelCompleted => _isLevelCompleted;

  int _starsEarned = 0;
  int get starsEarned => _starsEarned;

  bool _isBusy = false; // Processing gravity / clear animations
  bool get isBusy => _isBusy;

  String? _activeBooster;
  String? get activeBooster => _activeBooster;

  int? _clearingRowIndex; // Currently clearing row index for animated beam effect
  int? get clearingRowIndex => _clearingRowIndex;

  RowClearEvent? _latestClearEvent;
  RowClearEvent? get latestClearEvent => _latestClearEvent;

  int _frozenTurns = 0; // If magician froze upcoming blocks

  final AudioManager _audio = AudioManager();
  final Random _random = Random();
  final PlayerData _playerData = PlayerData();

  GameController({
    required this.mode,
    this.levelData,
  }) {
    initGame();
  }

  Future<void> initGame() async {
    _score = 0;
    _moves = 0;
    _combo = 0;
    _inGameLevel = 1;
    _skillCharge = 0.0;
    _linesClearedTotal = 0;
    _specialBlocksCleared = 0;
    _maxCombo = 0;
    _silverEarned = 0;
    _isGameOver = false;
    _isLevelCompleted = false;
    _isContinuePrompting = false;
    _hasUsedContinue = false;
    _starsEarned = 0;
    _blocks.clear();
    _nextRowBlocks.clear();
    _activeBooster = null;
    _clearingRowIndex = null;
    _latestClearEvent = null;
    _frozenTurns = 0;
    _mascotQuote = 'Meow! Let\'s slide and clear blocks!';

    if (mode == GameMode.level && levelData != null) {
      _loadLevelMap(levelData!);
    } else if (mode == GameMode.endless) {
      _initEndlessBoard();
    }

    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _bestScore = prefs.getInt('best_score') ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  void _loadLevelMap(LevelData data) {
    int idCounter = 1;
    for (int r = 0; r < data.map.length && r < GameConstants.boardRows; r++) {
      final rowBlocks = data.map[r];
      for (final b in rowBlocks) {
        BlockType type = BlockType.cat1;
        if (b.type == 1) type = BlockType.cat2;
        if (b.type == 2) type = BlockType.cat3;
        if (b.type == 3) type = BlockType.ice;

        _blocks.add(CatBlock(
          id: 'lvl_${idCounter++}',
          col: b.startPoint.clamp(0, GameConstants.boardCols - b.size),
          row: r,
          width: b.size.clamp(1, 4),
          type: type,
        ));
      }
    }
  }

  void _initEndlessBoard() {
    // Generate 4 initial rows at the bottom
    for (int r = 0; r < 4; r++) {
      _generateRow(r);
    }
    _generateNextRow();
  }

  void _generateNextRow() {
    _nextRowBlocks.clear();
    _nextRowBlocks.addAll(_createRandomRowBlocks(-1));
  }

  void _generateRow(int r) {
    _blocks.addAll(_createRandomRowBlocks(r));
  }

  List<CatBlock> _createRandomRowBlocks(int r) {
    final result = <CatBlock>[];
    int col = 0;
    final maxTotalWidth = GameConstants.boardCols - (1 + _random.nextInt(2)); // 6 or 7 cells
    int currentTotal = 0;

    while (col < GameConstants.boardCols && currentTotal < maxTotalWidth) {
      if (_random.nextBool() && col < GameConstants.boardCols - 1) {
        col++;
        continue;
      }

      final maxW = min(4, GameConstants.boardCols - col);
      if (maxW < 1) break;

      final w = 1 + _random.nextInt(maxW);
      if (currentTotal + w > maxTotalWidth) break;

      BlockType type = BlockType.values[_random.nextInt(3)]; // cat1, cat2, cat3

      // Chance for special block or gift block
      final specialRoll = _random.nextInt(100);
      if (specialRoll < 4) {
        type = BlockType.bomb;
      } else if (specialRoll < 8) {
        type = BlockType.lightning;
      } else if (specialRoll < 12) {
        type = BlockType.ice;
      } else if (specialRoll < 16) {
        type = BlockType.gift;
      } else if (specialRoll < 20) {
        type = BlockType.sealed;
      }

      // Gift box is strictly 1-cell
      final blockWidth = type == BlockType.gift ? 1 : w;

      result.add(CatBlock(
        id: 'blk_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(10000)}',
        col: col,
        row: r,
        width: blockWidth,
        type: type,
        variant: _random.nextInt(2),
      ));

      col += blockWidth;
      currentTotal += blockWidth;
    }
    return result;
  }

  CatBlock? getBlockAt(int col, int row) {
    for (final b in _blocks) {
      if (b.row == row && col >= b.col && col < b.col + b.width) {
        return b;
      }
    }
    return null;
  }

  bool isCellEmpty(int col, int row, {CatBlock? ignoring}) {
    if (col < 0 || col >= GameConstants.boardCols || row < 0 || row >= GameConstants.boardRows) {
      return false;
    }
    for (final b in _blocks) {
      if (b == ignoring) continue;
      if (b.row == row && col >= b.col && col < b.col + b.width) {
        return false;
      }
    }
    return true;
  }

  // Calculate maximum left and right col a block can slide to
  int getMinSlideCol(CatBlock block) {
    if (block.type == BlockType.sealed) return block.col;
    int minCol = block.col;
    while (minCol > 0 && isCellEmpty(minCol - 1, block.row, ignoring: block)) {
      minCol--;
    }
    return minCol;
  }

  int getMaxSlideCol(CatBlock block) {
    if (block.type == BlockType.sealed) return block.col;
    int maxCol = block.col;
    while (maxCol + block.width < GameConstants.boardCols &&
        isCellEmpty(maxCol + block.width, block.row, ignoring: block)) {
      maxCol++;
    }
    return maxCol;
  }

  /// Checks if any block on the active board (row >= 0) has at least 1 legal slide move.
  bool hasValidMoves() {
    if (_blocks.isEmpty) return false;
    for (final b in _blocks) {
      if (canBlockMove(b)) return true;
    }
    return false;
  }

  /// Checks if a specific block can slide at least 1 cell to the left or right.
  bool canBlockMove(CatBlock block) {
    if (block.row < 0) return false; // Row -1 is preview row, cannot be moved directly
    if (block.type == BlockType.sealed) return false; // Sealed blocks cannot be slid
    final minCol = getMinSlideCol(block);
    final maxCol = getMaxSlideCol(block);
    return minCol < block.col || maxCol > block.col;
  }

  /// Automatically pushes up the prepared row from the bottom if no blocks on the board can move
  Future<void> _ensureBoardHasValidMoves() async {
    if (mode != GameMode.endless || _isGameOver || _isContinuePrompting) return;

    int safetyCounter = 0;
    while (!_isGameOver && !_isContinuePrompting && !hasValidMoves() && safetyCounter < 10) {
      safetyCounter++;
      _mascotQuote = 'No valid moves left! Pushing up the next row...';
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 260));
      await _pushNewRow();
      await _resolvePhysicsAndLines();

      _checkLevelWinOrLoss();
    }
  }

  /// Public method callable by UI / Flame engine when board deadlock is detected
  Future<void> checkAndPushIfNoMoves() async {
    if (mode != GameMode.endless || _isBusy || _isGameOver || _isContinuePrompting) return;
    if (!hasValidMoves()) {
      _isBusy = true;
      try {
        await _ensureBoardHasValidMoves();
      } finally {
        _isBusy = false;
        notifyListeners();
      }
    }
  }

  void setMascotQuote(String quote) {
    _mascotQuote = quote;
    notifyListeners();
  }

  // Player slides block
  Future<void> slideBlock(CatBlock block, int targetCol) async {
    if (_isBusy || _isGameOver || _isLevelCompleted || _isContinuePrompting) return;
    if (block.type == BlockType.sealed) {
      _mascotQuote = 'This fish is tangled in seaweed and cannot slide, meow!';
      notifyListeners();
      return;
    }

    final minCol = getMinSlideCol(block);
    final maxCol = getMaxSlideCol(block);
    final clampedCol = targetCol.clamp(minCol, maxCol);

    if (clampedCol == block.col) {
      notifyListeners();
      return;
    }

    _isBusy = true;
    try {
      block.col = clampedCol;
      _moves++;
      _audio.playDrop();

      // Check bomb countdowns
      final autoExplodedBombs = <CatBlock>[];
      for (final b in _blocks) {
        if (b.type == BlockType.bomb) {
          b.bombCountdown--;
          if (b.bombCountdown <= 0) {
            autoExplodedBombs.add(b);
          }
        }
      }

      if (autoExplodedBombs.isNotEmpty) {
        _audio.playClear();
        int totalPenaltySpawned = 0;

        for (final eb in autoExplodedBombs) {
          // Remove the bomb itself
          _blocks.remove(eb);

          // Penalty: Spawn 2 extra fish blocks into empty cells
          final emptyCells = <Point<int>>[];
          for (int r = 0; r < GameConstants.maxVisibleRows - 1; r++) {
            for (int c = 0; c < GameConstants.boardCols; c++) {
              if (isCellEmpty(c, r)) {
                emptyCells.add(Point(c, r));
              }
            }
          }
          emptyCells.shuffle(_random);
          int spawned = 0;
          for (final pt in emptyCells) {
            if (spawned >= 2) break;
            if (isCellEmpty(pt.x, pt.y)) {
              _blocks.add(CatBlock(
                id: 'penalty_${DateTime.now().microsecondsSinceEpoch}_${pt.x}_${pt.y}',
                col: pt.x,
                row: pt.y,
                width: 1,
                type: BlockType.cat1,
                variant: _random.nextInt(2),
              ));
              spawned++;
              totalPenaltySpawned++;
            }
          }
        }
        _mascotQuote = 'BOOM! Bomb exploded and spawned $totalPenaltySpawned extra fish!';
      }

      notifyListeners();

      // Crisp horizontal snap beat before gravity begins
      await Future.delayed(const Duration(milliseconds: 90));

      // Run step-by-step gravity & top-to-bottom sequential line clear loop
      await _resolvePhysicsAndLines(resetCombo: true);

      if (!_isGameOver && !_isLevelCompleted && !_isContinuePrompting) {
        if (mode == GameMode.endless) {
          if (_frozenTurns > 0) {
            _frozenTurns--;
            _mascotQuote = 'Magician frost hold! Row push paused!';
          } else {
            await Future.delayed(const Duration(milliseconds: 160));
            await _pushNewRow();
            await _resolvePhysicsAndLines(resetCombo: false);
          }

          // Auto-detect deadlock / no valid moves and push prepared row up
          await _ensureBoardHasValidMoves();
        }

        _checkLevelWinOrLoss();
      }
    } finally {
      _combo = 0;
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> _resolvePhysicsAndLines({bool resetCombo = true}) async {
    bool anyClearedTotal = false;
    bool hadAction = true;
    if (resetCombo) {
      _combo = 0;
    }

    // Tracks rows where 100% of blocks were Ice/Sealed and just unsealed in this step,
    // preventing an all-ice row from double-clearing without any new blocks falling.
    final unsealedOnlyRows = <int>{};

    while (hadAction) {
      hadAction = false;

      // 1. Gravity fall: blocks drift smoothly down to rest on rows below
      final hadFall = await _applyGravity();
      if (hadFall) {
        hadAction = true;
        unsealedOnlyRows.clear();
      }

      // 2. Clear ONLY the single topmost full horizontal row (strictly top-to-bottom).
      // After clearing 1 row, loop immediately returns to step 1 (_applyGravity) so upper
      // blocks gradually drift down row-by-row before evaluating the next full row!
      final clearedOneRow = await _checkAndClearTopmostLine(
        hadJustFallen: hadFall,
        unsealedOnlyRows: unsealedOnlyRows,
      );
      if (clearedOneRow) {
        hadAction = true;
        anyClearedTotal = true;
      }
    }

    // Danger check for mascot quote
    final highestRow = _blocks.fold(0, (maxR, b) => b.row > maxR ? b.row : maxR);
    if (highestRow >= 7 && !_isGameOver) {
      _mascotQuote = 'Help me! It\'s getting too close to the top!';
    }

    return anyClearedTotal;
  }

  Future<bool> _applyGravity() async {
    bool fellAny = false;
    int maxDropRows = 0;
    final sortedBlocks = List<CatBlock>.from(_blocks)..sort((a, b) => a.row.compareTo(b.row));
    final fallingBlocks = <CatBlock>[];

    for (final block in sortedBlocks) {
      int targetRow = block.row;
      while (targetRow > 0) {
        bool canDrop = true;
        for (int c = block.col; c < block.col + block.width; c++) {
          if (!isCellEmpty(c, targetRow - 1, ignoring: block)) {
            canDrop = false;
            break;
          }
        }
        if (canDrop) {
          targetRow--;
        } else {
          break;
        }
      }

      if (targetRow != block.row) {
        final dropDistance = block.row - targetRow;
        if (dropDistance > maxDropRows) {
          maxDropRows = dropDistance;
        }
        block.row = targetRow;
        block.isFalling = true;
        fallingBlocks.add(block);
        fellAny = true;
      }
    }

    if (fellAny) {
      _audio.playDrop();
      notifyListeners();

      // Exact physics landing time synced with FishBlockComponent (v0 = 2.8*cell, g = 42*cell)
      final exactFallSec = (-2.8 + sqrt(7.84 + 84.0 * maxDropRows)) / 42.0;
      final fallMs = (exactFallSec * 1000).ceil() + 35;
      await Future.delayed(Duration(milliseconds: fallMs));

      for (final b in fallingBlocks) {
        b.isFalling = false;
      }
      notifyListeners();

      // Settle pause so player clearly sees blocks land, bounce, and fill the row before clearing
      await Future.delayed(const Duration(milliseconds: 150));
    }

    return fellAny;
  }

  /// Scans strictly TOP-TO-BOTTOM and clears at most ONE full horizontal row per call,
  /// allowing gravity to gradually drift upper rows down one step at a time.
  Future<bool> _checkAndClearTopmostLine({
    required bool hadJustFallen,
    required Set<int> unsealedOnlyRows,
  }) async {
    int? targetRow;

    // Strictly TOP-TO-BOTTOM scan: highest full row clears first
    for (int r = GameConstants.boardRows - 1; r >= 0; r--) {
      if (unsealedOnlyRows.contains(r)) continue;
      bool full = true;
      for (int c = 0; c < GameConstants.boardCols; c++) {
        if (isCellEmpty(c, r)) {
          full = false;
          break;
        }
      }
      if (full) {
        targetRow = r;
        break;
      }
    }

    if (targetRow == null) return false;

    // Brief visual confirmation beat so player sees the completed horizontal row edge-to-edge
    await Future.delayed(Duration(milliseconds: hadJustFallen ? 40 : 110));

    final r = targetRow;
    _combo++;
    _linesClearedTotal += 1;
    if (_combo > _maxCombo) _maxCombo = _combo;

    // Score formula per GDD: Cleared Cells x Combo
    final rowPoints = GameConstants.boardCols * _combo;
    _score += rowPoints;

    // Silver Fish: base 2 per line * silverMultiplier
    final silverReward = (2 * silverMultiplier).round();
    _silverEarned += silverReward;
    _playerData.addSilverFish(silverReward);

    // Charge skill meter
    _skillCharge = min(1.0, _skillCharge + 0.2 + (_combo * 0.08));

    // Update Level Progression (every 8 lines cleared = 1 level)
    final newLevel = 1 + (_linesClearedTotal ~/ 8);
    if (newLevel > _inGameLevel) {
      _inGameLevel = newLevel;
      _mascotQuote = 'LEVEL UP! Level $_inGameLevel (Silver x${silverMultiplier.toStringAsFixed(1)})!';
    } else if (_combo >= 3) {
      _mascotQuote = 'AWESOME! Combo x$_combo!';
    } else if (_combo == 2) {
      _mascotQuote = 'Double Combo!';
    } else {
      _mascotQuote = 'Line cleared! Keep going!';
    }

    if (_score > _bestScore) {
      _bestScore = _score;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('best_score', _bestScore);
      } catch (_) {}
    }

    _clearingRowIndex = r;
    _audio.playClear();
    if (_combo > 1) {
      _audio.playMeowCombo();
    } else {
      _audio.playMeow();
    }

    final rowBlocksToRemove = <CatBlock>{};
    final rowSpecialTriggers = <CatBlock>[];
    final clearedBlockInfos = <ClearedBlockInfo>[];
    final brokenObstacles = <BrokenObstacleInfo>[];

    for (final b in _blocks) {
      if (b.row == r) {
        if (b.type == BlockType.sealed) {
          b.type = BlockType.cat1;
          brokenObstacles.add(BrokenObstacleInfo(col: b.col, width: b.width, wasIce: false));
          _audio.playIceBreak();
          _mascotQuote = 'Seaweed cleared! The fish is free, meow!';
        } else if (b.type == BlockType.ice) {
          // Clear lần 1: Phá băng! Khối băng vỡ ra thành cá thường
          b.type = BlockType.cat1;
          b.health = 1;
          brokenObstacles.add(BrokenObstacleInfo(col: b.col, width: b.width, wasIce: true));
          _audio.playIceBreak();
          _mascotQuote = 'Ice cracked! The fish broke free!';
        } else {
          // Clear lần 2 (hoặc cá thường): Ăn con cá!
          b.isClearing = true;
          rowBlocksToRemove.add(b);
          clearedBlockInfos.add(ClearedBlockInfo(
            col: b.col,
            width: b.width,
            points: b.width * _combo,
            blockType: b.type,
          ));

          if (b.type != BlockType.cat1 && b.type != BlockType.cat2 && b.type != BlockType.cat3) {
            _specialBlocksCleared++;
          }

          if (b.type == BlockType.gift) {
            final roll = _random.nextInt(3);
            if (roll == 0) {
              final goldDrop = 1 + _random.nextInt(2); // 1 or 2 Gold
              _playerData.addGoldFish(goldDrop);
              _mascotQuote = 'Treasure Chest: +$goldDrop Gold!';
            } else if (roll == 1) {
              final boosterTypes = ['hammer', 'wand', 'magnet'];
              final chosen = boosterTypes[_random.nextInt(boosterTypes.length)];
              _playerData.addBooster(chosen, 1);
              final bName = chosen == 'hammer' ? 'Hammer' : (chosen == 'wand' ? 'Wand' : 'Net');
              _mascotQuote = 'Treasure Chest: +1 $bName Booster!';
            } else {
              const silverDrop = 25;
              _silverEarned += silverDrop;
              _playerData.addSilverFish(silverDrop);
              _mascotQuote = 'Treasure Chest: +$silverDrop Silver!';
            }
            _audio.playBooster();
          } else if (b.type == BlockType.bomb || b.type == BlockType.lightning) {
            rowSpecialTriggers.add(b);
          }
        }
      }
    }

    // Sort left-to-right for staggered aquatic wave pop choreography
    clearedBlockInfos.sort((a, b) => a.col.compareTo(b.col));

    _latestClearEvent = RowClearEvent(
      rowIndex: r,
      points: rowPoints,
      combo: _combo,
      timestamp: DateTime.now().microsecondsSinceEpoch,
      blocks: clearedBlockInfos,
      brokenObstacles: brokenObstacles,
    );

    notifyListeners();

    // Allow full staggered wave sweep & elastic pop-dissolve animation in Flame to finish cleanly
    await Future.delayed(const Duration(milliseconds: 420));

    // Handle special block chain reactions for this row
    for (final sb in rowSpecialTriggers) {
      if (sb.type == BlockType.bomb) {
        _audio.playClear();
        for (final b in _blocks) {
          if ((b.row - sb.row).abs() <= 1 &&
              (b.col <= sb.col + sb.width && b.col + b.width >= sb.col)) {
            rowBlocksToRemove.add(b);
          }
        }
      } else if (sb.type == BlockType.lightning) {
        _audio.playLightning();
        // Cross zap: clears entire row and intersecting columns
        for (final b in _blocks) {
          final isSameRow = b.row == sb.row;
          final isSameCol = (b.col <= sb.col + sb.width - 1 && b.col + b.width > sb.col);
          if (isSameRow || isSameCol) {
            rowBlocksToRemove.add(b);
          }
        }
      }
    }

    if (rowBlocksToRemove.isEmpty) {
      unsealedOnlyRows.add(r);
    } else {
      _blocks.removeWhere((b) => rowBlocksToRemove.contains(b));
    }

    _clearingRowIndex = null;
    notifyListeners();

    // Breathing pause before upper rows begin drifting down into the cleared gap
    await Future.delayed(const Duration(milliseconds: 120));

    return true;
  }

  Future<void> _pushNewRow() async {
    // Check if any block will hit or exceed ceiling
    bool reachesCeiling = false;
    for (final b in _blocks) {
      if (b.row >= GameConstants.maxVisibleRows - 1) {
        reachesCeiling = true;
        break;
      }
    }

    if (reachesCeiling) {
      _handleCeilingHit();
      return;
    }

    // Shift all blocks up by 1
    for (final b in _blocks) {
      b.row += 1;
    }

    // Move next row blocks into bottom row 0
    final pushedBlocks = List<CatBlock>.from(_nextRowBlocks);
    _nextRowBlocks.clear();

    if (pushedBlocks.isNotEmpty) {
      for (final b in pushedBlocks) {
        b.row = 0;
        _blocks.add(b);
      }
    } else {
      _generateRow(0);
    }

    _audio.playDrop();
    notifyListeners();

    // Allow 180ms for blocks to smoothly slide up before revealing next preview row
    await Future.delayed(const Duration(milliseconds: 180));
    _generateNextRow();
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 50));
  }

  void _handleCeilingHit() {
    if (mode == GameMode.endless && !_hasUsedContinue) {
      // Trigger Continue Revive dialog!
      _isContinuePrompting = true;
      _mascotQuote = 'Oh no! Can you continue to save me?';
      notifyListeners();
    } else {
      _isGameOver = true;
      _audio.playGameOver();
      _finishGame();
      notifyListeners();
    }
  }

  Future<void> reviveContinue() async {
    _hasUsedContinue = true;
    _isContinuePrompting = false;
    _mascotQuote = 'Yay! Thank you for reviving! Let\'s go!';

    // Remove top 4 rows of blocks to give plenty of breathing room
    _blocks.removeWhere((b) => b.row >= 5);
    _audio.playClear();
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 200));
    await _resolvePhysicsAndLines();

    if (mode == GameMode.endless) {
      await _ensureBoardHasValidMoves();
    }
    notifyListeners();
  }

  void declineContinue() {
    _isContinuePrompting = false;
    _isGameOver = true;
    _audio.playGameOver();
    _finishGame();
    notifyListeners();
  }

  void _checkLevelWinOrLoss() {
    if (mode == GameMode.level) {
      if (_blocks.isEmpty) {
        _isLevelCompleted = true;
        _starsEarned = levelData?.getStars(_moves) ?? 3;
        _audio.playWin();
        _saveLevelProgress();
        _finishGame();
        notifyListeners();
      }
    } else {
      for (final b in _blocks) {
        if (b.row >= GameConstants.maxVisibleRows) {
          _handleCeilingHit();
          break;
        }
      }
    }
  }

  void _finishGame() {
    _playerData.recordGameEnd(
      score: _score,
      linesCleared: _linesClearedTotal,
      silverEarned: 0, // Silver fish credited in real-time during game
    );
  }

  Future<void> _saveLevelProgress() async {
    if (levelData == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'level_stars_${levelData!.levelId}';
    final oldStars = prefs.getInt(key) ?? 0;
    if (_starsEarned > oldStars) {
      await prefs.setInt(key, _starsEarned);
    }
  }

  // --- CHARACTER SKILL ACTIVATION ---
  Future<void> activateSkill() async {
    if (!isSkillReady || _isBusy || _isGameOver || _isLevelCompleted) return;

    _skillCharge = 0.0;
    _audio.playBooster();
    final charId = _playerData.selectedCharacter;

    if (charId == 'robinhood') {
      // Smashes 1 random block and adjacent cats
      if (_blocks.isNotEmpty) {
        final target = _blocks[_random.nextInt(_blocks.length)];
        _blocks.removeWhere((b) => (b.row - target.row).abs() <= 1 && (b.col - target.col).abs() <= 2);
      }
      _mascotQuote = 'Robinhood Arrow Strike!';
    } else if (charId == 'warrior') {
      // Smashes 2 random blocks
      if (_blocks.isNotEmpty) {
        _blocks.removeAt(_random.nextInt(_blocks.length));
        if (_blocks.isNotEmpty) {
          _blocks.removeAt(_random.nextInt(_blocks.length));
        }
      }
      _mascotQuote = 'Warrior Double Smash!';
    } else if (charId == 'king') {
      // Throws 3 lightning bolts (clears 2 random rows and 1 column)
      _audio.playLightning();
      final rowsToClear = [_random.nextInt(GameConstants.maxVisibleRows), _random.nextInt(GameConstants.maxVisibleRows)];
      _blocks.removeWhere((b) => rowsToClear.contains(b.row));
      _mascotQuote = 'King\'s Thunderball Blitz!';
    } else if (charId == 'magician') {
      // Freezes upcoming blocks for 2 turns
      _frozenTurns = 2;
      _audio.playIceBreak();
      _mascotQuote = 'Frost Magic! Block pushes are frozen for 2 turns!';
    } else {
      // Haru: Purring power (Clears bottom row)
      _blocks.removeWhere((b) => b.row == 0);
      _mascotQuote = 'Haru Purring Power! Bottom row blasted!';
    }

    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 200));
    await _resolvePhysicsAndLines();
    _combo = 0;
    notifyListeners();
  }

  // --- BOOSTERS ---
  void selectBooster(String boosterType) {
    if (_isBusy || _isGameOver || _isLevelCompleted) return;
    if (_activeBooster == boosterType) {
      _activeBooster = null; // deselect
    } else {
      _activeBooster = boosterType;
      _audio.playClick();
    }
    notifyListeners();
  }

  Future<void> applyBoosterToBlock(CatBlock block) async {
    if (_activeBooster == null || _isBusy) return;

    if (_activeBooster == GameConstants.boosterHammer) {
      // Quy tắc GDD: Ice block > block. Ưu tiên phá khối băng trước!
      final hasIce = _blocks.any((b) => b.type == BlockType.ice);
      if (hasIce && block.type != BlockType.ice) {
        _mascotQuote = 'Hammer targets Ice blocks first, meow! Tap an Ice block!';
        notifyListeners();
        return;
      }

      if (_playerData.useBooster('hammer')) {
        _activeBooster = null;
        _isBusy = true;
        _audio.playIceBreak();

        try {
          // 1. Hammer: Breaks ice in 1 single hit ("Phá băng, chỉ cần phá 1 lần")
          if (block.type == BlockType.ice) {
            _blocks.remove(block);
            _mascotQuote = 'Shell Hammer shattered the ice block in a single hit!';
          } else if (block.type == BlockType.sealed) {
            _blocks.remove(block);
            _mascotQuote = 'Shell Hammer broke the seaweed!';
          } else {
            _blocks.remove(block);
            _mascotQuote = 'Shell Hammer smashed the fish block!';
          }

          notifyListeners();
          await Future.delayed(const Duration(milliseconds: 160));
          await _resolvePhysicsAndLines();

          if (mode == GameMode.endless) {
            await _ensureBoardHasValidMoves();
          }
        } finally {
          _combo = 0;
          _isBusy = false;
          notifyListeners();
        }
      }
    } else if (_activeBooster == GameConstants.boosterNet || _activeBooster == 'magnet') {
      if (_playerData.useBooster('net')) {
        _activeBooster = null;
        _isBusy = true;
        _audio.playDrop();

        try {
          // 3. Net: Scoop/collect target fish to clear space ("Thu thập dần các con cá để cho thông thoáng")
          _blocks.remove(block);
          _mascotQuote = 'Scoop Net collected the fish! More room to slide!';

          notifyListeners();
          await Future.delayed(const Duration(milliseconds: 160));
          await _resolvePhysicsAndLines();

          if (mode == GameMode.endless) {
            await _ensureBoardHasValidMoves();
          }
        } finally {
          _combo = 0;
          _isBusy = false;
          notifyListeners();
        }
      }
    } else if (_activeBooster == GameConstants.boosterWand) {
      // 2. Wand targeted fallback: transforms selected block into 1-cell fish
      if (block.width < 2) {
        _mascotQuote = 'Tap a large fish (2-4 cells) to split into 1-cell fish, meow!';
        notifyListeners();
        return;
      }

      if (_playerData.useBooster('wand')) {
        _activeBooster = null;
        _isBusy = true;
        _audio.playLightning();

        try {
          _blocks.remove(block);
          for (int i = 0; i < block.width; i++) {
            _blocks.add(CatBlock(
              id: 'wand_${DateTime.now().microsecondsSinceEpoch}_${block.col + i}_${block.row}',
              col: block.col + i,
              row: block.row,
              width: 1,
              type: block.type,
              variant: _random.nextInt(2),
            ));
          }

          _mascotQuote = 'Starfish Wand split the large fish into tiny fish!';
          notifyListeners();

          await Future.delayed(const Duration(milliseconds: 160));
          await _resolvePhysicsAndLines();

          if (mode == GameMode.endless) {
            await _ensureBoardHasValidMoves();
          }
        } finally {
          _combo = 0;
          _isBusy = false;
          notifyListeners();
        }
      }
    }
  }

  /// 2. Wand: Transforms fish across the board to make space ("Dùng để biến đổi các con cá cho thông thoáng")
  Future<void> useWand() async {
    if (_playerData.getBoosterCount('wand') <= 0 || _isBusy || _isGameOver || _isLevelCompleted) return;

    final largeBlocks = _blocks.where((b) => b.width >= 2).toList();
    if (largeBlocks.isEmpty && _blocks.isEmpty) {
      _mascotQuote = 'No large fish on the board to transform right now, meow!';
      notifyListeners();
      return;
    }

    if (_playerData.useBooster('wand')) {
      _audio.playLightning();
      _isBusy = true;
      _activeBooster = null;
      notifyListeners();

      try {
        if (largeBlocks.isNotEmpty) {
          // Transform all large fish into 1-cell fish
          for (final b in largeBlocks) {
            _blocks.remove(b);
            for (int i = 0; i < b.width; i++) {
              _blocks.add(CatBlock(
                id: 'wand_${DateTime.now().microsecondsSinceEpoch}_${b.col + i}_${b.row}',
                col: b.col + i,
                row: b.row,
                width: 1,
                type: b.type,
                variant: _random.nextInt(2),
              ));
            }
          }
          _mascotQuote = 'Starfish Wand split all large fish into tiny fish!';
        } else {
          // All fish are 1-cell: shuffle them to clear rows
          final cols = List.generate(GameConstants.boardCols, (i) => i)..shuffle(_random);
          for (int i = 0; i < _blocks.length; i++) {
            _blocks[i].col = cols[i % cols.length];
          }
          _mascotQuote = 'Starfish Wand shuffled the fish to open up space!';
        }

        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 200));

        await _resolvePhysicsAndLines();

        if (mode == GameMode.endless) {
          await _ensureBoardHasValidMoves();
        }
      } finally {
        _combo = 0;
        _isBusy = false;
        notifyListeners();
      }
    }
  }

  // Alias for legacy magnet calls if needed
  Future<void> useMagnet() => useWand();
}
