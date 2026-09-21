import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../logic/game_controller.dart';
import '../../utils/constants.dart';

class BoardEffectsOverlay extends StatefulWidget {
  final GameController controller;
  final double cellSize;
  final double boardWidth;
  final double boardHeight;
  final Function(Offset)? onShakeUpdate;

  const BoardEffectsOverlay({
    super.key,
    required this.controller,
    required this.cellSize,
    required this.boardWidth,
    required this.boardHeight,
    this.onShakeUpdate,
  });

  @override
  State<BoardEffectsOverlay> createState() => _BoardEffectsOverlayState();
}

class _BoardEffectsOverlayState extends State<BoardEffectsOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  final List<_BubbleParticle> _bubbles = [];
  final List<_StarParticle> _stars = [];
  final List<_LaserSlice> _laserSlices = [];
  final List<_FloatingText> _floatingTexts = [];

  int _lastProcessedTimestamp = 0;
  final Random _random = Random();
  double _shakeIntensity = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(covariant BoardEffectsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerUpdate);
      widget.controller.addListener(_onControllerUpdate);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _ticker.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    final event = widget.controller.latestClearEvent;
    if (event != null && event.timestamp != _lastProcessedTimestamp) {
      _lastProcessedTimestamp = event.timestamp;
      _triggerClearEffects(event.rowIndex, event.points, event.combo);
    }
  }

  void _triggerClearEffects(int rowIndex, int points, int combo) {
    final rowY = (GameConstants.boardRows - 1 - rowIndex) * widget.cellSize +
        widget.cellSize / 2;

    // 1. High-speed laser slice across row
    _laserSlices.add(_LaserSlice(y: rowY, height: widget.cellSize));

    // 2. Spawn 35 aquatic bubbles along the row
    for (int i = 0; i < 35; i++) {
      final colX = _random.nextDouble() * widget.boardWidth;
      final offsetY = rowY + (_random.nextDouble() - 0.5) * widget.cellSize * 0.8;
      _bubbles.add(_BubbleParticle(
        x: colX,
        y: offsetY,
        vx: (_random.nextDouble() - 0.5) * 80,
        vy: -40 - _random.nextDouble() * 110,
        radius: 3.5 + _random.nextDouble() * 7.5,
        wobble: _random.nextDouble() * 2 * pi,
        wobbleSpeed: 4 + _random.nextDouble() * 6,
        maxLife: 0.5 + _random.nextDouble() * 0.4,
      ));
    }

    // 3. Spawn 22 sparkling golden & cyan stars
    final starColors = [
      const Color(0xFFFFD54F),
      const Color(0xFFFFCA28),
      const Color(0xFF00E5FF),
      Colors.white,
    ];
    for (int i = 0; i < 22; i++) {
      final colX = _random.nextDouble() * widget.boardWidth;
      final offsetY = rowY + (_random.nextDouble() - 0.5) * widget.cellSize * 0.6;
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 40 + _random.nextDouble() * 100;
      _stars.add(_StarParticle(
        x: colX,
        y: offsetY,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: 5 + _random.nextDouble() * 8,
        rotation: _random.nextDouble() * 2 * pi,
        rotSpeed: (_random.nextDouble() - 0.5) * 12,
        color: starColors[_random.nextInt(starColors.length)],
        maxLife: 0.4 + _random.nextDouble() * 0.3,
      ));
    }

    // 4. Floating arcade score & combo badge
    String? subtext;
    if (combo >= 4) {
      subtext = 'UNBELIEVABLE! 🔥x$combo';
    } else if (combo == 3) {
      subtext = 'SUPER COMBO! ⚡x3';
    } else if (combo == 2) {
      subtext = 'DOUBLE COMBO! ✨x2';
    } else if (points >= 16) {
      subtext = 'GREAT! 🌊';
    }

    _floatingTexts.add(_FloatingText(
      x: widget.boardWidth / 2,
      startY: rowY - widget.cellSize * 0.2,
      title: '+$points',
      subtitle: subtext,
      maxLife: 0.85,
    ));

    // 5. Tactile screen shake
    _shakeIntensity = 4.0;

    if (!_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    if (dt <= 0 || dt > 0.1) return;

    // 1. Update Laser Slices
    for (int i = _laserSlices.length - 1; i >= 0; i--) {
      final slice = _laserSlices[i];
      slice.progress += dt / (slice.durationMs / 1000.0);
      if (slice.progress >= 1.0) {
        _laserSlices.removeAt(i);
      }
    }

    // 2. Update Bubbles
    for (int i = _bubbles.length - 1; i >= 0; i--) {
      final b = _bubbles[i];
      b.life -= dt;
      if (b.life <= 0) {
        _bubbles.removeAt(i);
        continue;
      }
      b.x += b.vx * dt;
      b.y += b.vy * dt;
      b.wobble += b.wobbleSpeed * dt;
      b.x += sin(b.wobble) * 0.5;
      b.vy -= 15 * dt;
    }

    // 3. Update Stars
    for (int i = _stars.length - 1; i >= 0; i--) {
      final s = _stars[i];
      s.life -= dt;
      if (s.life <= 0) {
        _stars.removeAt(i);
        continue;
      }
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.vx *= 0.94;
      s.vy *= 0.94;
      s.rotation += s.rotSpeed * dt;
    }

    // 4. Update Floating Texts
    for (int i = _floatingTexts.length - 1; i >= 0; i--) {
      final t = _floatingTexts[i];
      t.life -= dt;
      if (t.life <= 0) {
        _floatingTexts.removeAt(i);
        continue;
      }
      t.currentY -= 45 * dt;
    }

    // 5. Update Screen Shake
    if (_shakeIntensity > 0.1) {
      final shakeX = (_random.nextDouble() - 0.5) * 2 * _shakeIntensity;
      final shakeY = (_random.nextDouble() - 0.5) * 2 * _shakeIntensity;
      widget.onShakeUpdate?.call(Offset(shakeX, shakeY));
      _shakeIntensity *= 0.85;
    } else {
      _shakeIntensity = 0.0;
      widget.onShakeUpdate?.call(Offset.zero);
    }

    // Stop ticker if idle to save battery & CPU
    if (_laserSlices.isEmpty &&
        _bubbles.isEmpty &&
        _stars.isEmpty &&
        _floatingTexts.isEmpty &&
        _shakeIntensity <= 0.0) {
      _ticker.stop();
      _lastElapsed = Duration.zero;
      widget.onShakeUpdate?.call(Offset.zero);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_laserSlices.isEmpty &&
        _bubbles.isEmpty &&
        _stars.isEmpty &&
        _floatingTexts.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        size: Size(widget.boardWidth, widget.boardHeight),
        painter: _BoardEffectsPainter(
          bubbles: _bubbles,
          stars: _stars,
          laserSlices: _laserSlices,
          floatingTexts: _floatingTexts,
          boardWidth: widget.boardWidth,
        ),
      ),
    );
  }
}

