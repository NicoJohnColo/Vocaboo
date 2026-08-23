import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../motion_tokens.dart';
import '../typography_tokens.dart';

/// Reusable Answer Feedback Banner for young learners (ages 9-12).
///
/// Designed to follow the app's motion personality:
/// - [isCorrect == true]: Mild celebratory spring-overshoot banner with sparkling star
///   burst, rewarding iconography, and encouraging copy without stalling progress.
/// - [isCorrect == false]: Gentle, non-punishing horizontal soft nudge, warm pastel
///   background (no harsh red flashes), encouraging the learner to keep going.
class AppAnswerFeedback extends StatefulWidget {
  final bool isCorrect;
  final String? title;
  final String? subtitle;
  final VoidCallback? onContinue;
  final String continueLabel;

  const AppAnswerFeedback({
    super.key,
    required this.isCorrect,
    this.title,
    this.subtitle,
    this.onContinue,
    this.continueLabel = 'CONTINUE',
  });

  @override
  State<AppAnswerFeedback> createState() => _AppAnswerFeedbackState();
}

class _AppAnswerFeedbackState extends State<AppAnswerFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.celebratory,
    );

    // Spring overshoot for correct answers
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: AppCurves.celebratory),
      ),
    );

    // Gentle soft nudge (shake) for incorrect answers (3 gentle waves)
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    // Sparkle rotation and expand
    _sparkleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.9, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReduced = AppMotion.isReducedMotion(context);

    // Colorblind-safe palette & iconography
    final primaryColor = widget.isCorrect ? const Color(0xFF16A34A) : const Color(0xFFD97706);
    final bgColor = widget.isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB);
    final borderColor = widget.isCorrect ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A);
    final defaultTitle = widget.isCorrect ? 'Awesome job! 🎉' : 'Keep going! 🌟';
    final iconData = widget.isCorrect ? Icons.check_circle_rounded : Icons.lightbulb_rounded;

    Widget content = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: borderColor, width: 2)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animated Badge Icon / Sparkle
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (widget.isCorrect && !isReduced)
                      AnimatedBuilder(
                        animation: _sparkleAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _sparkleAnimation.value * math.pi * 0.5,
                            child: Transform.scale(
                              scale: _sparkleAnimation.value * 1.3,
                              child: Icon(
                                Icons.star_rounded,
                                size: 42,
                                color: const Color(0xFFFACC15).withValues(alpha: 0.4),
                              ),
                            ),
                          );
                        },
                      ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(iconData, color: Colors.white, size: 26),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title ?? defaultTitle,
                        style: AppTypography.titleLarge.copyWith(
                          color: primaryColor,
                          fontSize: 20,
                        ),
                      ),
                      if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: const Color(0xFF475569),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.onContinue != null)
              ElevatedButton(
                onPressed: widget.onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  textStyle: AppTypography.button.copyWith(fontSize: 16),
                ),
                child: Text(widget.continueLabel),
              ),
          ],
        ),
      ),
    );

    if (isReduced) {
      return content;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (widget.isCorrect) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.bottomCenter,
            child: child,
          );
        } else {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          );
        }
      },
      child: content,
    );
  }
}
