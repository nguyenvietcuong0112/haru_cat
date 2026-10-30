import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../models/block.dart';
import '../../utils/constants.dart';
import '../haru_slide_game.dart';

class FishBlockComponent extends PositionComponent
    with DragCallbacks, TapCallbacks, HasGameReference<HaruSlideGame> {
  final CatBlock block;
  bool isPreview;
  late BlockType _lastBlockType;

  // Visual state
  double visualX = 0.0;
  double visualY = 0.0;
  double velocityY = 0.0;
  double targetX = 0.0;
  double targetY = 0.0;

  // Squash & Stretch
  double squishX = 1.0;
  double squishY = 1.0;
  double squishVelX = 0.0;
  double squishVelY = 0.0;

  // Dragging state
  bool isDragging = false;
  double dragOffset = 0.0;
  int minSlideCol = 0;
  int maxSlideCol = 0;
  double dragTilt = 0.0;
  int _lastGhostCol = -1;
  int _lastGhostRow = -1;

  // Idle & Clear Animation state (staggered pop-jump & bubble dissolve, zero white flash)
  double idleTimer = 0.0;
  double _clearElapsed = 0.0;
  double clearScale = 1.0;
  double clearAlpha = 1.0;
  double clearOffsetY = 0.0;
  double clearTilt = 0.0;
  double clearAuraAlpha = 0.0;

  // Cached bomb badge text painter
  TextPainter? _bombTextPainter;
  int _lastBombCountdown = -1;

  // Reusable static Paint instances to eliminate per-frame GC churn
  static final Paint _shadowPaint = Paint();
  static final Paint _dragGlowPaint = Paint()
    ..color = const Color(0xFF00E5FF).withOpacity(0.6)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
  static final Paint _clearAuraPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9.0);
  static final Paint _spritePaint = Paint()..filterQuality = FilterQuality.medium;
  static final Paint _fallbackPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _bombBgPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _bombRingPaint = Paint()..style = PaintingStyle.stroke;

  FishBlockComponent({
    required this.block,
    this.isPreview = false,
  }) {
    _lastBlockType = block.type;
    idleTimer = Random().nextDouble() * 2 * pi;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(block.width * game.cellSize, game.cellSize);

    targetX = block.col * game.cellSize;
    targetY = game.rowToY(block.row);
    visualX = targetX;
    visualY = targetY;
    position = Vector2(visualX, visualY);

    if (block.type == BlockType.bomb) {
      _updateBombTextPainter();
    }
  }

  void syncState() {
    // Dynamic preview update: if block row >= 0, it is an active block on the board
    isPreview = block.row < 0;
    targetX = block.col * game.cellSize;
    targetY = game.rowToY(block.row);

    // Elastic liberation bounce when breaking free from ice or seaweed!
    if (_lastBlockType != block.type) {
      if (_lastBlockType == BlockType.ice || _lastBlockType == BlockType.sealed) {
        squishX = 1.22;
        squishY = 0.78;
      }
      _lastBlockType = block.type;
    }

    if (!isDragging) {
      dragOffset = 0.0;
    }

    // Cell-proportional initial drop speed (matches GameController._applyGravity timing on all screens)
    if (block.isFalling && velocityY <= 0) {
      velocityY = 2.8 * game.cellSize;
    }

    if (block.type == BlockType.bomb && block.bombCountdown != _lastBombCountdown) {
      _updateBombTextPainter();
    }
  }

  void _updateBombTextPainter() {
    _lastBombCountdown = block.bombCountdown;
    final isUrgent = block.bombCountdown <= 2;
    _bombTextPainter = TextPainter(
      text: TextSpan(
        text: '${block.bombCountdown}',
        style: TextStyle(
          color: isUrgent ? const Color(0xFFFF5252) : const Color(0xFFFFD54F),
          fontSize: 12.0,
          fontWeight: FontWeight.w900,
          fontFamily: 'BrandonText',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    idleTimer += dt * 3.5;

    // 1. Horizontal position interpolation
    if (!isDragging) {
      final dx = targetX - visualX;
      if (dx.abs() > 0.5) {
        visualX += dx * min(1.0, 20.0 * dt);
      } else {
        visualX = targetX;
      }
      dragTilt *= max(0.0, 1.0 - 15.0 * dt);
    }

    // 2. Vertical position & Cell-Proportional Gravity Physics
    final dy = targetY - visualY;
    if (dy.abs() > 0.5) {
      if (block.isFalling || visualY < targetY) {
        if (velocityY <= 0) {
          velocityY = 2.8 * game.cellSize;
        }
        velocityY += 42.0 * game.cellSize * dt;
        visualY += velocityY * dt;

        if (visualY >= targetY) {
          visualY = targetY;
          velocityY = 0.0;

          // Juicy Squash & Stretch landing bounce
          squishY = 0.80;
          squishX = 1.18;

          game.emitLandingWaterDrops(
            visualX + width / 2,
            visualY + height - 2,
            block.width,
          );
        }
      } else {
        visualY += dy * min(1.0, 16.0 * dt);
        velocityY = 0.0;
      }
    } else {
      visualY = targetY;
      velocityY = 0.0;
    }

    // 3. Spring back Squash & Stretch to (1.0, 1.0)
    const springK = 340.0;
    const springC = 21.0;

    final forceX = -springK * (squishX - 1.0) - springC * squishVelX;
    squishVelX += forceX * dt;
    squishX += squishVelX * dt;

    final forceY = -springK * (squishY - 1.0) - springC * squishVelY;
    squishVelY += forceY * dt;
    squishY += squishVelY * dt;

    // 4. Staggered Left-to-Right Elastic Pop-Jump & Bubble Dissolve on Row Clear
    if (block.isClearing) {
      if (priority < 45) priority = 45;
      _clearElapsed += dt;

      // Left-to-right wave stagger across columns 0..7
      final staggerDelay = block.col * 0.022;
      if (_clearElapsed > staggerDelay) {
        final activeTime = _clearElapsed - staggerDelay;
        const popDuration = 0.25;
        final t = (activeTime / popDuration).clamp(0.0, 1.0);

        if (t < 0.38) {
          // Phase 1: Joyful elastic swell & upward leap (sprite remains 100% crisp & colorful)
          final p1 = t / 0.38;
          final ease = sin(p1 * pi * 0.5);
          clearScale = 1.0 + 0.22 * ease;
          clearOffsetY = -8.5 * ease;
          clearTilt = sin(p1 * pi) * 0.10;
          clearAuraAlpha = ease * 0.65;
          clearAlpha = 1.0;
        } else {
          // Phase 2: Smooth shrink-pop to zero as bubbles & stars burst outward
          final p2 = ((t - 0.38) / 0.62).clamp(0.0, 1.0);
          final shrink = 1.0 - p2 * p2;
          clearScale = 1.22 * shrink;
          clearOffsetY = -8.5 - 5.0 * p2;
          clearTilt = -sin(p2 * pi) * 0.12;
          clearAuraAlpha = 0.65 * (1.0 - p2);
          clearAlpha = shrink.clamp(0.0, 1.0);
        }
      }
    }

    position.setValues(visualX, visualY);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (clearAlpha <= 0.01 || clearScale <= 0.02) return;

    final w = width;
    final h = height;

    canvas.save();

    // Center transform for squash, stretch, clear hop, and tilt
    canvas.translate(w / 2, h / 2 + clearOffsetY);
    canvas.rotate(dragTilt + clearTilt);

    // Swimming breathing idle
    final swimWobbleY = (isDragging || block.isClearing) ? 0.0 : sin(idleTimer) * 1.2;
    canvas.translate(0, swimWobbleY);

    final currentScaleX = squishX * clearScale * (isDragging ? 1.04 : 1.0);
    final currentScaleY = squishY * clearScale * (isDragging ? 1.04 : 1.0);
    canvas.scale(currentScaleX, currentScaleY);

    canvas.translate(-w / 2, -h / 2);

    final opacity = ((isPreview || block.row < 0 ? 0.80 : 1.0) * clearAlpha).clamp(0.0, 1.0);

    // 1. Drop Shadow under fish
    _shadowPaint
      ..color = Colors.black.withOpacity(0.18 * opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isDragging ? 6.0 : 3.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, isDragging ? 8 : 4, w - 4, h - 6),
        const Radius.circular(8),
      ),
      _shadowPaint,
    );

    // 2. Drag Highlight Glow or Soft Clear Halo Behind Fish (never obscuring sprite)
    if (isDragging) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, h),
          const Radius.circular(10),
        ),
        _dragGlowPaint,
      );
    } else if (clearAuraAlpha > 0.01) {
      final auraColor =
          game.controller.combo > 1 ? const Color(0xFFFFD54F) : const Color(0xFF00E5FF);
      _clearAuraPaint.color = auraColor.withOpacity((clearAuraAlpha * clearAlpha).clamp(0.0, 0.7));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-2, -2, w + 4, h + 4),
          const Radius.circular(12),
        ),
        _clearAuraPaint,
      );
    }

    // 3. Render Main Fish Sprite
    final mainSpritePath = block.fishSpriteAsset;
    final mainImage = game.getCachedImage(mainSpritePath);
    final srcDstRect = Rect.fromLTWH(1, 1, w - 2, h - 2);

    if (mainImage != null) {
      final srcRect = Rect.fromLTWH(0, 0, mainImage.width.toDouble(), mainImage.height.toDouble());
      _spritePaint.color = Color.fromRGBO(255, 255, 255, opacity);
      canvas.drawImageRect(mainImage, srcRect, srcDstRect, _spritePaint);
    } else {
      _fallbackPaint.color = Colors.lightBlue.withOpacity(opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(srcDstRect, const Radius.circular(8)),
        _fallbackPaint,
      );
    }

    // 4. Overlays (Ice or Seaweed)
    final overlayPath = block.overlayAsset;
    if (overlayPath != null) {
      final overlayImage = game.getCachedImage(overlayPath);
      if (overlayImage != null) {
        final srcRect = Rect.fromLTWH(
          0,
          0,
          overlayImage.width.toDouble(),
          overlayImage.height.toDouble(),
        );
        _spritePaint.color = Color.fromRGBO(255, 255, 255, opacity * 0.92);
        canvas.drawImageRect(overlayImage, srcRect, srcDstRect, _spritePaint);
      }
    }

    // 5. Bomb Countdown Badge
    if (block.type == BlockType.bomb) {
      _renderBombBadge(canvas, w, h, opacity);
    }

    canvas.restore();
  }

  void _renderBombBadge(Canvas canvas, double w, double h, double opacity) {
    const badgeRadius = 11.0;
    final badgeCenter = Offset(w - 15.0, 15.0);

    final pulse = 0.5 + 0.5 * sin(idleTimer * 6.0);
    final isUrgent = block.bombCountdown <= 2;

    _bombRingPaint
      ..color = (isUrgent ? Colors.redAccent : Colors.amber)
          .withOpacity((0.6 + pulse * 0.4) * opacity)
      ..strokeWidth = isUrgent ? 2.5 : 2.0;

    _bombBgPaint.color = Colors.black.withOpacity(0.85 * opacity);

    canvas.drawCircle(badgeCenter, badgeRadius, _bombBgPaint);
    canvas.drawCircle(badgeCenter, badgeRadius, _bombRingPaint);

    if (_bombTextPainter != null) {
      _bombTextPainter!.paint(
        canvas,
        Offset(badgeCenter.dx - _bombTextPainter!.width / 2,
            badgeCenter.dy - _bombTextPainter!.height / 2),
      );
    }
  }

  // --- DRAG GESTURE HANDLING ---

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);

    // Row < 0 is preview row, cannot be dragged
    if (isPreview || block.row < 0) return;
    if (game.controller.isBusy || game.controller.activeBooster != null) return;

    if (block.type == BlockType.sealed) {
      game.controller.setMascotQuote('This fish is tangled in seaweed and cannot slide, meow!');
      squishVelX = 40.0;
      return;
    }

    minSlideCol = game.controller.getMinSlideCol(block);
    maxSlideCol = game.controller.getMaxSlideCol(block);

    // If block has no room to slide left or right
    if (minSlideCol == block.col && maxSlideCol == block.col) {
      squishVelX = 35.0; // Wiggle feedback showing it is jammed
      game.controller.setMascotQuote('This fish is blocked on both sides and cannot slide, meow!');
      game.controller.checkAndPushIfNoMoves();
      return;
    }

    isDragging = true;
    dragOffset = 0.0;
    _lastGhostCol = -1;
    _lastGhostRow = -1;

    priority = 100;
    squishX = 1.08;
    squishY = 0.94;

    _updateGhostIndicator();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!isDragging) return;

    final minPx = (minSlideCol - block.col) * game.cellSize;
    final maxPx = (maxSlideCol - block.col) * game.cellSize;

    dragOffset = (dragOffset + event.canvasDelta.x).clamp(minPx, maxPx);
    visualX = targetX + dragOffset;
    dragTilt = (event.canvasDelta.x * 0.04).clamp(-0.12, 0.12);

    _updateGhostIndicator();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _finalizeDrag();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _finalizeDrag();
  }

  void _finalizeDrag() {
    if (!isDragging) return;
    isDragging = false;
    dragOffset = 0.0;
    priority = isPreview ? 15 : 20;

    game.ghostIndicator.hide();

    final snapCol = (visualX / game.cellSize).round().clamp(minSlideCol, maxSlideCol);
    targetX = snapCol * game.cellSize;

    if (snapCol != block.col) {
      game.controller.slideBlock(block, snapCol);
    } else {
      squishVelX = 20.0;
    }
  }

  void _updateGhostIndicator() {
    final candidateCol = (visualX / game.cellSize).round().clamp(minSlideCol, maxSlideCol);

    if (candidateCol == _lastGhostCol && block.row == _lastGhostRow) {
      return;
    }
    _lastGhostCol = candidateCol;
    _lastGhostRow = block.row;

    int dropRow = block.row;
    while (dropRow > 0) {
      bool canDrop = true;
      for (int c = candidateCol; c < candidateCol + block.width; c++) {
        if (!game.controller.isCellEmpty(c, dropRow - 1, ignoring: block)) {
          canDrop = false;
          break;
        }
      }
      if (canDrop) {
        dropRow--;
      } else {
        break;
      }
    }

    bool willComplete = true;
    for (int c = 0; c < GameConstants.boardCols; c++) {
      if (c >= candidateCol && c < candidateCol + block.width) continue;
      if (game.controller.isCellEmpty(c, dropRow, ignoring: block)) {
        willComplete = false;
        break;
      }
    }

    game.ghostIndicator.show(
      col: candidateCol,
      row: dropRow,
      width: block.width,
      completesLine: willComplete,
    );
  }

  // --- TAP GESTURE HANDLING ---

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    if (isPreview || block.row < 0) return;

    if (game.controller.activeBooster != null) {
      game.controller.applyBoosterToBlock(block);
    } else {
      squishY = 0.88;
      squishX = 1.10;
    }
  }
}
