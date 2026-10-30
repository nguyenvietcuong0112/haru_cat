import 'package:flutter/material.dart';
import '../../audio/audio_manager.dart';

/// Color & bevel presets matching Btn_Play.png, Btn_Shop.png, and Btn_Settings.png
class GameButtonPalette {
  final Color faceTop;
  final Color faceBottom;
  final Color bottomBevel;
  final Color innerHighlight;
  final Color borderColor;
  final Color textStroke;

  const GameButtonPalette({
    required this.faceTop,
    required this.faceBottom,
    required this.bottomBevel,
    required this.innerHighlight,
    required this.borderColor,
    required this.textStroke,
  });

  /// Matches Btn_Play.png (Juicy Lime Green)
  static const green = GameButtonPalette(
    faceTop: Color(0xFF96E832),
    faceBottom: Color(0xFF7ED31B),
    bottomBevel: Color(0xFF559E0B),
    innerHighlight: Color(0xFFD6F99E),
    borderColor: Color(0xFF245312),
    textStroke: Color(0xFF214D10),
  );

  /// Matches Btn_Shop.png (Warm Sandy Gold)
  static const gold = GameButtonPalette(
    faceTop: Color(0xFFEBD08B),
    faceBottom: Color(0xFFDDB968),
    bottomBevel: Color(0xFFB9903B),
    innerHighlight: Color(0xFFFBF0CE),
    borderColor: Color(0xFF5A4214),
    textStroke: Color(0xFF5A4010),
  );

  /// Matches Btn_Settings.png / Ocean HUD (Crystal Aqua)
  static const aqua = GameButtonPalette(
    faceTop: Color(0xFF6AE0F0),
    faceBottom: Color(0xFF3CC2D6),
    bottomBevel: Color(0xFF1D93A8),
    innerHighlight: Color(0xFFCEF8FD),
    borderColor: Color(0xFF135261),
    textStroke: Color(0xFF0F4A58),
  );

  /// Arcade Sunset Orange (Rewards / Spin / Boosters)
  static const orange = GameButtonPalette(
    faceTop: Color(0xFFFFB938),
    faceBottom: Color(0xFFFF9416),
    bottomBevel: Color(0xFFD96B00),
    innerHighlight: Color(0xFFFFE5AD),
    borderColor: Color(0xFF6B2F00),
    textStroke: Color(0xFF682C00),
  );

  /// Glossy Coral Red (Close / Danger / Game Over banner)
  static const coral = GameButtonPalette(
    faceTop: Color(0xFFFF7A7A),
    faceBottom: Color(0xFFF04848),
    bottomBevel: Color(0xFFC22525),
    innerHighlight: Color(0xFFFFC9C9),
    borderColor: Color(0xFF681313),
    textStroke: Color(0xFF631010),
  );

  /// Ocean Pearl Slate (Muted / Off / Secondary)
  static const slate = GameButtonPalette(
    faceTop: Color(0xFFB8CED7),
    faceBottom: Color(0xFF9AB4BF),
    bottomBevel: Color(0xFF75909C),
    innerHighlight: Color(0xFFE3EFF3),
    borderColor: Color(0xFF425A65),
    textStroke: Color(0xFF3B515B),
  );
}

/// Chunky 2D casual game typography with crisp cartoon outline & hard drop shadow
class GameStrokedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final TextAlign textAlign;
  final int? maxLines;

  const GameStrokedText(
    this.text, {
    super.key,
    this.fontSize = 18,
    this.fillColor = Colors.white,
    this.strokeColor = const Color(0xFF134B5A),
    this.strokeWidth = 4.0,
    this.textAlign = TextAlign.center,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasNonAscii = RegExp(r'[^\x00-\x7F]').hasMatch(text);
    final String activeFont = hasNonAscii ? 'NotoSans' : 'JandaManatee';

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: maxLines != null ? TextOverflow.ellipsis : null,
          style: TextStyle(
            fontFamily: activeFont,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            height: 1.12,
            letterSpacing: 0.4,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeJoin = StrokeJoin.round
              ..color = strokeColor,
            shadows: [
              Shadow(
                offset: const Offset(0, 2.2),
                blurRadius: 0,
                color: strokeColor.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
        Text(
          text,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: maxLines != null ? TextOverflow.ellipsis : null,
          style: TextStyle(
            fontFamily: activeFont,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            height: 1.12,
            letterSpacing: 0.4,
            color: fillColor,
          ),
        ),
      ],
    );
  }
}

/// Press-bounce wrapper with snappy 2D game squash feedback
class GameTapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool playSound;

  const GameTapScale({
    super.key,
    required this.child,
    required this.onTap,
    this.playSound = true,
  });

  @override
  State<GameTapScale> createState() => _GameTapScaleState();
}