class _LaserSlice {
  final double y;
  final double height;
  double progress = 0.0;
  final double durationMs = 240.0;

  _LaserSlice({required this.y, required this.height});
}

class _BubbleParticle {
  double x, y;
  double vx, vy;
  double radius;
  double wobble;
  double wobbleSpeed;
  double life;
  final double maxLife;

  _BubbleParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.wobble,
    required this.wobbleSpeed,
    required this.maxLife,
  }) : life = maxLife;
}

class _StarParticle {
  double x, y;
  double vx, vy;
  double size;
  double rotation;
  double rotSpeed;
  Color color;
  double life;
  final double maxLife;

  _StarParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rotation,
    required this.rotSpeed,
    required this.color,
    required this.maxLife,
  }) : life = maxLife;
}

class _FloatingText {
  final double x;
  final double startY;
  double currentY;
  final String title;
  final String? subtitle;
  double life;
  final double maxLife;

  _FloatingText({
    required this.x,
    required this.startY,
    required this.title,
    this.subtitle,
    required this.maxLife,
  })  : currentY = startY,
        life = maxLife;
}

class _BoardEffectsPainter extends CustomPainter {
  final List<_BubbleParticle> bubbles;
  final List<_StarParticle> stars;
  final List<_LaserSlice> laserSlices;
  final List<_FloatingText> floatingTexts;
  final double boardWidth;

