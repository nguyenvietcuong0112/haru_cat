import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Pre-records static grid slots, borders, and danger line into a GPU Picture
/// to achieve single-draw-call background rendering at 60/120 FPS.
class BoardGridComponent extends Component {
  final double cellSize;
  final int totalRows;
  final bool isEndless;
  final double boardWidth;
  final double boardHeight;

  // Cached display list
  ui.Picture? _cachedGridPicture;

  // Ambient floating bubbles in water tank
  final List<_AmbientBubble> _bubbles = [];
  final Random _random = Random();

  BoardGridComponent({
    required this.cellSize,
    required this.totalRows,
    required this.isEndless,
    required this.boardWidth,
    required this.boardHeight,
  }) {
    // Generate initial ambient bubbles
    for (int i = 0; i < 18; i++) {
      _bubbles.add(_AmbientBubble(
        x: _random.nextDouble() * boardWidth,
        y: _random.nextDouble() * boardHeight,
        radius: 2.0 + _random.nextDouble() * 3.5,
        speed: 15.0 + _random.nextDouble() * 25.0,
        wobbleSpeed: 1.5 + _random.nextDouble() * 2.0,
        opacity: 0.15 + _random.nextDouble() * 0.25,
      ));
    }
  }

  void _recordStaticGrid() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 1. Grid cell slots
    final normalSlotPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final previewSlotPaint = Paint()
      ..color = const Color(0xFF006064).withOpacity(0.25)
      ..style = PaintingStyle.fill;

    final slotBorderPaint = Paint()
      ..color = const Color(0xFF80DEEA).withOpacity(0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int r = 0; r < totalRows; r++) {
      final isPreview = isEndless && r == totalRows - 1;
      final y = r * cellSize;

      for (int c = 0; c < GameConstants.boardCols; c++) {
        final x = c * cellSize;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 1.0, y + 1.0, cellSize - 2.0, cellSize - 2.0),
          const Radius.circular(5.0),
        );

        canvas.drawRRect(rect, isPreview ? previewSlotPaint : normalSlotPaint);
        canvas.drawRRect(rect, slotBorderPaint);
      }
    }

    // 2. Danger Warning Ceiling Line
    final dangerPaint = Paint()
      ..color = Colors.red.withOpacity(0.45)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(4, cellSize),
      Offset(boardWidth - 4, cellSize),
      dangerPaint,
    );

    // 3. Preview Divider Bar (if endless mode)
    if (isEndless) {
      final dividerY = GameConstants.boardRows * cellSize;
      final dividerPaint = Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF006064),
            Color(0xFF00838F),
            Color(0xFF00E5FF),
            Color(0xFF00838F),
            Color(0xFF006064),
          ],
        ).createShader(Rect.fromLTWH(0, dividerY - 2, boardWidth, 4));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, dividerY - 2, boardWidth, 4),
          const Radius.circular(2),
        ),
        dividerPaint,
      );

      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawLine(
        Offset(0, dividerY + 2),
        Offset(boardWidth, dividerY + 2),
        shadowPaint,
      );
    }

    _cachedGridPicture = recorder.endRecording();
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final b in _bubbles) {
      b.update(dt, boardWidth, boardHeight);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Single GPU draw call for entire background grid
    if (_cachedGridPicture == null) {
      _recordStaticGrid();
    }
    canvas.drawPicture(_cachedGridPicture!);

    // 2. Ambient floating water bubbles
    for (final b in _bubbles) {
      b.render(canvas);
    }
  }

  @override
  void onRemove() {
    _cachedGridPicture?.dispose();
    _cachedGridPicture = null;
    super.onRemove();
  }
}

class _AmbientBubble {
  double x;
  double y;
  double radius;
  double speed;
  double wobbleSpeed;
  double opacity;
  double wobblePhase = 0.0;

  static final Paint _bubblePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  static final Paint _glintPaint = Paint()..style = PaintingStyle.fill;

  _AmbientBubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.wobbleSpeed,
    required this.opacity,
  });

  void update(double dt, double boardW, double boardH) {
    y -= speed * dt;
    wobblePhase += wobbleSpeed * dt;
    x += sin(wobblePhase) * 8.0 * dt;

    if (y < -radius * 2) {
      y = boardH + radius;
      x = Random().nextDouble() * boardW;
    }
  }

  void render(Canvas canvas) {
    _bubblePaint.color = Colors.white.withOpacity(opacity);
    canvas.drawCircle(Offset(x, y), radius, _bubblePaint);

    _glintPaint.color = Colors.white.withOpacity(opacity * 1.2);
    canvas.drawCircle(Offset(x - radius * 0.35, y - radius * 0.35), radius * 0.25, _glintPaint);
  }
}
