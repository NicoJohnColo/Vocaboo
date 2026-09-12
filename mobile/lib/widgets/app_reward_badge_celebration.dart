import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/motion/motion_tokens.dart';
import '../core/motion/typography_tokens.dart';

enum AppBadgeTier {
  gold,
  silver,
  bronze,
}

extension AppBadgeTierExtension on AppBadgeTier {
  List<Color> get gradientColors {
    switch (this) {
      case AppBadgeTier.gold:
        return const [Color(0xFFFFE68A), Color(0xFFFFC107), Color(0xFFE6A100)];
      case AppBadgeTier.silver:
        return const [Color(0xFFF0F0F0), Color(0xFFC0C0C0), Color(0xFF9A9A9A)];
      case AppBadgeTier.bronze:
        return const [Color(0xFFF0C89A), Color(0xFFCD7F32), Color(0xFF9C5A1F)];
    }
  }

  Color get primaryColor {
    switch (this) {
      case AppBadgeTier.gold:
        return const Color(0xFFD97706);
      case AppBadgeTier.silver:
        return const Color(0xFF64748B);
      case AppBadgeTier.bronze:
        return const Color(0xFF9C5A1F);
    }
  }

  Color get glowColor {
    switch (this) {
      case AppBadgeTier.gold:
        return const Color(0xFFFFC107);
      case AppBadgeTier.silver:
        return const Color(0xFFCBD5E1);
      case AppBadgeTier.bronze:
        return const Color(0xFFCD7F32);
    }
  }

  String get defaultTitle {
    switch (this) {
      case AppBadgeTier.gold:
        return 'Gold Badge Earned';
      case AppBadgeTier.silver:
        return 'Silver Badge Earned';
      case AppBadgeTier.bronze:
        return 'Bronze Badge Earned';
    }
  }

  String get defaultSubtitle {
    switch (this) {
      case AppBadgeTier.gold:
        return 'Flawless performance! Perfect lesson.';
      case AppBadgeTier.silver:
        return 'Solid run! Great effort and accuracy.';
      case AppBadgeTier.bronze:
        return 'Completed! Keep practicing to reach gold.';
    }
  }

  String get emoji {
    switch (this) {
      case AppBadgeTier.gold:
        return '🥇';
      case AppBadgeTier.silver:
        return '🥈';
      case AppBadgeTier.bronze:
        return '🥉';
    }
  }
}

/// Helper method to infer tier from percentage score or error count
AppBadgeTier badgeTierFromScore(double score) {
  if (score >= 90.0) return AppBadgeTier.gold;
  if (score >= 75.0) return AppBadgeTier.silver;
  return AppBadgeTier.bronze;
}

AppBadgeTier badgeTierFromString(String? type) {
  if (type == null) return AppBadgeTier.bronze;
  final upper = type.toUpperCase();
  if (upper.contains('GOLD') || upper.contains('PERFECT')) return AppBadgeTier.gold;
  if (upper.contains('SILVER')) return AppBadgeTier.silver;
  return AppBadgeTier.bronze;
}

/// A lesson-completion reward badge reveal animation with:
/// - 300ms initial delay
/// - 700ms scale (0.3x -> 1.15x -> 1.0x) and overshoot rotation (-30deg -> +8deg -> 0deg)
/// - 900ms brightness shine pass (1 -> 1.5 -> 1)
/// - 500ms delayed title & subtitle slide-up
/// - Gold-tier celebratory confetti burst
/// - Tap-to-skip support
class AppRewardBadgeReveal extends StatefulWidget {
  final AppBadgeTier tier;
  final String? title;
  final String? subtitle;
  final double badgeSize;
  final bool autoPlay;
  final VoidCallback? onAnimationComplete;
  final Color? titleColor;
  final Color? subtitleColor;

  const AppRewardBadgeReveal({
    super.key,
    required this.tier,
    this.title,
    this.subtitle,
    this.badgeSize = 108.0,
    this.autoPlay = true,
    this.onAnimationComplete,
    this.titleColor,
    this.subtitleColor,
  });

  @override
  State<AppRewardBadgeReveal> createState() => _AppRewardBadgeRevealState();
}

