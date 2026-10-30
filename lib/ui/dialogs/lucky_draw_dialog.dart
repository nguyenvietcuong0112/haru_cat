import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/player_data.dart';
import '../../audio/audio_manager.dart';
import '../widgets/game_popup_kit.dart';

class LuckyDrawDialog extends StatefulWidget {
  const LuckyDrawDialog({super.key});

  @override
  State<LuckyDrawDialog> createState() => _LuckyDrawDialogState();
}

class _LuckyDrawDialogState extends State<LuckyDrawDialog>
    with SingleTickerProviderStateMixin {
  final PlayerData _playerData = PlayerData();
  final AudioManager _audio = AudioManager();
  late AnimationController _animController;
  late Animation<double> _animation;

  double _currentAngle = 0;
  bool _isSpinning = false;
  String? _wonReward;

  final List<Map<String, dynamic>> _prizes = [
    {'label': '100 Bạc', 'type': 'silver', 'amount': 100, 'color': const Color(0xFF4DD0E1)},
    {'label': '5 Vàng', 'type': 'gold', 'amount': 5, 'color': const Color(0xFFFFCA28)},
    {'label': '1 Búa', 'type': 'hammer', 'amount': 1, 'color': const Color(0xFF81D4FA)},
    {'label': '250 Bạc', 'type': 'silver', 'amount': 250, 'color': const Color(0xFF80CBC4)},
    {'label': '10 Vàng', 'type': 'gold', 'amount': 10, 'color': const Color(0xFFFFB74D)},
    {'label': '1 Vợt', 'type': 'net', 'amount': 1, 'color': const Color(0xFF90CAF9)},
    {'label': '1 Đũa', 'type': 'wand', 'amount': 1, 'color': const Color(0xFF4DB6AC)},
    {'label': '20 Vàng', 'type': 'gold', 'amount': 20, 'color': const Color(0xFFFF8A65)},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _animation = CurvedAnimation(parent: _animController, curve: Curves.easeOutQuart);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning) return;

    _audio.playClick();
    setState(() {
      _isSpinning = true;
      _wonReward = null;
    });

    final randomPrizeIndex = Random().nextInt(_prizes.length);
    const double fullRotations = 5 * 2 * pi;
    final double sliceAngle = (2 * pi) / _prizes.length;
    final targetAngle = fullRotations + (randomPrizeIndex * sliceAngle) + (sliceAngle / 2);

    final startAngle = _currentAngle % (2 * pi);
    final endAngle = startAngle + targetAngle;

    _animation = Tween<double>(begin: startAngle, end: endAngle).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _currentAngle = _animation.value;
        });
      });

    _animController.forward(from: 0).then((_) {
      _isSpinning = false;
      _currentAngle = endAngle % (2 * pi);

      final prize = _prizes[randomPrizeIndex];
      _grantPrize(prize);

      _playerData.recordSpin();
      _audio.playWin();

      if (mounted) {
        setState(() {
          _wonReward = '+${prize['label']}!';
        });
      }
    });
  }

  void _grantPrize(Map<String, dynamic> prize) {
    final type = prize['type'] as String;
    final amount = prize['amount'] as int;

    if (type == 'silver') {
      _playerData.addSilverFish(amount);
    } else if (type == 'gold') {
      _playerData.addGoldFish(amount);
    } else {
      _playerData.addBooster(type, amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canFree = _playerData.canFreeSpin();
    final remaining = _playerData.getSpinCooldownRemaining();

    return GamePopupFrame(
      title: 'LUCKY SPIN',
      bannerPalette: GameButtonPalette.orange,
      maxWidth: 365,
      onClose: _isSpinning ? null : () => Navigator.pop(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),

          // Ocean Wheel Container
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glow Backdrop
              Container(
                width: 246,
                height: 246,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00ACC1).withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),

              // Rotating Wheel
              Transform.rotate(
                angle: _currentAngle,
                child: CustomPaint(
                  size: const Size(236, 236),
                  painter: _OceanWheelPainter(prizes: _prizes),
                ),
              ),

              // Center Hub
              Image.asset(
                'assets/images/sprites/ui/luckydraw_center.png',
                width: 50,
                height: 50,
                errorBuilder: (_, __, ___) => Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF135060), width: 3),
                  ),
                  child: const Icon(Icons.star_rounded, color: Colors.white, size: 26),
                ),
              ),

              // Top Pointer
              Positioned(
                top: -2,
                child: Image.asset(
                  'assets/images/sprites/ui/luckydraw_arrow.png',
                  width: 36,
                  height: 36,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 42,
                    color: Color(0xFFE53935),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Reward Banner
          if (_wonReward != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF59D), Color(0xFFFFD54F)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFF8F00), width: 2),
              ),
              child: GameStrokedText(
                'CHÚC MỪNG: $_wonReward',
                fontSize: 15,
                strokeColor: const Color(0xFF682C00),
                strokeWidth: 3.5,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // 3D Spin Button
          Game3DButton(
            label: _isSpinning
                ? 'SPINNING...'
                : (canFree ? 'FREE SPIN!' : 'SPIN AGAIN!'),
            icon: Icons.casino_rounded,
            palette: canFree ? GameButtonPalette.green : GameButtonPalette.orange,
            height: 50,
            fontSize: 18,
            onTap: _isSpinning ? null : _spin,
          ),

          if (!canFree && remaining > Duration.zero) ...[
            const SizedBox(height: 8),
            Text(
              'Lượt miễn phí sau: ${remaining.inMinutes}p ${remaining.inSeconds % 60}s',
              style: const TextStyle(
                fontFamily: 'BrandonText',
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF236273),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OceanWheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> prizes;

  _OceanWheelPainter({required this.prizes});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    final sweepAngle = (2 * pi) / prizes.length;

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final dividerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    for (int i = 0; i < prizes.length; i++) {
      fillPaint.color = prizes[i]['color'] as Color;
      final startAngle = i * sweepAngle;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        fillPaint,
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        dividerPaint,
      );

      // Draw chunky game label on slice
      canvas.save();
      final textAngle = startAngle + sweepAngle / 2;
      canvas.translate(center.dx, center.dy);
      canvas.rotate(textAngle);

      final label = prizes[i]['label'] as String;

      final strokePainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'JandaManatee',
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.0
              ..strokeJoin = StrokeJoin.round
              ..color = const Color(0xFF104957),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final fillPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'JandaManatee',
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = Offset(radius * 0.38, -fillPainter.height / 2);
      strokePainter.paint(canvas, offset);
      fillPainter.paint(canvas, offset);
      canvas.restore();
    }

    // Outer Ocean Bezel Ring
    final outerDarkBorder = Paint()
      ..color = const Color(0xFF135060)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;
    canvas.drawCircle(center, radius, outerDarkBorder);

    final outerGoldRim = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, radius, outerGoldRim);

    // Pearl Peg Dots around rim
    final pegPaint = Paint()..color = Colors.white;
    for (int i = 0; i < prizes.length * 2; i++) {
      final a = (i * pi) / prizes.length;
      final px = center.dx + cos(a) * radius;
      final py = center.dy + sin(a) * radius;
      canvas.drawCircle(Offset(px, py), 2.2, pegPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
