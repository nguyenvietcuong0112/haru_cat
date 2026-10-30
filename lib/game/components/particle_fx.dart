import 'dart:math';
import 'package:flutter/material.dart';

/// Highly-optimized lightweight particle representation for zero-garbage 60/120 FPS aquatic effects
class GameParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double maxLife;
  double life;
  double delay;
  Color color;
  double rotation;
  double vRotation;
  final ParticleType type;
  final String? text;

  TextPainter? _cachedTextPainter;

  // Reusable static paints & paths to avoid GC allocations during render loop
  static final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _glintPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white;
  static final Path _starPath = Path();
  static final Path _iceShardPath = Path();
  static final Path _leafPath = Path();

  GameParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.maxLife,
    required this.color,
    this.delay = 0.0,
    this.rotation = 0.0,
    this.vRotation = 0.0,
    required this.type,
    this.text,
  }) : life = maxLife {
    if (type == ParticleType.floatingText && text != null && text!.isNotEmpty) {
      _cachedTextPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'JandaManatee',
            fontSize: size,
            fontWeight: FontWeight.w900,
            color: color,
            shadows: const [
              Shadow(
                color: Color(0xCC00363A),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
              Shadow(
                color: Colors.black54,
                blurRadius: 2,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
  }

  double get progress => (1.0 - (life / maxLife)).clamp(0.0, 1.0);
  bool get isDead => life <= 0;

  void update(double dt) {
    if (delay > 0) {
      delay -= dt;
      return;
    }

    life -= dt;
    x += vx * dt;
    y += vy * dt;
    rotation += vRotation * dt;

    switch (type) {
      case ParticleType.waterDrop:
        vy += 420 * dt; // Gravity arc
        break;
      case ParticleType.bubble:
        vy -= 48 * dt; // Buoyant upward float
        vx *= 0.96;
        x += sin(progress * 11.0 + rotation) * 22.0 * dt; // Natural underwater wobble
        break;
      case ParticleType.star:
      case ParticleType.spark:
        vx *= 0.94;
        vy *= 0.94;
        vy += 55 * dt; // Slight float-drift settle
        break;
      case ParticleType.floatingText:
        vy *= 0.92; // Smooth upward deceleration
        break;
      case ParticleType.iceShard:
        vy += 380 * dt;
        break;
      case ParticleType.seaweedLeaf:
        vy += 90 * dt;
        vx += sin(progress * 9.0) * 35.0 * dt; // Fluttering leaf sway
        break;
      case ParticleType.shockwave:
        break;
    }
  }

  void render(Canvas canvas) {
    if (isDead || delay > 0) return;
    final p = progress;
    final alpha = (life / maxLife).clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(x, y);

    switch (type) {
      case ParticleType.bubble:
        // Pop-in scale & subtle pop-shrink at very end
        final popScale = p < 0.15
            ? (p / 0.15)
            : (p > 0.85 ? (1.0 + (p - 0.85) * 1.4) : 1.0);
        final r = size * popScale;

        // Soft translucent inner body
        _fillPaint.color = color.withOpacity(alpha * 0.22);
        canvas.drawCircle(Offset.zero, r, _fillPaint);

        // Crisp glossy bubble rim
        _strokePaint
          ..color = color.withOpacity(alpha * 0.85)
          ..strokeWidth = 1.35;
        canvas.drawCircle(Offset.zero, r, _strokePaint);

        // Specular highlight glints
        _glintPaint.color = Colors.white.withOpacity(alpha * 0.95);
        canvas.drawCircle(Offset(-r * 0.34, -r * 0.34), r * 0.28, _glintPaint);
        canvas.drawCircle(Offset(r * 0.26, r * 0.26), r * 0.13, _glintPaint);
        break;

      case ParticleType.waterDrop:
      case ParticleType.spark:
        _fillPaint.color = color.withOpacity(alpha);
        final r = size * (1.0 - p * 0.45);
        canvas.drawCircle(Offset.zero, r, _fillPaint);
        _glintPaint.color = Colors.white.withOpacity(alpha * 0.7);
        canvas.drawCircle(Offset(-r * 0.25, -r * 0.25), r * 0.3, _glintPaint);
        break;

      case ParticleType.star:
        canvas.rotate(rotation);
        final starScale = p < 0.2 ? (p / 0.2) * 1.15 : (1.15 * (1.0 - (p - 0.2) / 0.8));
        final currentSize = (size * starScale).clamp(0.1, size * 1.3);

        _fillPaint.color = color.withOpacity(alpha);
        _starPath.reset();
        for (int i = 0; i < 5; i++) {
          final a1 = (i * 72 - 18) * pi / 180;
          final a2 = (i * 72 + 18) * pi / 180;
          final rOut = currentSize;
          final rIn = currentSize * 0.44;
          if (i == 0) {
            _starPath.moveTo(cos(a1) * rOut, sin(a1) * rOut);
          } else {
            _starPath.lineTo(cos(a1) * rOut, sin(a1) * rOut);
          }
          _starPath.lineTo(cos(a2) * rIn, sin(a2) * rIn);
        }
        _starPath.close();
        canvas.drawPath(_starPath, _fillPaint);

        // Bright star center core
        _glintPaint.color = Colors.white.withOpacity(alpha * 0.85);
        canvas.drawCircle(Offset.zero, currentSize * 0.26, _glintPaint);
        break;

      case ParticleType.iceShard:
        canvas.rotate(rotation);
        _fillPaint.color = color.withOpacity(alpha * 0.9);
        _strokePaint
          ..color = Colors.white.withOpacity(alpha * 0.95)
          ..strokeWidth = 1.1;

        _iceShardPath.reset();
        _iceShardPath.moveTo(0, -size);
        _iceShardPath.lineTo(size * 0.72, size * 0.45);
        _iceShardPath.lineTo(-size * 0.58, size * 0.82);
        _iceShardPath.close();

        canvas.drawPath(_iceShardPath, _fillPaint);
        canvas.drawPath(_iceShardPath, _strokePaint);
        break;

      case ParticleType.seaweedLeaf:
        canvas.rotate(rotation);
        _fillPaint.color = color.withOpacity(alpha * 0.9);
        _leafPath.reset();
        _leafPath.moveTo(0, -size);
        _leafPath.quadraticBezierTo(size * 0.65, 0, 0, size);
        _leafPath.quadraticBezierTo(-size * 0.65, 0, 0, -size);
        _leafPath.close();
        canvas.drawPath(_leafPath, _fillPaint);
        break;

      case ParticleType.shockwave:
        // Smooth ease-out expanding concentric water ripples
        final eased = 1.0 - (1.0 - p) * (1.0 - p);
        final outerRadius = size * (0.25 + eased * 0.75);
        _strokePaint
          ..color = color.withOpacity(alpha * 0.72)
          ..strokeWidth = max(0.8, (1.0 - p) * 3.2);
        canvas.drawCircle(Offset.zero, outerRadius, _strokePaint);

        if (p > 0.12) {
          final innerRadius = outerRadius * 0.66;
          _strokePaint
            ..color = Colors.white.withOpacity(alpha * 0.45)
            ..strokeWidth = max(0.5, (1.0 - p) * 1.6);
          canvas.drawCircle(Offset.zero, innerRadius, _strokePaint);
        }
        break;

      case ParticleType.floatingText:
        if (_cachedTextPainter != null) {
          // Elastic pop-in (0..0.22) and smooth pop-out (0.76..1.0)
          double textScale = 1.0;
          if (p < 0.22) {
            final t = p / 0.22;
            textScale = sin(t * pi * 0.65) * 1.16;
          } else if (p < 0.34) {
            final t = (p - 0.22) / 0.12;
            textScale = 1.16 - 0.16 * t;
          } else if (p > 0.76) {
            final t = (p - 0.76) / 0.24;
            textScale = (1.0 - t * t).clamp(0.0, 1.0);
          }

          if (textScale > 0.02) {
            canvas.scale(textScale, textScale);
            _cachedTextPainter!.paint(
              canvas,
              Offset(-_cachedTextPainter!.width / 2, -_cachedTextPainter!.height / 2),
            );
          }
        }
        break;
    }

    canvas.restore();
  }
}

enum ParticleType {
  bubble,
  waterDrop,
  spark,
  star,
  iceShard,
  seaweedLeaf,
  shockwave,
  floatingText,
}
