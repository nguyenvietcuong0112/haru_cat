import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../logic/game_controller.dart';
import '../models/block.dart';
import '../utils/constants.dart';
import 'components/board_grid_component.dart';
import 'components/fish_block_component.dart';
import 'components/ghost_indicator_component.dart';
import 'components/particle_manager_component.dart';

class HaruSlideGame extends FlameGame with DragCallbacks, TapCallbacks {
  final GameController controller;
  final double cellSize;
  final double boardWidth;
  final double boardHeight;
  final int totalRows;
  final bool isEndless;

  late final BoardGridComponent boardGrid;
  late final GhostIndicatorComponent ghostIndicator;
  late final ParticleManagerComponent particleManager;

  final Map<String, FishBlockComponent> _activeComponents = {};
  final Map<String, FishBlockComponent> _previewComponents = {};
  int _lastHandledClearTimestamp = 0;

  // GPU Camera screen shake state (eliminates Flutter widget setState)
  double _shakeTimer = 0.0;
  double _shakeDuration = 0.0;
  double _shakeIntensity = 0.0;

  HaruSlideGame({
    required this.controller,
    required this.cellSize,
    required this.boardWidth,
    required this.boardHeight,
    required this.totalRows,
    required this.isEndless,
  });

  @override
  Color backgroundColor() => const Color(0x00000000); // Fully transparent

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Ensure camera coordinate system starts top-left at (0, 0)
    camera.viewfinder.anchor = Anchor.topLeft;

    // Load assets
    images.prefix = '';
    await _preloadAssets();

    // 1. Grid Background (Single GPU draw call via Picture cache)
    boardGrid = BoardGridComponent(
      cellSize: cellSize,
      totalRows: totalRows,
      isEndless: isEndless,
      boardWidth: boardWidth,
      boardHeight: boardHeight,
    );
    boardGrid.priority = 1;
    world.add(boardGrid);

    // 2. Ghost Drop Indicator
    ghostIndicator = GhostIndicatorComponent(
      cellSize: cellSize,
      boardWidth: boardWidth,
    );
    ghostIndicator.priority = 10;
    world.add(ghostIndicator);

    // 3. Particle & Laser Manager (zero-allocation render)
    particleManager = ParticleManagerComponent();
    particleManager.priority = 200;
    world.add(particleManager);

    // 4. Initial sync of blocks
    _syncBlocks();

