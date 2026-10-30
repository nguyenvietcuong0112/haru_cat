import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'particle_fx.dart';

class ParticleManagerComponent extends Component {
  final List<GameParticle> _particles = [];
  final List<_LaserBeamEffect> _lasers = [];
  final Random _random = Random();

  void addParticle(GameParticle p) {
    _particles.add(p);
  }

  void spawnLandingSplash(double x, double y, int blockWidth) {
    final count = 3 + blockWidth * 2;
    for (int i = 0; i < count; i++) {
      final angle = -pi / 2 + (_random.nextDouble() - 0.5) * pi * 0.8;
      final speed = 80.0 + _random.nextDouble() * 120.0;
      _particles.add(GameParticle(
        x: x + (_random.nextDouble() - 0.5) * 16.0,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: 2.0 + _random.nextDouble() * 2.5,
        maxLife: 0.28 + _random.nextDouble() * 0.15,
        color: const Color(0xFF80DEEA),
        type: ParticleType.waterDrop,
      ));
    }
  }

  void spawnIceBreak(double centerX, double centerY) {
    for (int i = 0; i < 12; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 90.0 + _random.nextDouble() * 150.0;
      _particles.add(GameParticle(
        x: centerX,
        y: centerY,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: 5.0 + _random.nextDouble() * 5.0,
        maxLife: 0.5 + _random.nextDouble() * 0.25,
        color: const Color(0xFFE0F7FA),
        rotation: _random.nextDouble() * 2 * pi,
        vRotation: (_random.nextDouble() - 0.5) * 12.0,
        type: ParticleType.iceShard,
      ));
    }
  }

  void spawnBombExplosion(double centerX, double centerY) {
    // 1. Shockwave ring
    _particles.add(GameParticle(
      x: centerX,
      y: centerY,
      vx: 0,
      vy: 0,
      size: 90.0,
      maxLife: 0.35,
      color: const Color(0xFFFF5252),
      type: ParticleType.shockwave,
    ));

    // 2. Fiery sparks & bubbles
    for (int i = 0; i < 20; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 120.0 + _random.nextDouble() * 180.0;
      _particles.add(GameParticle(
        x: centerX,
        y: centerY,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: 3.5 + _random.nextDouble() * 4.0,
        maxLife: 0.4 + _random.nextDouble() * 0.2,
        color: i % 2 == 0 ? const Color(0xFFFF7043) : const Color(0xFFFFEB3B),
        type: ParticleType.spark,
      ));
    }
  }

  void spawnRowLaser(double y, double boardWidth, int combo) {
    _lasers.add(_LaserBeamEffect(y: y, boardWidth: boardWidth, combo: combo));

    // Stars and sparks along the row
    for (int i = 0; i < 16; i++) {
      final px = _random.nextDouble() * boardWidth;
      final py = y + (_random.nextDouble() - 0.5) * 18.0;
      final angle = -pi / 2 + (_random.nextDouble() - 0.5) * pi;
      final speed = 40.0 + _random.nextDouble() * 80.0;
      _particles.add(GameParticle(
        x: px,
        y: py,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: 4.0 + _random.nextDouble() * 4.5,
        maxLife: 0.45 + _random.nextDouble() * 0.25,
        color: i % 2 == 0 ? const Color(0xFFFFD54F) : const Color(0xFF00E5FF),
        rotation: _random.nextDouble() * 2 * pi,
        vRotation: (_random.nextDouble() - 0.5) * 8.0,
        type: ParticleType.star,
      ));
    }
  }

  void spawnFloatingText(double x, double y, String text, Color color, {double size = 18.0}) {
    _particles.add(GameParticle(
      x: x,
      y: y,
      vx: (_random.nextDouble() - 0.5) * 20.0,
      vy: -75.0,
      size: size,
      maxLife: 0.75,
      color: color,
      type: ParticleType.floatingText,
      text: text,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.update(dt);
      if (p.isDead) {
        _particles.removeAt(i);
      }
    }

    for (int i = _lasers.length - 1; i >= 0; i--) {
      final laser = _lasers[i];
      laser.update(dt);
      if (laser.isDead) {
        _lasers.removeAt(i);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (final laser in _lasers) {
      laser.render(canvas);
    }

    for (final p in _particles) {
      p.render(canvas);
    }
  }
}

class _LaserBeamEffect {
  final double y;
  final double boardWidth;
  final int combo;
  double life = 0.32;
  final double maxLife = 0.32;

  static final Paint _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
  static final Paint _corePaint = Paint();

  _LaserBeamEffect({
    required this.y,
    required this.boardWidth,
    required this.combo,
  });

  bool get isDead => life <= 0;

  void update(double dt) {
    life -= dt;
  }

  void render(Canvas canvas) {
    final progress = (1.0 - (life / maxLife)).clamp(0.0, 1.0);
    final alpha = (life / maxLife).clamp(0.0, 1.0);

    final beamHeight = (1.0 - progress) * (combo > 1 ? 14.0 : 8.0);
    final laserRect = Rect.fromLTWH(0, y - beamHeight / 2, boardWidth, beamHeight);

    final glowColor = combo > 1 ? const Color(0xFFFFD54F) : const Color(0xFF00E5FF);

    _glowPaint.color = glowColor.withOpacity(alpha * 0.65);
    canvas.drawRect(laserRect, _glowPaint);

    _corePaint.color = Colors.white.withOpacity(alpha * 0.95);
    canvas.drawRect(
      Rect.fromLTWH(0, y - beamHeight * 0.25, boardWidth, beamHeight * 0.5),
      _corePaint,
    );
  }
}
