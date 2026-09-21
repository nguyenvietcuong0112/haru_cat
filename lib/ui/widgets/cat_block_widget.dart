import 'package:flutter/material.dart';
import '../../models/block.dart';
import '../../logic/game_controller.dart';
import '../../utils/constants.dart';

class CatBlockWidget extends StatefulWidget {
  final CatBlock block;
  final double cellSize;
  final GameController controller;

  const CatBlockWidget({
    super.key,
    required this.block,
    required this.cellSize,
    required this.controller,
  });

  @override
  State<CatBlockWidget> createState() => _CatBlockWidgetState();
}

class _CatBlockWidgetState extends State<CatBlockWidget> {
  double _dragOffset = 0.0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    final cellSize = widget.cellSize;
    final blockWidthPx = cellSize * block.width;
    final blockHeightPx = cellSize;

    // In our model: row 0 is bottom row, row 9 is top row
    // In UI Positioned: top = (9 - row) * cellSize
    final targetLeft = block.col * cellSize;
    final targetTop = (GameConstants.boardRows - 1 - block.row) * cellSize;

    final currentLeft = _isDragging ? (targetLeft + _dragOffset) : targetLeft;

    return AnimatedPositioned(
      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 160),
      curve: Curves.easeOutQuad,
      left: currentLeft,
      top: targetTop,
      width: blockWidthPx,
      height: blockHeightPx,
      child: GestureDetector(
        onTap: () {
          if (widget.controller.activeBooster != null) {
            widget.controller.applyBoosterToBlock(block);
          }
        },
        onHorizontalDragStart: (details) {
          if (widget.controller.isBusy || widget.controller.activeBooster != null) return;
          if (block.type == BlockType.sealed) {
            widget.controller.setMascotQuote('Chú mèo này đang bị xích, không thể trượt meow!');
            return;
          }
          setState(() {
            _isDragging = true;
            _dragOffset = 0.0;
          });
        },
        onHorizontalDragUpdate: (details) {
          if (!_isDragging) return;
          final minCol = widget.controller.getMinSlideCol(block);
          final maxCol = widget.controller.getMaxSlideCol(block);

          final minPx = (minCol - block.col) * cellSize;
          final maxPx = (maxCol - block.col) * cellSize;

          setState(() {
            _dragOffset = (_dragOffset + details.delta.dx).clamp(minPx, maxPx);
          });
        },
        onHorizontalDragEnd: (details) {
          if (!_isDragging) return;
          _isDragging = false;

          // Calculate target column based on drag offset
          final colShift = (_dragOffset / cellSize).round();
          final targetCol = block.col + colShift;

          setState(() {
            _dragOffset = 0.0;
          });

          widget.controller.slideBlock(block, targetCol);
        },
        child: AnimatedScale(
          scale: block.isClearing ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 160),
          child: AnimatedOpacity(
            opacity: block.isClearing ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 160),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              margin: EdgeInsets.all(_isDragging ? 1.0 : 2.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isDragging ? 0.35 : 0.20),
                    offset: Offset(0, _isDragging ? 5 : 3),
                    blurRadius: _isDragging ? 8 : 4,
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Base Cat Artwork with true aspect-ratio preservation
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      block.spriteAsset,
                      fit: BoxFit.fill,
                      errorBuilder: (ctx, err, stack) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '🐱 ${block.width}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // 2. Bomb Countdown Badge
                  if (block.type == BlockType.bomb)
                    Positioned(
                      top: 4,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: block.bombCountdown <= 2
                              ? Colors.redAccent
                              : const Color(0xFF222222),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.yellowAccent,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: block.bombCountdown <= 2
                                  ? Colors.red.withValues(alpha: 0.6)
                                  : Colors.black38,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          '${block.bombCountdown}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),

                  // 3. Ice Crack Overlay (When health is reduced to 1)
                  if (block.type == BlockType.ice && block.health <= 1)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white.withValues(alpha: 0.25),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.7),
                              width: 1.5,
                            ),
                          ),
                          child: CustomPaint(
                            painter: _IceCrackPainter(),
                          ),
                        ),
                      ),
                    ),

                  // 4. Sealed / Chained Block Overlay
                  if (block.type == BlockType.sealed)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.black.withValues(alpha: 0.28),
                            border: Border.all(
                              color: const Color(0xFFB0BEC5),
                              width: 2.2,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF263238).withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFFD54F),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.lock,
                                color: Color(0xFFFFD54F),
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for broken ice cracks
class _IceCrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Center jagged star crack
    final path = Path()
      ..moveTo(cx - 12, cy - 8)
      ..lineTo(cx, cy)
      ..lineTo(cx + 14, cy - 6)
      ..moveTo(cx, cy)
      ..lineTo(cx - 8, cy + 10)
      ..moveTo(cx, cy)
      ..lineTo(cx + 10, cy + 9)
      ..moveTo(cx, cy)
      ..lineTo(cx - 18, cy + 2)
      ..moveTo(cx, cy)
      ..lineTo(cx + 18, cy + 1);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

