import 'package:flutter/material.dart';
import '../core/motion/typography_tokens.dart';
import 'app_reward_badge_celebration.dart';

/// Tactile 3D Duolingo-style Badge Pill & Badge Disc for Profile, Sheets, and Scoreboards.
class App3DBadgePill extends StatelessWidget {
  final AppBadgeTier tier;
  final int count;
  final String? customLabel;
  final VoidCallback? onTap;

  const App3DBadgePill({
    super.key,
    required this.tier,
    required this.count,
    this.customLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = customLabel ?? (tier == AppBadgeTier.gold ? 'GOLD' : tier == AppBadgeTier.silver ? 'SILVER' : 'BRONZE');

    Color bgColor;
    Color borderColor;
    Color textColor;
    Color depthColor;

    switch (tier) {
      case AppBadgeTier.gold:
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFDE047);
        textColor = const Color(0xFFB45309);
        depthColor = const Color(0xFFF59E0B);
        break;
      case AppBadgeTier.silver:
        bgColor = const Color(0xFFF8FAFC);
        borderColor = const Color(0xFFCBD5E1);
        textColor = const Color(0xFF475569);
        depthColor = const Color(0xFF94A3B8);
        break;
      case AppBadgeTier.bronze:
        bgColor = const Color(0xFFFFF7ED);
        borderColor = const Color(0xFFFED7AA);
        textColor = const Color(0xFF92400E);
        depthColor = const Color(0xFFD97706);
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: depthColor.withValues(alpha: 0.35),
              offset: const Offset(0, 2.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 3D Mini Badge Disc
            App3DMiniBadgeDisc(tier: tier, size: 22),
            const SizedBox(width: 8),
            Text(
              '$count × $label',
              style: AppTypography.baloo2(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A mini 3D circular medal disc with radial gradient, bevel, and highlight.
class App3DMiniBadgeDisc extends StatelessWidget {
  final AppBadgeTier tier;
  final double size;

  const App3DMiniBadgeDisc({
    super.key,
    required this.tier,
    this.size = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = tier.gradientColors;
    final depthColor = tier.primaryColor;

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
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: depthColor.withValues(alpha: 0.4),
            offset: const Offset(0, 2),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.emoji_events_rounded,
          size: size * 0.55,
          color: Colors.white,
          shadows: const [
            Shadow(
              color: Colors.black26,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
