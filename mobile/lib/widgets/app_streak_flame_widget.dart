import 'package:flutter/material.dart';
import '../core/motion/motion.dart';

/// Duolingo-style animated streak flame widget.
///
/// Features:
/// - Continuous subtle flame flicker/breathing (2s loop).
/// - Flare animation on streak increment (`1.0 -> 1.3 -> 1.0` with warm amber glow).
/// - Bold celebration number typography.
class AppStreakFlameWidget extends StatefulWidget {
  final int streakDays;
  final bool isEarnedToday;
  final double size;
  final TextStyle? numberStyle;

  const AppStreakFlameWidget({
    super.key,
    required this.streakDays,
    this.isEarnedToday = false,
    this.size = 32.0,
    this.numberStyle,
  });

  @override
  State<AppStreakFlameWidget> createState() => _AppStreakFlameWidgetState();
}

class _AppStreakFlameWidgetState extends State<AppStreakFlameWidget>
    with TickerProviderStateMixin {
  late AnimationController _flickerController;
  late Animation<double> _flickerAnimation;

  late AnimationController _flareController;
  late Animation<double> _flareAnimation;

  @override
  void initState() {
    super.initState();

    // Idle flicker/pulse
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _flickerAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(
        parent: _flickerController,
        curve: Curves.easeInOutSine,
      ),
    );

    if (widget.streakDays > 0) {
      _flickerController.repeat(reverse: true);
    }

    // Flare on streak update
    _flareController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _flareAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 60),
    ]).animate(
      CurvedAnimation(
        parent: _flareController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void didUpdateWidget(AppStreakFlameWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streakDays > oldWidget.streakDays) {
      _flareController.forward(from: 0.0);
    }
    if (widget.streakDays > 0 && !_flickerController.isAnimating) {
      _flickerController.repeat(reverse: true);
    } else if (widget.streakDays == 0 && _flickerController.isAnimating) {
      _flickerController.stop();
    }
  }

  @override
  void dispose() {
    _flickerController.dispose();
    _flareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReduced = AppMotion.isReducedMotion(context);
    final isActive = widget.streakDays > 0;
    final flameColor = isActive ? const Color(0xFFF97316) : const Color(0xFF94A3B8);
    final glowColor = isActive ? const Color(0xFFFBBF24) : Colors.transparent;

    Widget flameIcon = Icon(
      Icons.local_fire_department_rounded,
      color: flameColor,
      size: widget.size,
      shadows: isActive
          ? [
              Shadow(
                color: glowColor.withValues(alpha: 0.6),
                blurRadius: 10,
              ),
            ]
          : null,
    );

    Widget animatedFlame = AnimatedBuilder(
      animation: Listenable.merge([_flickerController, _flareController]),
      builder: (context, child) {
        if (isReduced) return child!;
        double scale = _flareController.isAnimating
            ? _flareAnimation.value
            : (_flickerController.isAnimating ? _flickerAnimation.value : 1.0);

        return Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: flameIcon,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFF7ED) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFFFDBA74) : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          animatedFlame,
          const SizedBox(width: 4),
          AppAnimatedCounter(
            value: widget.streakDays,
            style: widget.numberStyle ??
                AppTypography.displayMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: flameColor,
                ),
          ),
        ],
      ),
    );
  }
}
