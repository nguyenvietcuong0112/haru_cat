import 'package:flutter/material.dart';
import '../../models/block.dart';
import '../../logic/game_controller.dart';
import '../../utils/constants.dart';

class CatBlockWidget extends StatefulWidget {
  final CatBlock block;
  final double cellSize;
  final GameController controller;
  final bool isPreview;

  const CatBlockWidget({
    super.key,
    required this.block,
    required this.cellSize,
    required this.controller,
    this.isPreview = false,
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
    // Preview row is at row -1, which maps to top = (9 - (-1)) * cellSize = 10 * cellSize
    final targetLeft = block.col * cellSize;
    final targetTop = (GameConstants.boardRows - 1 - block.row) * cellSize;

    final currentLeft = _isDragging ? (targetLeft + _dragOffset) : targetLeft;

    return AnimatedPositioned(
      duration: _isDragging
          ? Duration.zero
          : (block.isFalling
              ? const Duration(milliseconds: 260)
              : const Duration(milliseconds: 180)),
      curve: block.isFalling ? Curves.bounceOut : Curves.easeOutQuad,
      left: currentLeft,
      top: targetTop,
      width: blockWidthPx,
      height: blockHeightPx,
      child: GestureDetector(
        onTap: () {
          if (widget.isPreview || block.row < 0) return;
          if (widget.controller.activeBooster != null) {
            widget.controller.applyBoosterToBlock(block);
          }
        },
        onHorizontalDragStart: (details) {
          if (widget.isPreview || block.row < 0) return;
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
          scale: block.isClearing ? 1.22 : (_isDragging ? 1.05 : 1.0),
          duration: const Duration(milliseconds: 240),
          curve: block.isClearing ? Curves.easeOutBack : Curves.easeInOut,
          child: AnimatedOpacity(
            opacity: block.isClearing
                ? 0.0
                : (widget.isPreview || block.row < 0 ? 0.78 : 1.0),
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeIn,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              margin: const EdgeInsets.all(1.0),
              decoration: _isDragging
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withOpacity(0.55),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    )
                  : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Base Fish Artwork with white silhouette flash when clearing
                  ColorFiltered(
                    colorFilter: block.isClearing
                        ? const ColorFilter.mode(Colors.white, BlendMode.srcATop)
                        : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                    child: Image.asset(
                      block.fishSpriteAsset,
                      fit: BoxFit.fill,
                      errorBuilder: (ctx, err, stack) {
                        return Image.asset(
                          block.spriteAsset,
                          fit: BoxFit.fill,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '🐟 ${block.width}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // 2. Ice Block Overlay (Translucent ice capsule)
                  if (block.type == BlockType.ice)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Image.asset(
                          'assets/images/sprites/fish/ice_${block.width}cell.png',
                          fit: BoxFit.fill,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.cyan.withValues(alpha: 0.25),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  width: 1.5,
                                ),
                              ),
                              child: block.health <= 1
                                  ? CustomPaint(painter: _IceCrackPainter())
                                  : null,
                            );
                          },
                        ),
                      ),
                    ),

                  // 3. Sealed / Seaweed Overlay (Seaweed wrapped around block)
                  if (block.type == BlockType.sealed)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Image.asset(
                          'assets/images/sprites/fish/seaweed_${block.width}cell.png',
                          fit: BoxFit.fill,
                          errorBuilder: (_, __, ___) {
                            return Container(
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
                            );
                          },
                        ),
                      ),
                    ),

                  // 4. Bomb Countdown (Centered inside bomb fish circle)
                  if (block.type == BlockType.bomb)
                    Center(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black45, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${block.bombCountdown}',
                          style: TextStyle(
                            fontFamily: 'JandaManatee',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: block.bombCountdown <= 2
                                ? Colors.red.shade800
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),

                  // 5. Submerged Tint for preview row blocks
                  if (widget.isPreview || block.row < 0)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xFF00363A).withValues(alpha: 0.22),
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