class _AppRewardBadgeRevealState extends State<AppRewardBadgeReveal>
    with TickerProviderStateMixin {
  late AnimationController _revealController;
  late AnimationController _shineController;
  late AnimationController _labelController;
  late AnimationController _confettiController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _shineAnimation;
  late Animation<double> _labelOpacityAnimation;
  late Animation<Offset> _labelSlideAnimation;

  bool _isFinished = false;
  static const Cubic _springCurve = Cubic(0.34, 1.56, 0.64, 1.0);

  @override
  void initState() {
    super.initState();

    // 1. Reveal Controller (700ms)
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 1.15)
            .chain(CurveTween(curve: _springCurve)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
    ]).animate(_revealController);

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        // -30 deg (-0.523 rad) -> +8 deg (+0.14 rad) -> 0 deg
        tween: Tween<double>(begin: -0.5236, end: 0.1396)
            .chain(CurveTween(curve: _springCurve)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.1396, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
    ]).animate(_revealController);

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    // 2. Shine Controller (900ms)
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _shineAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.5)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.5, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 55,
      ),
    ]).animate(_shineController);

    // 3. Label Controller (450ms)
    _labelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _labelOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _labelController, curve: Curves.easeOut),
    );

    _labelSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _labelController, curve: Curves.easeOutCubic),
    );

    // 4. Confetti Controller (Gold only)
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    if (widget.autoPlay) {
      _startSequence();
    }
  }

  void _startSequence() async {
    // 300ms initial delay so it feels natural
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // Trigger reveal
    _revealController.forward();

    // Trigger label reveal at ~500ms into sequence
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _labelController.forward();
    });

    // When reveal finishes (~700ms), trigger shine and haptic
    _revealController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        try {
          HapticFeedback.mediumImpact();
        } catch (_) {}

        _shineController.forward();

        if (widget.tier == AppBadgeTier.gold) {
          _confettiController.forward();
        }

        setState(() {
          _isFinished = true;
        });

        if (widget.onAnimationComplete != null) {
          widget.onAnimationComplete!();
        }
      }
    });
  }

  void _skipAnimation() {
    if (_isFinished) return;
    _revealController.value = 1.0;
    _shineController.value = 1.0;
    _labelController.value = 1.0;
    if (widget.tier == AppBadgeTier.gold) {
      _confettiController.value = 1.0;
    }
    setState(() {
      _isFinished = true;
    });
    if (widget.onAnimationComplete != null) {
      widget.onAnimationComplete!();
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    _shineController.dispose();
    _labelController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.title ?? widget.tier.defaultTitle;
    final subtitleText = widget.subtitle ?? widget.tier.defaultSubtitle;
    final isReduced = AppMotion.isReducedMotion(context);

    if (isReduced) {
      return _buildStaticBadge(titleText, subtitleText);
    }

    return GestureDetector(
      onTap: _skipAnimation,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Badge with Confetti & Spotlight ──────────────────────────
          SizedBox(
            width: widget.badgeSize * 2.2,
            height: widget.badgeSize * 1.6,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Gold Confetti Particles Burst
                if (widget.tier == AppBadgeTier.gold)
                  AnimatedBuilder(
                    animation: _confettiController,
                    builder: (context, _) {
                      return CustomPaint(
                        size: Size(widget.badgeSize * 2.0, widget.badgeSize * 1.5),
                        painter: _ConfettiBurstPainter(
                          progress: _confettiController.value,
                        ),
                      );
                    },
                  ),

                // Animated Badge (Scale + Rotate + Brightness Shine)
                AnimatedBuilder(
                  animation: Listenable.merge([_revealController, _shineController]),
                  builder: (context, child) {
                    final scale = _scaleAnimation.value;
                    final rotation = _rotationAnimation.value;
                    final opacity = _opacityAnimation.value;
                    final brightness = _shineController.isAnimating
                        ? _shineAnimation.value
                        : 1.0;

                    return Opacity(
                      opacity: opacity,
                      child: Transform.rotate(
                        angle: rotation,
                        child: Transform.scale(
                          scale: scale,
                          child: ColorFiltered(
                            colorFilter: ColorFilter.matrix([
                              brightness, 0, 0, 0, 0,
                              0, brightness, 0, 0, 0,
                              0, 0, brightness, 0, 0,
                              0, 0, 0, 1, 0,
                            ]),
                            child: _buildBadgeShape(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Label Text (Slide & Fade in at 500ms) ──────────────────────
          SlideTransition(
            position: _labelSlideAnimation,
            child: FadeTransition(
              opacity: _labelOpacityAnimation,
              child: Column(
                children: [
                  Text(
                    titleText,
                    textAlign: TextAlign.center,
                    style: AppTypography.baloo2(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: widget.titleColor ?? const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      subtitleText,
                      textAlign: TextAlign.center,
                      style: AppTypography.nunito(
                        fontSize: 14,
                        color: widget.subtitleColor ?? const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeShape() {
    final colors = widget.tier.gradientColors;
    final size = widget.badgeSize;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.3),
          radius: 0.85,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.tier.glowColor.withValues(alpha: 0.38),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.65),
          width: 3.5,
        ),
      ),
      child: Center(
        child: Container(
          width: size * 0.72,
          height: size * 0.72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.emoji_events_rounded,
              size: size * 0.44,
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaticBadge(String title, String subtitle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBadgeShape(),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.baloo2(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: widget.titleColor ?? const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTypography.nunito(
            fontSize: 14,
            color: widget.subtitleColor ?? const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Particle painter for the gold celebratory confetti burst
class _ConfettiBurstPainter extends CustomPainter {
  final double progress;
  _ConfettiBurstPainter({required this.progress});

  static final List<Color> _colors = [
    const Color(0xFFFFD700), // Gold
    const Color(0xFFFF9800), // Amber
    const Color(0xFF06A6FF), // Cyan
    const Color(0xFF10B981), // Emerald
    const Color(0xFFEC4899), // Pink
    const Color(0xFF2563EB), // Royal Blue
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.001 || progress >= 0.99) return;

    final center = Offset(size.width / 2, size.height / 2);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    const particleCount = 28;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i * 2 * math.pi) / particleCount;
      final distance = (40.0 + (i % 5) * 16.0) * progress * 1.8;
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance - (progress * 15);
      final radius = ((i % 3) + 3.0) * (1.0 - progress * 0.4);
      final color = _colors[i % _colors.length].withValues(alpha: opacity);

      final paint = Paint()..color = color;
      if (i % 2 == 0) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: radius * 2.2, height: radius * 1.2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
