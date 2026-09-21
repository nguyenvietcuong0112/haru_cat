import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/player_data.dart';
import '../../audio/audio_manager.dart';

class LuckyDrawDialog extends StatefulWidget {
  const LuckyDrawDialog({super.key});

  @override
  State<LuckyDrawDialog> createState() => _LuckyDrawDialogState();
}

class _LuckyDrawDialogState extends State<LuckyDrawDialog> with SingleTickerProviderStateMixin {
  final PlayerData _playerData = PlayerData();
  final AudioManager _audio = AudioManager();
  late AnimationController _animController;
  late Animation<double> _animation;

  double _currentAngle = 0;
  bool _isSpinning = false;
  String? _wonReward;

  final List<Map<String, dynamic>> _prizes = [
    {'label': '100 Silver', 'type': 'silver', 'amount': 100, 'color': Color(0xFFFFD54F)},
    {'label': '5 Gold', 'type': 'gold', 'amount': 5, 'color': Color(0xFFFF8A65)},
    {'label': '1 Hammer', 'type': 'hammer', 'amount': 1, 'color': Color(0xFF81D4FA)},
    {'label': '250 Silver', 'type': 'silver', 'amount': 250, 'color': Color(0xFFAED581)},
    {'label': '10 Gold', 'type': 'gold', 'amount': 10, 'color': Color(0xFFFFB74D)},
    {'label': '1 Vợt', 'type': 'net', 'amount': 1, 'color': Color(0xFFBA68C8)},
    {'label': '1 Wand', 'type': 'wand', 'amount': 1, 'color': Color(0xFF4DB6AC)},
    {'label': '20 Gold', 'type': 'gold', 'amount': 20, 'color': Color(0xFFFFD54F)},
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

    // Pointer is at the top (3*pi/2 or 0 depending on setup).
    // Let's align target angle to the top pointer
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

      // Determine which prize was selected
      // Slice index pointed by top (270 degrees or top vertical)
      final prize = _prizes[randomPrizeIndex];
      _grantPrize(prize);

      _playerData.recordSpin();
      _audio.playWin();

      setState(() {
        _wonReward = 'You won ${prize['label']}!';
      });
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

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9EE),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFD6A266), width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 32),
                const Text(
                  'LUCKY DRAW',
                  style: TextStyle(
                    fontFamily: 'JandaManatee',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B4226),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF6B4226)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Wheel Container
            Stack(
              alignment: Alignment.center,
              children: [
                // Wheel
                Transform.rotate(
                  angle: _currentAngle,
                  child: CustomPaint(
                    size: const Size(240, 240),
                    painter: _WheelPainter(prizes: _prizes),
                  ),
                ),

                // Center hub
                Image.asset(
                  'assets/images/sprites/ui/luckydraw_center.png',
                  width: 50,
                  height: 50,
                  errorBuilder: (_, __, ___) => Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.star, color: Colors.white, size: 24),
                  ),
                ),

                // Pointer at top
                Positioned(
                  top: 0,
                  child: Image.asset(
                    'assets/images/sprites/ui/luckydraw_arrow.png',
                    width: 36,
                    height: 36,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.arrow_drop_down,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reward feedback
            if (_wonReward != null) ...[
              Text(
                '🎉 $_wonReward',
                style: const TextStyle(
                  fontFamily: 'BrandonText',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Spin Button
            GestureDetector(
              onTap: _isSpinning ? null : _spin,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _isSpinning
                        ? 'SPINNING...'
                        : canFree
                            ? 'FREE SPIN NOW!'
                            : 'WATCH AD & SPIN',
                    style: const TextStyle(
                      fontFamily: 'JandaManatee',
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            if (!canFree && remaining > Duration.zero)
              Text(
                'Next free spin in: ${remaining.inMinutes}m ${remaining.inSeconds % 60}s',
                style: const TextStyle(
                  fontFamily: 'BrandonText',
                  fontSize: 12,
                  color: Color(0xFF8B5A2B),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> prizes;

  _WheelPainter({required this.prizes});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (2 * pi) / prizes.length;

    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF8B5A2B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < prizes.length; i++) {
      paint.color = prizes[i]['color'] as Color;
      final startAngle = i * sweepAngle;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      // Draw text label
      canvas.save();
      final textAngle = startAngle + sweepAngle / 2;
      canvas.translate(center.dx, center.dy);
      canvas.rotate(textAngle);

      final textSpan = TextSpan(
        text: prizes[i]['label'] as String,
        style: const TextStyle(
          color: Color(0xFF4A2810),
          fontSize: 11,
          fontFamily: 'BrandonText',
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(radius * 0.45, -textPainter.height / 2));
      canvas.restore();
    }

    // Outer wheel ring
    final outerRing = Paint()
      ..color = const Color(0xFFD6A266)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius, outerRing);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
