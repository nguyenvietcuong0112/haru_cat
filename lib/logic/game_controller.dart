import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/block.dart';
import '../models/level_data.dart';
import '../models/player_data.dart';
import '../audio/audio_manager.dart';
import '../utils/constants.dart';

enum GameMode { endless, level }

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

      result.add(CatBlock(
        id: 'blk_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(10000)}',
        col: col,
        row: r,
        width: w,
        type: type,
      ));

      col += w;
      currentTotal += w;
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

  void setMascotQuote(String quote) {
    _mascotQuote = quote;
    notifyListeners();
  }

  // Player slides block
  Future<void> slideBlock(CatBlock block, int targetCol) async {
    if (_isBusy || _isGameOver || _isLevelCompleted || _isContinuePrompting) return;
    if (block.type == BlockType.sealed) {
      _mascotQuote = 'Chú mèo này đang bị xích, không thể trượt meow!';
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
      final toExplode = <CatBlock>{};
      for (final eb in autoExplodedBombs) {
        toExplode.add(eb);
        for (final b in _blocks) {
          if ((b.row - eb.row).abs() <= 1 &&
              (b.col <= eb.col + eb.width && b.col + b.width >= eb.col)) {
            toExplode.add(b);
          }
        }
      }
      _blocks.removeWhere((b) => toExplode.contains(b));
      _mascotQuote = 'BÙM! Bom tự kích nổ sau 5 lượt!';
    }

    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 160));

    // Run gravity & match loop
    await _resolvePhysicsAndLines();

    if (!_isGameOver && !_isLevelCompleted && !_isContinuePrompting) {
      if (mode == GameMode.endless) {
        if (_frozenTurns > 0) {
          _frozenTurns--;
          _mascotQuote = 'Magician frost hold! Row push paused!';
        } else {
          await Future.delayed(const Duration(milliseconds: 220));
          await _pushNewRow();
          await _resolvePhysicsAndLines();
        }
      }

      _checkLevelWinOrLoss();
    }

    _isBusy = false;
    notifyListeners();
  }

  Future<bool> _resolvePhysicsAndLines() async {
    bool anyClearedTotal = false;
    bool hadAction = true;
    _combo = 0;

    while (hadAction) {
      hadAction = false;

      // 1. Gravity fall
      bool hadFall = await _applyGravity();
      if (hadFall) {
        hadAction = true;
        await Future.delayed(const Duration(milliseconds: 140));
      }

      // 2. Clear full lines
      int linesCleared = await _checkAndClearLines();
      if (linesCleared > 0) {
        hadAction = true;
        anyClearedTotal = true;
        _combo++;
        _linesClearedTotal += linesCleared;
        if (_combo > _maxCombo) _maxCombo = _combo;

        // Score with combo & level multiplier
        int points = linesCleared * 100 * _combo * _scoreMultiplier;
        _score += points;

        // Earn 2 silver fish per line cleared
        _silverEarned += (linesCleared * 2);

        // Charge skill meter
        _skillCharge = min(1.0, _skillCharge + (linesCleared * 0.2) + (_combo * 0.08));

        // Update Level Progression
        final newLevel = 1 + (_score ~/ 1200);
        if (newLevel > _inGameLevel) {
          _inGameLevel = newLevel;
          _mascotQuote = 'LEVEL UP! Score is now x$_inGameLevel points!';
        } else if (_combo >= 3) {
          _mascotQuote = 'UNBELIEVABLE! Combo x$_combo!';
        } else if (_combo == 2) {
          _mascotQuote = 'Awesome! Double Combo!';
        } else {
          _mascotQuote = 'Purr-fect line clear! Keep it up!';
        }

        if (_score > _bestScore) {
          _bestScore = _score;
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('best_score', _bestScore);
          } catch (_) {}
        }

        if (_combo > 1) {
          _audio.playMeowCombo();
        } else {
          _audio.playMeow();
        }

        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    // Danger check for mascot quote
    final highestRow = _blocks.fold(0, (maxR, b) => b.row > maxR ? b.row : maxR);
    if (highestRow >= 7 && !_isGameOver) {
      _mascotQuote = 'Help me! It\'s getting too close to the top!';
    }

    return anyClearedTotal;
  }

  int get _scoreMultiplier => _inGameLevel;

  Future<bool> _applyGravity() async {
    bool fellAny = false;
    final sortedBlocks = List<CatBlock>.from(_blocks)..sort((a, b) => a.row.compareTo(b.row));

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
        block.row = targetRow;
        fellAny = true;
      }
    }

    if (fellAny) {
      _audio.playDrop();
      notifyListeners();
    }

    return fellAny;
  }

  Future<int> _checkAndClearLines() async {
    final fullRows = <int>[];

    for (int r = 0; r < GameConstants.boardRows; r++) {
      bool full = true;
      for (int c = 0; c < GameConstants.boardCols; c++) {
        if (isCellEmpty(c, r)) {
          full = false;
          break;
        }
      }
      if (full) {
        fullRows.add(r);
      }
    }

    if (fullRows.isEmpty) return 0;

    _audio.playClear();

    final toRemove = <CatBlock>{};
    final specialTriggers = <CatBlock>[];

    for (final r in fullRows) {
      for (final b in _blocks) {
        if (b.row == r) {
          if (b.type == BlockType.sealed) {
            b.type = BlockType.cat1;
            _audio.playIceBreak();
            _mascotQuote = 'Xiềng xích đã vỡ! Mèo tự do rồi meow!';
          } else if (b.type == BlockType.ice && b.health > 1) {
            b.health--;
            _audio.playIceBreak();
          } else {
            b.isClearing = true;
            toRemove.add(b);

            if (b.type != BlockType.cat1 && b.type != BlockType.cat2 && b.type != BlockType.cat3) {
              _specialBlocksCleared++;
            }

            if (b.type == BlockType.gift) {
              _silverEarned += 25; // 25 Silver fish from gift!
              _audio.playBooster();
            } else if (b.type == BlockType.bomb || b.type == BlockType.lightning) {
              specialTriggers.add(b);
            }
          }
        }
      }
    }

    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 180));

    // Special block chain reactions
    for (final sb in specialTriggers) {
      if (sb.type == BlockType.bomb) {
        _audio.playClear();
        for (final b in _blocks) {
          if ((b.row - sb.row).abs() <= 1 &&
              (b.col <= sb.col + sb.width && b.col + b.width >= sb.col)) {
            toRemove.add(b);
          }
        }
      } else if (sb.type == BlockType.lightning) {
        _audio.playLightning();
        // Cross zap: clears entire row and intersecting columns!
        for (final b in _blocks) {
          final isSameRow = b.row == sb.row;
          final isSameCol = (b.col <= sb.col + sb.width - 1 && b.col + b.width > sb.col);
          if (isSameRow || isSameCol) {
            toRemove.add(b);
          }
        }
      }
    }

    _blocks.removeWhere((b) => toRemove.contains(b));
    notifyListeners();

    return fullRows.length;
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
    if (_nextRowBlocks.isNotEmpty) {
      for (final b in _nextRowBlocks) {
        b.row = 0;
        _blocks.add(b);
      }
    } else {
      _generateRow(0);
    }
    _generateNextRow();

    _audio.playDrop();
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 150));
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
      silverEarned: _silverEarned,
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
      if (_playerData.useBooster('hammer')) {
        _activeBooster = null;
        _audio.playBooster();

        // 1. Hammer (Thunderball): Clears target block AND nearby cats (3x3 area)
        final toRemove = <CatBlock>{block};
        for (final b in _blocks) {
          final rowDist = (b.row - block.row).abs();
          final bStart = b.col;
          final bEnd = b.col + b.width - 1;
          final targetStart = block.col;
          final targetEnd = block.col + block.width - 1;
          if (rowDist <= 1 && bStart <= targetEnd + 1 && bEnd >= targetStart - 1) {
            toRemove.add(b);
          }
        }

        _blocks.removeWhere((b) => toRemove.contains(b));
        _mascotQuote = 'Búa sấm sét đã đập vỡ khối và các chú mèo xung quanh!';
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 160));
        await _applyGravity();
        await _resolvePhysicsAndLines();
      }
    } else if (_activeBooster == GameConstants.boosterWand) {
      // 3. Magic Wand (Purring): Splits big cat blocks into 1-cell kitty cats!
      if (block.width < 2) {
        _mascotQuote = 'Hãy chọn chú mèo lớn (2-4 ô) để chia nhỏ thành mèo con 1 ô meow!';
        notifyListeners();
        return;
      }

      if (_playerData.useBooster('wand')) {
        _activeBooster = null;
        _audio.playLightning();

        // Remove the big block and spawn width * 1-cell blocks
        _blocks.remove(block);
        for (int i = 0; i < block.width; i++) {
          _blocks.add(CatBlock(
            id: 'split_${DateTime.now().microsecondsSinceEpoch}_${block.col + i}',
            col: block.col + i,
            row: block.row,
            width: 1,
            type: block.type,
          ));
        }

        _mascotQuote = 'Đũa thần đã phân tách mèo lớn thành các chú mèo con!';
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 160));
        await _applyGravity();
        await _resolvePhysicsAndLines();
      }
    }
  }

  Future<void> useMagnet() async {
    if (_playerData.getBoosterCount('magnet') <= 0 || _isBusy || _isGameOver || _isLevelCompleted) return;

    // 2. Magnet (Scratching): Randomly clear all cat blocks of the same color!
    final catColors = <BlockType>{};
    for (final b in _blocks) {
      if (b.type == BlockType.cat1 || b.type == BlockType.cat2 || b.type == BlockType.cat3) {
        catColors.add(b.type);
      }
    }

    if (catColors.isEmpty && _blocks.isEmpty) return;

    if (_playerData.useBooster('magnet')) {
      _audio.playBooster();
      _isBusy = true;
      notifyListeners();

      final targetColor = catColors.isNotEmpty
          ? (catColors.toList()..shuffle(_random)).first
          : _blocks.first.type;

      final removedCount = _blocks.where((b) => b.type == targetColor).length;
      _blocks.removeWhere((b) => b.type == targetColor);

      String colorName = 'mèo cam';
      if (targetColor == BlockType.cat2) colorName = 'mèo trắng';
      if (targetColor == BlockType.cat3) colorName = 'mèo nâu';

      _mascotQuote = 'Nam châm đã hút sạch toàn bộ $colorName trên bàn cờ!';
      _score += removedCount * 60 * _scoreMultiplier;

      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 200));

      await _applyGravity();
      await _resolvePhysicsAndLines();

      _isBusy = false;
      notifyListeners();
    }
  }
}
