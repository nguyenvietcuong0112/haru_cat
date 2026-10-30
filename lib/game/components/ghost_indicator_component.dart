import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Shows real-time ghost drop indicator where the dragged fish will settle,
/// including a glowing row highlight if the drop will complete a full line.
class GhostIndicatorComponent extends Component {
  final double cellSize;
  final double boardWidth;

  bool isVisible = false;
  int targetCol = 0;
  int targetRow = 0;
  int blockWidth = 1;
  bool willCompleteLine = false;

  double _pulseTimer = 0.0;

  // Reusable static Paint instances
  static final Paint _lineGlowPaint = Paint();
  static final Paint _lineBorderPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _dropFillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _dropBorderPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _arrowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;
  static final Path _arrowPath = Path();

  GhostIndicatorComponent({
    required this.cellSize,
    required this.boardWidth,
  });

  void show({
    required int col,
    required int row,
    required int width,
    required bool completesLine,
  }) {
    isVisible = true;
    targetCol = col;
    targetRow = row;
    blockWidth = width;
    willCompleteLine = completesLine;
  }

  void hide() {
    isVisible = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isVisible) {
      _pulseTimer += dt;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!isVisible) return;

    final targetX = targetCol * cellSize;
    final targetY = (GameConstants.boardRows - 1 - targetRow) * cellSize;
    final blockW = blockWidth * cellSize;
    final pulse = 0.5 + 0.5 * sin(_pulseTimer * 8.0);

    // 1. If completing line: Highlight entire horizontal row edge-to-edge!
    if (willCompleteLine) {
      final lineRect = Rect.fromLTWH(0, targetY, boardWidth, cellSize);
      _lineGlowPaint.shader = LinearGradient(
        colors: [
          const Color(0xFFFFD54F).withOpacity(0.15 + pulse * 0.20),
          const Color(0xFF00E5FF).withOpacity(0.35 + pulse * 0.25),
          const Color(0xFFFFD54F).withOpacity(0.15 + pulse * 0.20),
        ],
      ).createShader(lineRect);

      final lineRRect = RRect.fromRectAndRadius(lineRect, const Radius.circular(8));
      canvas.drawRRect(lineRRect, _lineGlowPaint);

      _lineBorderPaint
        ..color = const Color(0xFFFFD54F).withOpacity(0.65 + pulse * 0.35)
        ..strokeWidth = 2.0;

      canvas.drawRRect(lineRRect, _lineBorderPaint);
    }

    // 2. Render Ghost Target Box
    final dropRect = Rect.fromLTWH(targetX + 2, targetY + 2, blockW - 4, cellSize - 4);
    final dropRRect = RRect.fromRectAndRadius(dropRect, const Radius.circular(8));

    final fillColor = willCompleteLine
        ? const Color(0xFFFFD54F).withOpacity(0.35 + pulse * 0.20)
        : const Color(0xFF00E5FF).withOpacity(0.25 + pulse * 0.15);

    _dropFillPaint.color = fillColor;
    canvas.drawRRect(dropRRect, _dropFillPaint);

    final borderColor = willCompleteLine
        ? const Color(0xFFFFD700)
        : const Color(0xFF80DEEA);

    _dropBorderPaint
      ..color = borderColor.withOpacity(0.75 + pulse * 0.25)
      ..strokeWidth = 2.2;

    canvas.drawRRect(dropRRect, _dropBorderPaint);

    // 3. Downward Arrow Indicator in center
    final centerX = targetX + blockW / 2;
    final centerY = targetY + cellSize / 2;
    final arrowOffset = pulse * 3.0;

    _arrowPaint.color = Colors.white.withOpacity(0.70 + pulse * 0.30);

    _arrowPath.reset();
    _arrowPath.moveTo(centerX - 6, centerY - 2 + arrowOffset);
    _arrowPath.lineTo(centerX, centerY + 4 + arrowOffset);
    _arrowPath.lineTo(centerX + 6, centerY - 2 + arrowOffset);
    canvas.drawPath(_arrowPath, _arrowPaint);
  }
}