    // Listen to GameController state changes
    controller.addListener(_onControllerStateChanged);
  }

  @override
  void onRemove() {
    controller.removeListener(_onControllerStateChanged);
    super.onRemove();
  }

  void triggerShake({double duration = 0.22, double intensity = 4.0}) {
    _shakeDuration = duration;
    _shakeTimer = duration;
    _shakeIntensity = intensity;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 1. GPU Camera Viewfinder shake - zero Flutter tree rebuilds
    if (_shakeTimer > 0) {
      _shakeTimer -= dt;
      final progress = (_shakeTimer / _shakeDuration).clamp(0.0, 1.0);
      final mag = _shakeIntensity * progress;
      final offsetX = sin(_shakeTimer * 45) * mag;
      final offsetY = cos(_shakeTimer * 35) * (mag * 0.7);
      camera.viewfinder.position = Vector2(offsetX, offsetY);
      if (_shakeTimer <= 0) {
        camera.viewfinder.position = Vector2.zero();
      }
    }

    // 2. Auto-detect deadlock / no moves available on active board -> trigger row push
    if (!controller.isBusy &&
        !controller.isGameOver &&
        !controller.isContinuePrompting &&
        controller.mode == GameMode.endless &&
        !controller.hasValidMoves()) {
      controller.checkAndPushIfNoMoves();
    }
  }

  Future<void> _preloadAssets() async {
    final assetList = <String>[
      'assets/images/sprites/fish/fish_1cell_a.png',
      'assets/images/sprites/fish/fish_1cell_b.png',
      'assets/images/sprites/fish/fish_2cell_a.png',
      'assets/images/sprites/fish/fish_2cell_b.png',
      'assets/images/sprites/fish/fish_3cell_a.png',
      'assets/images/sprites/fish/fish_3cell_b.png',
      'assets/images/sprites/fish/fish_4cell_a.png',
      'assets/images/sprites/fish/fish_4cell_b.png',
      'assets/images/sprites/fish/bomb_1cell.png',
      'assets/images/sprites/fish/bomb_2cell.png',
      'assets/images/sprites/fish/bomb_3cell.png',
      'assets/images/sprites/fish/bomb_4cell.png',
      'assets/images/sprites/fish/gift_1cell.png',
      'assets/images/sprites/fish/ice_1cell.png',
      'assets/images/sprites/fish/ice_2cell.png',
      'assets/images/sprites/fish/ice_3cell.png',
      'assets/images/sprites/fish/ice_4cell.png',
      'assets/images/sprites/fish/seaweed_1cell.png',
      'assets/images/sprites/fish/seaweed_2cell.png',
      'assets/images/sprites/fish/seaweed_3cell.png',
      'assets/images/sprites/fish/seaweed_4cell.png',
      'assets/images/sprites/ui/coin-gold-8.png',
      'assets/images/sprites/ui/coin-silver-8.png',
    ];

    for (final path in assetList) {
      try {
        await images.load(path);
      } catch (_) {}
    }
  }

  ui.Image? getCachedImage(String path) {
    if (images.containsKey(path)) {
      return images.fromCache(path);
    }
    images.load(path).then<ui.Image?>((img) => img).catchError((_) => null);
    return null;
  }

  double rowToY(int row) {
    return (GameConstants.boardRows - 1 - row) * cellSize;
  }

  double colToX(int col) {
    return col * cellSize;
  }

  void emitLandingWaterDrops(double x, double y, int blockWidth) {
    particleManager.spawnLandingSplash(x, y, blockWidth);
  }

  void _onControllerStateChanged() {
    _syncBlocks();
    _handleClearEvents();
  }

  void _syncBlocks() {
    final currentBlockIds = <String>{};

    // 1. Sync Active Blocks (Rows 0..9)
    for (final block in controller.blocks) {
      currentBlockIds.add(block.id);

      if (_activeComponents.containsKey(block.id)) {
        final comp = _activeComponents[block.id]!;
        comp.syncState();
      } else if (_previewComponents.containsKey(block.id)) {
        // Was preview, promoted to active board block (row pushed up!)
        final comp = _previewComponents.remove(block.id)!;
        comp.isPreview = false;
        comp.priority = 20;
        _activeComponents[block.id] = comp;
        comp.syncState();
      } else {
        final comp = FishBlockComponent(block: block, isPreview: false);
        comp.priority = 20;
        _activeComponents[block.id] = comp;
        world.add(comp);
      }
    }

    // Remove active components that no longer exist in controller
    final removedIds = _activeComponents.keys.where((id) => !currentBlockIds.contains(id)).toList();
    for (final id in removedIds) {
      final comp = _activeComponents.remove(id)!;
      if (comp.block.type == BlockType.bomb && comp.block.bombCountdown <= 0) {
        particleManager.spawnBombExplosion(
          comp.visualX + comp.width / 2,
          comp.visualY + comp.height / 2,
        );
        triggerShake(duration: 0.35, intensity: 6.0);
      }
      comp.removeFromParent();
    }

    // 2. Sync Preview Blocks (Row -1)
    if (isEndless) {
      final previewIds = <String>{};
      for (final block in controller.nextRowBlocks) {
        previewIds.add(block.id);
        if (_previewComponents.containsKey(block.id)) {
          _previewComponents[block.id]!.syncState();
        } else {
          final comp = FishBlockComponent(block: block, isPreview: true);
          comp.priority = 15;
          _previewComponents[block.id] = comp;
          world.add(comp);
        }
      }

      final removedPreviewIds =
          _previewComponents.keys.where((id) => !previewIds.contains(id)).toList();
      for (final id in removedPreviewIds) {
        final comp = _previewComponents.remove(id)!;
        comp.removeFromParent();
      }
    }
  }

  void _handleClearEvents() {
    final event = controller.latestClearEvent;
    if (event != null && event.timestamp != _lastHandledClearTimestamp) {
      _lastHandledClearTimestamp = event.timestamp;

      final rowY = rowToY(event.rowIndex) + cellSize / 2;
      particleManager.spawnRowLaser(rowY, boardWidth, event.combo);
      triggerShake(duration: 0.22, intensity: 2.0 + event.combo * 1.5);

      // Spawn floating score & combo texts
      for (final b in event.blocks) {
        final textX = colToX(b.col) + (b.width * cellSize) / 2;
        particleManager.spawnFloatingText(
          textX,
          rowY - 12,
          '+${b.points}',
          event.combo > 1 ? const Color(0xFFFFD54F) : const Color(0xFF00E5FF),
          size: event.combo > 1 ? 20.0 : 16.0,
        );
      }

      if (event.combo > 1) {
        particleManager.spawnFloatingText(
          boardWidth / 2,
          rowY - 30,
          'COMBO x${event.combo}!',
          const Color(0xFFFF7043),
          size: 24.0,
        );
      }
    }
  }
}
