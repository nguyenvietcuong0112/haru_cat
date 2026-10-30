import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'particle_fx.dart';

class ParticleManagerComponent extends Component {
  final List<GameParticle> _particles = [];
  final List<_AquaticWaveSweepEffect> _waves = [];
  final Random _random = Random();

  void addParticle(GameParticle p) {
    _particles.add(p);
  }

  void spawnLandingSplash(double x, double y, int blockWidth) {
    final count = 3 + blockWidth * 2;
    for (int i = 0; i < count; i++) {
      final angle = -pi / 2 + (_random.nextDouble() - 0.5) * pi * 0.8;
      final speed = 75.0 + _random.nextDouble() * 115.0;
      _particles.add(GameParticle(
        x: x + (_random.nextDouble() - 0.5) * 18.0,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: 2.0 + _random.nextDouble() * 2.4,
        maxLife: 0.28 + _random.nextDouble() * 0.14,
        color: i % 3 == 0 ? const Color(0xFFB2EBF2) : const Color(0xFF4DD0E1),
        type: ParticleType.waterDrop,
      ));
    }
  }

  /// Juicy per-fish pop burst: concentric water ripple + rising glossy bubbles + twinkling stars
  void spawnFishPopBurst(
    double centerX,
    double centerY,
    double blockPixelWidth,
    int combo, {
    double delay = 0.0,
  }) {
    final isCombo = combo > 1;
    final primaryColor = isCombo ? const Color(0xFFFFD54F) : const Color(0xFF00E5FF);
    final secondaryColor = isCombo ? const Color(0xFFFF80AB) : const Color(0xFF4DD0E1);

    // 1. Expanding concentric water ripple ring
    _particles.add(GameParticle(
      x: centerX,
      y: centerY,
      vx: 0,
      vy: 0,
      size: max(30.0, blockPixelWidth * 0.62),
      maxLife: 0.36,
      delay: delay,
      color: primaryColor,
      type: ParticleType.shockwave,
    ));

    // 2. Buoyant glossy water bubbles rising from the popped fish
    final approxCells = max(1, (blockPixelWidth / 42.0).round());
    final bubbleCount = 4 + approxCells * 2;
    for (int i = 0; i < bubbleCount; i++) {
      final spreadX = (_random.nextDouble() - 0.5) * (blockPixelWidth * 0.78);
      final spreadY = (_random.nextDouble() - 0.5) * 14.0;
      _particles.add(GameParticle(
        x: centerX + spreadX,
        y: centerY + spreadY,
        vx: (_random.nextDouble() - 0.5) * 55.0,
        vy: -(45.0 + _random.nextDouble() * 85.0),
        size: 3.2 + _random.nextDouble() * 4.6,
        maxLife: 0.48 + _random.nextDouble() * 0.28,
        delay: delay + _random.nextDouble() * 0.04,
        color: i % 3 == 0 ? primaryColor : const Color(0xFF80DEEA),
        rotation: _random.nextDouble() * 2 * pi,
        type: ParticleType.bubble,
      ));
    }

    // 3. Twinkling 5-point starlight sparkles
    final starCount = 3 + approxCells + min(3, combo);
    for (int i = 0; i < starCount; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 55.0 + _random.nextDouble() * 115.0;
      final starColor = i % 3 == 0
          ? const Color(0xFFFFD54F)
          : (i % 3 == 1 ? primaryColor : secondaryColor);
      _particles.add(GameParticle(
        x: centerX + (_random.nextDouble() - 0.5) * (blockPixelWidth * 0.5),
        y: centerY + (_random.nextDouble() - 0.5) * 10.0,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 25.0,
        size: 4.5 + _random.nextDouble() * 4.2,
        maxLife: 0.42 + _random.nextDouble() * 0.22,
        delay: delay,
        color: starColor,
        rotation: _random.nextDouble() * 2 * pi,
        vRotation: (_random.nextDouble() - 0.5) * 10.0,
        type: ParticleType.star,
      ));
    }

    // 4. Crisp splashing water droplets
    for (int i = 0; i < 4; i++) {
      final angle = -pi / 2 + (_random.nextDouble() - 0.5) * pi * 0.9;
      final speed = 70.0 + _random.nextDouble() * 95.0;
      _particles.add(GameParticle(
        x: centerX + (_random.nextDouble() - 0.5) * (blockPixelWidth * 0.4),
        y: centerY,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: 2.4 + _random.nextDouble() * 2.2,
        maxLife: 0.32 + _random.nextDouble() * 0.14,
        delay: delay,
        color: const Color(0xFF26C6DA),
        type: ParticleType.waterDrop,
      ));
    }
  }