class _GameTapScaleState extends State<GameTapScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        if (widget.playSound) {
          AudioManager().playClick();
        }
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// 3D Beveled Cartoon Game Button matching Btn_Play.png & Btn_Shop.png
class Game3DButton extends StatelessWidget {
  final String? label;
  final Widget? child;
  final IconData? icon;
  final GameButtonPalette palette;
  final VoidCallback? onTap;
  final double height;
  final double? width;
  final double fontSize;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const Game3DButton({
    super.key,
    this.label,
    this.child,
    this.icon,
    this.palette = GameButtonPalette.green,
    required this.onTap,
    this.height = 50,
    this.width = double.infinity,
    this.fontSize = 17,
    this.borderRadius = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final activePalette = onTap == null ? GameButtonPalette.slate : palette;

    return GameTapScale(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: activePalette.bottomBevel,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: activePalette.borderColor, width: 2.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4.5),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [activePalette.faceTop, activePalette.faceBottom],
              ),
              borderRadius: BorderRadius.circular((borderRadius - 3).clamp(4.0, 40.0)),
              border: Border.all(
                color: activePalette.innerHighlight.withValues(alpha: 0.72),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: child ??
                Row(
                  mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        color: Colors.white,
                        size: fontSize + 4,
                        shadows: [
                          Shadow(
                            color: activePalette.textStroke,
                            offset: const Offset(0, 2),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                      const SizedBox(width: 7),
                    ],
                    if (label != null)
                      Flexible(
                        child: GameStrokedText(
                          label!,
                          fontSize: fontSize,
                          strokeColor: activePalette.textStroke,
                          strokeWidth: 4.2,
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}

/// 3D Circular Glossy Medallion Toggle (for Music, Sound, Vibrate) matching Btn_Settings.png
class GameMedallionToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const GameMedallionToggle({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = isActive ? GameButtonPalette.green : GameButtonPalette.slate;

    return GameTapScale(
      onTap: onTap,
      playSound: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.bottomBevel,
              border: Border.all(color: p.borderColor, width: 2.6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [p.faceTop, p.faceBottom],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: Colors.white,
                size: 27,
                shadows: [
                  Shadow(
                    color: p.textStroke,
                    offset: const Offset(0, 2),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          GameStrokedText(
            label,
            fontSize: 12.5,
            fillColor: isActive ? Colors.white : const Color(0xFFE0EDF2),
            strokeColor: const Color(0xFF154C5B),
            strokeWidth: 3.2,
          ),
        ],
      ),
    );
  }
}

/// Synchronized Currency Pill for popup headers (matches HomeScreen Silver/Gold pills)
class GameWalletPill extends StatelessWidget {
  final String iconAsset;
  final String amount;

  const GameWalletPill({
    super.key,
    required this.iconAsset,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF5FAAC0), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF165B6E).withValues(alpha: 0.16),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            iconAsset,
            width: 20,
            height: 20,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.circle, size: 16, color: Colors.amber),
          ),
          const SizedBox(width: 5),
          GameStrokedText(
            amount,
            fontSize: 13.5,
            fillColor: Colors.white,
            strokeColor: const Color(0xFF174A5A),
            strokeWidth: 3.2,
          ),
        ],
      ),
    );
  }
}

/// Shared 2D Casual Ocean-Shell Popup Frame with Floating 3D Ribbon Banner & Close [X] Button
class GamePopupFrame extends StatelessWidget {
  final String title;
  final GameButtonPalette bannerPalette;
  final Widget child;
  final VoidCallback? onClose;
  final double maxWidth;
  final double? maxHeight;
  final EdgeInsetsGeometry innerPadding;

  const GamePopupFrame({
    super.key,
    required this.title,
    required this.child,
    this.bannerPalette = GameButtonPalette.aqua,
    this.onClose,
    this.maxWidth = 365,
    this.maxHeight,
    this.innerPadding = const EdgeInsets.fromLTRB(16, 26, 16, 16),
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.84, end: 1.0),
        duration: const Duration(milliseconds: 210),
        curve: Curves.easeOutBack,
        builder: (context, scale, content) => Transform.scale(
          scale: scale,
          child: content,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.84,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // 1. Main Outer Glossy Ocean Shell Bezel
              Container(
                margin: const EdgeInsets.only(top: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF63A6B8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF1A5666), width: 3.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF062C36).withValues(alpha: 0.42),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFC7F0F9),
                        Color(0xFF91D2E2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.72),
                      width: 1.8,
                    ),
                  ),
                  // 2. Inner Pearl-Aqua Recessed Board
                  child: Container(
                    width: double.infinity,
                    padding: innerPadding,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFF6FDFF),
                          Color(0xFFE6F8FC),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF72B5C7),
                        width: 2.0,
                      ),
                    ),
                    child: child,
                  ),
                ),
              ),

              // 3. Floating 3D Title Ribbon Plaque Perched at Top Center
              Positioned(
                top: 0,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 185),
                  padding: const EdgeInsets.only(bottom: 4.5),
                  decoration: BoxDecoration(
                    color: bannerPalette.bottomBevel,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: bannerPalette.borderColor, width: 2.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [bannerPalette.faceTop, bannerPalette.faceBottom],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: bannerPalette.innerHighlight.withValues(alpha: 0.75),
                        width: 1.6,
                      ),
                    ),
                    child: GameStrokedText(
                      title,
                      fontSize: 21,
                      strokeColor: bannerPalette.textStroke,
                      strokeWidth: 4.8,
                    ),
                  ),
                ),
              ),

              // 4. Glossy 3D Coral [X] Close Button Perched at Top Right
              if (onClose != null)
                Positioned(
                  top: 4,
                  right: -4,
                  child: GameTapScale(
                    onTap: onClose,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GameButtonPalette.coral.bottomBevel,
                        border: Border.all(
                          color: GameButtonPalette.coral.borderColor,
                          width: 2.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 4,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.only(bottom: 3.5),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              GameButtonPalette.coral.faceTop,
                              GameButtonPalette.coral.faceBottom,
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.55),
                            width: 1.4,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const GameStrokedText(
                          'X',
                          fontSize: 17,
                          strokeColor: Color(0xFF631010),
                          strokeWidth: 4.0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