  _BoardEffectsPainter({
    required this.bubbles,
    required this.stars,
    required this.laserSlices,
    required this.floatingTexts,
    required this.boardWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Laser Slices
    for (final slice in laserSlices) {
      _paintLaserSlice(canvas, slice);
    }

    // 2. Draw Bubbles
    final bubbleFillPaint = Paint()..style = PaintingStyle.fill;
    final bubbleStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final glintPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final b in bubbles) {
      final alpha = (b.life / b.maxLife).clamp(0.0, 1.0);
      bubbleFillPaint.color = const Color(0xFFE0F7FA).withOpacity(alpha * 0.45);
      bubbleStrokePaint.color = Colors.white.withOpacity(alpha * 0.85);

      canvas.drawCircle(Offset(b.x, b.y), b.radius, bubbleFillPaint);
      canvas.drawCircle(Offset(b.x, b.y), b.radius, bubbleStrokePaint);

      // Specular highlight glint
      glintPaint.color = Colors.white.withOpacity(alpha * 0.9);
      final glintOffset = Offset(b.x - b.radius * 0.35, b.y - b.radius * 0.35);
      canvas.drawCircle(glintOffset, b.radius * 0.24, glintPaint);
    }

    // 3. Draw Stars
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      final alpha = (s.life / s.maxLife).clamp(0.0, 1.0);
      final scale = alpha;
      starPaint.color = s.color.withOpacity(alpha);

      canvas.save();
      canvas.translate(s.x, s.y);
      canvas.rotate(s.rotation);
      canvas.scale(scale);

      final starPath = Path()
        ..moveTo(0, -s.size)
        ..quadraticBezierTo(0, 0, s.size, 0)
        ..quadraticBezierTo(0, 0, 0, s.size)
        ..quadraticBezierTo(0, 0, -s.size, 0)
        ..quadraticBezierTo(0, 0, 0, -s.size);

      canvas.drawPath(starPath, starPaint);
      canvas.restore();
    }

    // 4. Draw Floating Arcade Texts
    for (final t in floatingTexts) {
      _paintFloatingText(canvas, t);
    }
  }

  void _paintLaserSlice(Canvas canvas, _LaserSlice slice) {
    final headX = slice.progress * boardWidth;
    final tailX = (headX - 140).clamp(0.0, boardWidth);
    final y = slice.y;

    if (headX <= tailX) return;

    // Glowing beam line
    final rect = Rect.fromLTRB(tailX, y - 4, headX, y + 4);
    final gradient = LinearGradient(
      colors: [
        const Color(0xFF00E5FF).withOpacity(0.0),
        const Color(0xFF00E5FF).withOpacity(0.8),
        Colors.white,
      ],
      stops: const [0.0, 0.7, 1.0],
    );

    final beamPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0;

    canvas.drawLine(Offset(tailX, y), Offset(headX, y), beamPaint);

    // Core white laser
    final corePaint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(tailX + 30, y), Offset(headX, y), corePaint);

    // Cutting edge starburst
    final starPaint = Paint()..color = Colors.white;
    canvas.save();
    canvas.translate(headX, y);
    final flarePath = Path()
      ..moveTo(0, -14)
      ..lineTo(2.5, -2.5)
      ..lineTo(14, 0)
      ..lineTo(2.5, 2.5)
      ..lineTo(0, 14)
      ..lineTo(-2.5, 2.5)
      ..lineTo(-14, 0)
      ..lineTo(-2.5, -2.5)
      ..close();
    canvas.drawPath(flarePath, starPaint);
    canvas.restore();
  }

  void _paintFloatingText(Canvas canvas, _FloatingText text) {
    final progress = 1.0 - (text.life / text.maxLife);
    double scale = 1.0;
    double opacity = 1.0;

    // Punch scale entrance
    if (progress < 0.25) {
      scale = 0.4 + (progress / 0.25) * 0.75;
    } else if (progress < 0.4) {
      scale = 1.15 - ((progress - 0.25) / 0.15) * 0.15;
    }

    if (progress > 0.65) {
      opacity = (1.0 - (progress - 0.65) / 0.35).clamp(0.0, 1.0);
    }

    canvas.save();
    canvas.translate(text.x, text.currentY);
    canvas.scale(scale);

    // 1. Draw Title (+80)
    final titleTp = TextPainter(
      text: TextSpan(
        text: text.title,
        style: TextStyle(
          fontFamily: 'JandaManatee',
          fontSize: 26,
          fontWeight: FontWeight.w900,
          foreground: Paint()
            ..color = const Color(0xFFFFD54F).withOpacity(opacity)
            ..style = PaintingStyle.fill,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(opacity * 0.65),
              offset: const Offset(0, 3),
              blurRadius: 4,
            ),
            Shadow(
              color: const Color(0xFFFF6F00).withOpacity(opacity * 0.8),
              offset: const Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    titleTp.paint(canvas, Offset(-titleTp.width / 2, -titleTp.height / 2));

    // 2. Draw Subtitle (COMBO x2! 🔥)
    if (text.subtitle != null) {
      final subTp = TextPainter(
        text: TextSpan(
          text: text.subtitle,
          style: TextStyle(
            fontFamily: 'JandaManatee',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..color = const Color(0xFF00E5FF).withOpacity(opacity)
              ..style = PaintingStyle.fill,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(opacity * 0.7),
                offset: const Offset(0, 2),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      subTp.paint(
        canvas,
        Offset(-subTp.width / 2, -titleTp.height / 2 - subTp.height - 2),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BoardEffectsPainter oldDelegate) => true;
}
