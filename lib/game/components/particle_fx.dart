import 'dart:math';
import 'package:flutter/material.dart';

/// Highly-optimized lightweight particle representation for zero-garbage 60/120 FPS effects
class GameParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double maxLife;
  double life;
  Color color;
  double rotation;
  double vRotation;
  final ParticleType type;
  final String? text;

  TextPainter? _cachedTextPainter;

  // Reusable static paints to avoid GC allocations during render loop
  static final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _glintPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white;
  static final Path _starPath = Path();
  static final Path _iceShardPath = Path();

  GameParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.maxLife,
    required this.color,
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
            fontFamily: 'BrandonText',
            fontSize: size,
            fontWeight: FontWeight.w900,
            color: color,
            shadows: const [
              Shadow(
                color: Colors.black54,
                blurRadius: 4,
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
    life -= dt;
    x += vx * dt;
    y += vy * dt;
    rotation += vRotation * dt;

    if (type == ParticleType.waterDrop) {
      vy += 450 * dt; // Gravity
    } else if (type == ParticleType.bubble) {
      vy -= 25 * dt; // Upward buoyancy
      vx += sin(progress * 10) * 15 * dt; // Gentle wobble
    } else if (type == ParticleType.floatingText) {
      vy *= 0.94; // Decelerate upward drift
    } else if (type == ParticleType.iceShard) {
      vy += 380 * dt; // Ice falling with gravity
    }
  }

  void render(Canvas canvas) {
    if (isDead) return;
    final alpha = (life / maxLife).clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(x, y);

    switch (type) {
      case ParticleType.bubble:
        _strokePaint
          ..color = color.withOpacity(alpha * 0.75)
          ..strokeWidth = 1.2;
        canvas.drawCircle(Offset.zero, size, _strokePaint);

        // Highlight glint
        _glintPaint.color = Colors.white.withOpacity(alpha * 0.9);
        canvas.drawCircle(Offset(-size * 0.35, -size * 0.35), size * 0.28, _glintPaint);
        break;

      case ParticleType.waterDrop:
      case ParticleType.spark:
        _fillPaint.color = color.withOpacity(alpha);
        canvas.drawCircle(Offset.zero, size * (1.0 - progress * 0.4), _fillPaint);
        break;

      case ParticleType.star:
        canvas.rotate(rotation);
        _fillPaint.color = color.withOpacity(alpha);
        final currentSize = size * (1.0 - progress * 0.5);

        _starPath.reset();
        for (int i = 0; i < 5; i++) {
          final a1 = (i * 72 - 18) * pi / 180;
          final a2 = (i * 72 + 18) * pi / 180;
          final rOut = currentSize;
          final rIn = currentSize * 0.42;
          if (i == 0) {
            _starPath.moveTo(cos(a1) * rOut, sin(a1) * rOut);
          } else {
            _starPath.lineTo(cos(a1) * rOut, sin(a1) * rOut);
          }
          _starPath.lineTo(cos(a2) * rIn, sin(a2) * rIn);
        }
        _starPath.close();
        canvas.drawPath(_starPath, _fillPaint);
        break;

      case ParticleType.iceShard:
        canvas.rotate(rotation);
        _fillPaint.color = color.withOpacity(alpha);
        _strokePaint
          ..color = Colors.white.withOpacity(alpha * 0.8)
          ..strokeWidth = 1.0;

        _iceShardPath.reset();
        _iceShardPath.moveTo(0, -size);
        _iceShardPath.lineTo(size * 0.7, size * 0.5);
        _iceShardPath.lineTo(-size * 0.6, size * 0.8);
        _iceShardPath.close();

        canvas.drawPath(_iceShardPath, _fillPaint);
        canvas.drawPath(_iceShardPath, _strokePaint);
        break;

      case ParticleType.shockwave:
        final waveRadius = size * (0.3 + progress * 0.7);
        _strokePaint
          ..color = color.withOpacity(alpha * 0.65)
          ..strokeWidth = (1.0 - progress) * 4.0;
        canvas.drawCircle(Offset.zero, waveRadius, _strokePaint);
        break;

      case ParticleType.floatingText:
        if (_cachedTextPainter != null) {
          _cachedTextPainter!.paint(
            canvas,
            Offset(-_cachedTextPainter!.width / 2, -_cachedTextPainter!.height / 2),
          );
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
  shockwave,
  floatingText,
}
