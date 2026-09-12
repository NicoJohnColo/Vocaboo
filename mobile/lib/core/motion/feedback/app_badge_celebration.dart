import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../motion_tokens.dart';
import '../typography_tokens.dart';
import '../../../widgets/app_3d_button.dart';

/// Modal dialog and celebration banner for badge unlocks, streak records,
/// and level completion tailored for 9-12 year old learners.
class AppBadgeCelebration extends StatefulWidget {
  final String title;
  final String subtitle;
  final String badgeName;
  final Widget? badgeIcon;
  final num? scoreEarned;
  final String scoreSuffix;
  final VoidCallback onDismiss;
  final String buttonLabel;

  const AppBadgeCelebration({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badgeName,
    this.badgeIcon,
    this.scoreEarned,
    this.scoreSuffix = ' XP',
    required this.onDismiss,
    this.buttonLabel = 'AWESOME!',
  });

  /// Helper to display celebration modal dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String badgeName,
    Widget? badgeIcon,
    num? scoreEarned,
    String scoreSuffix = ' XP',
    String buttonLabel = 'AWESOME!',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppBadgeCelebration(
        title: title,
        subtitle: subtitle,
        badgeName: badgeName,
        badgeIcon: badgeIcon,
        scoreEarned: scoreEarned,
        scoreSuffix: scoreSuffix,
        buttonLabel: buttonLabel,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<AppBadgeCelebration> createState() => _AppBadgeCelebrationState();
}

class _AppBadgeCelebrationState extends State<AppBadgeCelebration>
    with TickerProviderStateMixin {
  late AnimationController _badgeController;
  late AnimationController _raysController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _badgeController = AnimationController(
      vsync: this,
      duration: AppDurations.long,
    );

    _scaleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _badgeController,
        curve: AppCurves.celebratory,
      ),
    );

    _raysController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _badgeController.forward();
  }

  @override
  void dispose() {
    _badgeController.dispose();
    _raysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReduced = AppMotion.isReducedMotion(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                blurRadius: 36,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge Spotlight with Rotating Rays
              Stack(
                alignment: Alignment.center,
                children: [
                  if (!isReduced)
                    AnimatedBuilder(
                      animation: _raysController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _raysController.value * 2 * math.pi,
                          child: CustomPaint(
                            size: const Size(180, 180),
                            painter: _SunburstPainter(),
                          ),
                        );
                      },
                    ),
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: isReduced ? 1.0 : _scaleAnimation.value,
                        child: child,
                      );
                    },
                    child: widget.badgeIcon ??
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD97706).withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: AppTypography.celebratory.copyWith(
                  color: const Color(0xFF0F172A),
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 6),

              // Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                ),
                child: Text(
                  widget.badgeName,
                  style: AppTypography.badgeLabel.copyWith(
                    color: const Color(0xFFB45309),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: const Color(0xFF64748B),
                ),
              ),

              // Animated Score / XP count
              if (widget.scoreEarned != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, color: Color(0xFF16A34A), size: 24),
                      const SizedBox(width: 6),
                      Text('+', style: AppTypography.titleLarge.copyWith(color: const Color(0xFF16A34A))),
                      AppAnimatedCounter(
                        value: widget.scoreEarned!,
                        suffix: widget.scoreSuffix,
                        style: AppTypography.titleLarge.copyWith(
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Dismiss Action Button
              App3DButton(
                text: widget.buttonLabel,
                onPressed: widget.onDismiss,
                variant: App3DButtonVariant.primary,
                height: 52.0,
                depth: 5.0,
                isFullWidth: true,
                borderRadius: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SunburstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFDE68A).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const rayCount = 12;
    const angleStep = (2 * math.pi) / rayCount;

    for (int i = 0; i < rayCount; i++) {
      final startAngle = i * angleStep;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          angleStep * 0.45,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