  void spawnIceBreak(double centerX, double centerY, [double blockPixelWidth = 44.0]) {
    _particles.add(GameParticle(
      x: centerX,
      y: centerY,
      vx: 0,
      vy: 0,
      size: max(34.0, blockPixelWidth * 0.65),
      maxLife: 0.32,
      color: const Color(0xFF80DEEA),
      type: ParticleType.shockwave,
    ));

    for (int i = 0; i < 14; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 85.0 + _random.nextDouble() * 155.0;
      _particles.add(GameParticle(
        x: centerX + (_random.nextDouble() - 0.5) * (blockPixelWidth * 0.55),
        y: centerY + (_random.nextDouble() - 0.5) * 10.0,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 20.0,
        size: 4.8 + _random.nextDouble() * 4.8,
        maxLife: 0.46 + _random.nextDouble() * 0.24,
        color: i % 2 == 0 ? const Color(0xFFE0F7FA) : const Color(0xFF80DEEA),
        rotation: _random.nextDouble() * 2 * pi,
        vRotation: (_random.nextDouble() - 0.5) * 13.0,
        type: ParticleType.iceShard,
      ));
    }
  }

  void spawnSeaweedBreak(double centerX, double centerY, [double blockPixelWidth = 44.0]) {
    for (int i = 0; i < 10; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 55.0 + _random.nextDouble() * 105.0;
      _particles.add(GameParticle(
        x: centerX + (_random.nextDouble() - 0.5) * (blockPixelWidth * 0.6),
        y: centerY,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 35.0,
        size: 4.5 + _random.nextDouble() * 3.5,
        maxLife: 0.50 + _random.nextDouble() * 0.22,
        color: i % 2 == 0 ? const Color(0xFF26A69A) : const Color(0xFF66BB6A),
        rotation: _random.nextDouble() * 2 * pi,
        vRotation: (_random.nextDouble() - 0.5) * 9.0,
        type: ParticleType.seaweedLeaf,
      ));
    }

    for (int i = 0; i < 5; i++) {
      _particles.add(GameParticle(
        x: centerX + (_random.nextDouble() - 0.5) * (blockPixelWidth * 0.5),
        y: centerY,
        vx: (_random.nextDouble() - 0.5) * 40.0,
        vy: -(50.0 + _random.nextDouble() * 60.0),
        size: 3.0 + _random.nextDouble() * 3.2,
        maxLife: 0.45,
        color: const Color(0xFF80CBC4),
        type: ParticleType.bubble,
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
      size: 92.0,
      maxLife: 0.36,
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

  /// Spawns a graceful left-to-right translucent aquatic tidal wave & starlight ribbon
  void spawnAquaticRowWave(double y, double cellSize, double boardWidth, int combo) {
    _waves.add(_AquaticWaveSweepEffect(
      y: y,
      rowHeight: cellSize,
      boardWidth: boardWidth,
      combo: combo,
      onEmitTrailParticle: (px, py, isStar) {
        if (isStar) {
          _particles.add(GameParticle(
            x: px,
            y: py + (_random.nextDouble() - 0.5) * (cellSize * 0.45),
            vx: -20.0 + (_random.nextDouble() - 0.5) * 40.0,
            vy: -35.0 - _random.nextDouble() * 45.0,
            size: 3.8 + _random.nextDouble() * 3.4,
            maxLife: 0.38 + _random.nextDouble() * 0.18,
            color: combo > 1 ? const Color(0xFFFFD54F) : const Color(0xFF4DD0E1),
            rotation: _random.nextDouble() * 2 * pi,
            vRotation: (_random.nextDouble() - 0.5) * 8.0,
            type: ParticleType.star,
          ));
        } else {
          _particles.add(GameParticle(
            x: px,
            y: py + (_random.nextDouble() - 0.5) * (cellSize * 0.5),
            vx: -15.0 + (_random.nextDouble() - 0.5) * 30.0,
            vy: -40.0 - _random.nextDouble() * 55.0,
            size: 2.6 + _random.nextDouble() * 3.4,
            maxLife: 0.42 + _random.nextDouble() * 0.22,
            color: combo > 1 ? const Color(0xFFFFE082) : const Color(0xFF80DEEA),
            rotation: _random.nextDouble() * 2 * pi,
            type: ParticleType.bubble,
          ));
        }
      },
    ));
  }

  void spawnRowLaser(double y, double boardWidth, int combo) {
    spawnAquaticRowWave(y, 44.0, boardWidth, combo);
  }

  void spawnFloatingText(
    double x,
    double y,
    String text,
    Color color, {
    double size = 18.0,
    double delay = 0.0,
  }) {
    _particles.add(GameParticle(
      x: x,
      y: y,
      vx: (_random.nextDouble() - 0.5) * 16.0,
      vy: -78.0,
      size: size,
      maxLife: 0.78,
      delay: delay,
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

    for (int i = _waves.length - 1; i >= 0; i--) {
      final wave = _waves[i];
      wave.update(dt);
      if (wave.isDead) {
        _waves.removeAt(i);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (final wave in _waves) {
      wave.render(canvas);
    }

    for (final p in _particles) {
      p.render(canvas);
    }
  }
}

/// Flowing left-to-right ocean current & starlight ribbon (replaces harsh white laser flash)
class _AquaticWaveSweepEffect {
  final double y;
  final double rowHeight;
  final double boardWidth;
  final int combo;
  final void Function(double x, double y, bool isStar) onEmitTrailParticle;

  double elapsed = 0.0;
  final double duration = 0.38;
  double _lastEmitX = -20.0;

  static final Paint _wakeGlowPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9.0);
  static final Paint _ribbonPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _crestPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
  static final Path _sinePathA = Path();
  static final Path _sinePathB = Path();
  static final Path _crestPath = Path();

  _AquaticWaveSweepEffect({
    required this.y,
    required this.rowHeight,
    required this.boardWidth,
    required this.combo,
    required this.onEmitTrailParticle,
  });

  bool get isDead => elapsed >= duration;

  void update(double dt) {
    elapsed += dt;
    final sweepProgress = (elapsed / (duration * 0.62)).clamp(0.0, 1.0);
    final crestX = sweepProgress * (boardWidth + 24.0);

    // Emit bubbles and stars smoothly along the advancing wave crest
    if (sweepProgress < 1.0 && crestX - _lastEmitX >= 22.0) {
      _lastEmitX = crestX;
      final clampedX = crestX.clamp(4.0, boardWidth - 4.0);
      onEmitTrailParticle(clampedX, y, false);
      if ((clampedX ~/ 22) % 2 == 0) {
        onEmitTrailParticle(clampedX, y, true);
      }
    }
  }

  void render(Canvas canvas) {
    final totalProgress = (elapsed / duration).clamp(0.0, 1.0);
    // Wave crest sweeps across the row in the first 62% (~235ms), then wake dissolves smoothly
    final sweepProgress = (elapsed / (duration * 0.62)).clamp(0.0, 1.0);
    final fadeAlpha = totalProgress < 0.45
        ? 1.0
        : (1.0 - (totalProgress - 0.45) / 0.55).clamp(0.0, 1.0);

    final isCombo = combo > 1;
    final primaryColor = isCombo ? const Color(0xFFFFB300) : const Color(0xFF00BCD4);
    final accentColor = isCombo ? const Color(0xFFFF80AB) : const Color(0xFF4DD0E1);

    final headX = (sweepProgress * boardWidth).clamp(0.0, boardWidth);
    final tailX = (totalProgress > 0.22 ? ((totalProgress - 0.22) / 0.78) * boardWidth * 0.65 : 0.0)
        .clamp(0.0, headX);

    if (headX - tailX > 2.0) {
      // 1. Soft translucent water wake aura (subtle ocean glow, zero harsh white!)
      final wakeHeight = rowHeight * (0.52 - totalProgress * 0.18);
      _wakeGlowPaint.color = primaryColor.withOpacity(0.24 * fadeAlpha);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(tailX, y - wakeHeight / 2, headX - tailX, wakeHeight),
          Radius.circular(wakeHeight / 2),
        ),
        _wakeGlowPaint,
      );

      // 2. Dual undulating water current sine ribbons
      _sinePathA.reset();
      _sinePathB.reset();
      final phase = elapsed * 20.0;
      final amp = rowHeight * 0.16 * fadeAlpha;
      const step = 12.0;

      bool first = true;
      for (double px = tailX; px <= headX; px += step) {
        final env = sin(((px - tailX) / max(1.0, headX - tailX)) * pi);
        final yOffsetA = sin(px * 0.055 - phase) * amp * env;
        final yOffsetB = cos(px * 0.055 - phase * 1.15) * (amp * 0.75) * env;
        if (first) {
          _sinePathA.moveTo(px, y + yOffsetA);
          _sinePathB.moveTo(px, y - yOffsetB);
          first = false;
        } else {
          _sinePathA.lineTo(px, y + yOffsetA);
          _sinePathB.lineTo(px, y - yOffsetB);
        }
      }

      _ribbonPaint
        ..color = accentColor.withOpacity(0.62 * fadeAlpha)
        ..strokeWidth = 2.6;
      canvas.drawPath(_sinePathA, _ribbonPaint);

      _ribbonPaint
        ..color = (isCombo ? const Color(0xFFFFE082) : const Color(0xFFB2EBF2))
            .withOpacity(0.55 * fadeAlpha)
        ..strokeWidth = 1.8;
      canvas.drawPath(_sinePathB, _ribbonPaint);
    }

    // 3. Curved crescent wave crest head while sweeping across board
    if (sweepProgress < 1.0) {
      final crestAlpha = (1.0 - sweepProgress * 0.25) * fadeAlpha;
      final crestH = rowHeight * 0.36;
      _crestPath.reset();
      _crestPath.moveTo(headX - 14.0, y - crestH);
      _crestPath.quadraticBezierTo(headX + 10.0, y, headX - 14.0, y + crestH);
      _crestPath.quadraticBezierTo(headX + 2.0, y, headX - 14.0, y - crestH);
      _crestPath.close();

      _crestPaint.color = (isCombo ? const Color(0xFFFFD54F) : const Color(0xFF80DEEA))
          .withOpacity(0.75 * crestAlpha);
      canvas.drawPath(_crestPath, _crestPaint);
    }
  }
}
