import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/motion/motion.dart';

enum AnswerState {
  defaultState,
  selected,
  correct,
  incorrect,
  revealedCorrect,
  disabled,
}

/// A Duolingo-style interactive answer card for multiple choice, matching, and quiz activities.
///
/// Features physical 3D bottom-depth edge, translateY(4px) compression on tap down,
/// spring bounce-back upon release, and error shake/correct bounce animations.
class AppAnswerOptionCard extends StatefulWidget {
  final Widget? child;
  final String? text;
  final String? subtitle;
  final String? badgeText; // e.g. "A", "B", "1", "2"
  final AnswerState state;
  final VoidCallback? onTap;
  final double minHeight;
  final double depth;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const AppAnswerOptionCard({
    super.key,
    this.child,
    this.text,
    this.subtitle,
    this.badgeText,
    this.state = AnswerState.defaultState,
    this.onTap,
    this.minHeight = 60.0,
    this.depth = 4.0,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
  });

  @override
  State<AppAnswerOptionCard> createState() => _AppAnswerOptionCardState();
}

class _AppAnswerOptionCardState extends State<AppAnswerOptionCard>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _feedbackController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _scaleAnimation;

  static const Curve _duoSpring = Cubic(0.34, 1.56, 0.64, 1.0);

  DateTime? _tapDownTime;
  bool _isHandlingTap = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      value: 0.0,
      lowerBound: -0.15,
      upperBound: 1.0,
    );

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    // Scale bounce for correct answers (1.05x)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: _duoSpring)), weight: 60),
    ]).animate(_feedbackController);

    // Horizontal shake for wrong answers
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 20),
    ]).animate(_feedbackController);

    if (widget.state == AnswerState.incorrect || widget.state == AnswerState.correct) {
      _feedbackController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(AppAnswerOptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == AnswerState.incorrect && oldWidget.state != AnswerState.incorrect) {
      HapticFeedback.mediumImpact();
      _feedbackController.forward(from: 0.0);
    } else if (widget.state == AnswerState.correct && oldWidget.state != AnswerState.correct) {
      HapticFeedback.lightImpact();
      _feedbackController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.state == AnswerState.disabled || widget.onTap == null || _isHandlingTap) return;
    _tapDownTime = DateTime.now();
    HapticFeedback.selectionClick();
    _pressController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 65),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handleTap() async {
    if (widget.state == AnswerState.disabled || widget.onTap == null || _isHandlingTap) return;
    _isHandlingTap = true;

    try {
      final isReduced = AppMotion.isReducedMotion(context);
      if (!isReduced) {
        final downTime = _tapDownTime;
        if (downTime != null) {
          final elapsed = DateTime.now().difference(downTime).inMilliseconds;
          final waitMs = 85 - elapsed;
          if (waitMs > 0) {
            await Future.delayed(Duration(milliseconds: waitMs));
          }
        } else {
          await _pressController.animateTo(
            1.0,
            duration: const Duration(milliseconds: 65),
            curve: Curves.easeOutCubic,
          );
          await Future.delayed(const Duration(milliseconds: 30));
        }

        if (!mounted) return;

        _pressController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 140),
          curve: _duoSpring,
        );
        HapticFeedback.selectionClick();

        await Future.delayed(const Duration(milliseconds: 45));
      }

      if (mounted && widget.state != AnswerState.disabled) {
        widget.onTap?.call();
      }
    } finally {
      if (mounted) {
        _isHandlingTap = false;
        _tapDownTime = null;
      }
    }
  }

  void _handleTapCancel() {
    if (_isHandlingTap) return;
    _tapDownTime = null;
    if (_pressController.value > 0.0) {
      _pressController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  Color _getBackgroundColor() {
    switch (widget.state) {
      case AnswerState.defaultState:
        return Colors.white;
      case AnswerState.selected:
        return const Color(0xFFEFF6FF); // Light Sky Blue tint
      case AnswerState.correct:
      case AnswerState.revealedCorrect:
        return const Color(0xFFDCFCE7); // Light Emerald Green tint
      case AnswerState.incorrect:
        return const Color(0xFFFEE2E2); // Light Coral Red tint
      case AnswerState.disabled:
        return const Color(0xFFF8FAFC);
    }
  }

  Color _getBorderColor() {
    switch (widget.state) {
      case AnswerState.defaultState:
        return const Color(0xFFE2E8F0);
      case AnswerState.selected:
        return const Color(0xFF0EA5E9);
      case AnswerState.correct:
      case AnswerState.revealedCorrect:
        return const Color(0xFF22C55E);
      case AnswerState.incorrect:
        return const Color(0xFFEF4444);
      case AnswerState.disabled:
        return const Color(0xFFE2E8F0);
    }
  }

  Color _getBottomDepthColor() {
    switch (widget.state) {
      case AnswerState.defaultState:
        return const Color(0xFFCBD5E1);
      case AnswerState.selected:
        return const Color(0xFF0284C7);
      case AnswerState.correct:
      case AnswerState.revealedCorrect:
        return const Color(0xFF16A34A);
      case AnswerState.incorrect:
        return const Color(0xFFDC2626);
      case AnswerState.disabled:
        return const Color(0xFFE2E8F0);
    }
  }

  Color _getTextColor() {
    switch (widget.state) {
      case AnswerState.defaultState:
        return const Color(0xFF0F172A);
      case AnswerState.selected:
        return const Color(0xFF0369A1);
      case AnswerState.correct:
      case AnswerState.revealedCorrect:
        return const Color(0xFF15803D);
      case AnswerState.incorrect:
        return const Color(0xFFB91C1C);
      case AnswerState.disabled:
        return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReduced = AppMotion.isReducedMotion(context);
    final bgColor = _getBackgroundColor();
    final borderColor = _getBorderColor();
    final depthColor = _getBottomDepthColor();
    final textColor = _getTextColor();
    final isInteractive = widget.state != AnswerState.disabled && widget.onTap != null;
    final effectiveDepth = widget.state == AnswerState.disabled ? 1.5 : widget.depth;

    Widget innerContent = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Optional Leading Badge (A, B, C or Number)
        if (widget.badgeText != null) ...[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: widget.state == AnswerState.selected
                  ? const Color(0xFF0EA5E9)
                  : (widget.state == AnswerState.correct || widget.state == AnswerState.revealedCorrect
                      ? const Color(0xFF22C55E)
                      : (widget.state == AnswerState.incorrect
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF1F5F9))),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.state == AnswerState.defaultState ? const Color(0xFFCBD5E1) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                widget.badgeText!,
                style: AppTypography.baloo2(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: (widget.state == AnswerState.selected ||
                          widget.state == AnswerState.correct ||
                          widget.state == AnswerState.revealedCorrect ||
                          widget.state == AnswerState.incorrect)
                      ? Colors.white
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],

        // Main text / child content
        Expanded(
          child: widget.child ??
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.text != null)
                    Text(
                      widget.text!,
                      style: AppTypography.baloo2(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: AppTypography.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
        ),

        // State Trailing Icon Indicator
        if (widget.state == AnswerState.correct || widget.state == AnswerState.revealedCorrect)
          const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 24),
          )
        else if (widget.state == AnswerState.incorrect)
          const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 24),
          ),
      ],
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_pressController, _feedbackController]),
      builder: (context, child) {
        final pressProgress = isReduced ? 0.0 : _pressController.value.clamp(0.0, 1.0);
        final translateY = pressProgress * effectiveDepth;
        final pressScale = 1.0 - (0.015 * pressProgress);

        final Widget topSurface = Transform.translate(
          offset: Offset(0, translateY),
          child: Container(
            constraints: BoxConstraints(minHeight: widget.minHeight),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: borderColor,
                width: widget.state == AnswerState.defaultState ? 1.8 : 2.4,
              ),
            ),
            child: innerContent,
          ),
        );

        Widget cardBody = SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapCancel: _handleTapCancel,
            onTap: isInteractive ? _handleTap : null,
            behavior: HitTestBehavior.opaque,
            child: Transform.scale(
              scale: pressScale,
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(bottom: effectiveDepth),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Solid 3D Depth Layer
                    Positioned(
                      top: effectiveDepth,
                      left: 0,
                      right: 0,
                      bottom: -effectiveDepth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: depthColor,
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          boxShadow: (isInteractive && !isReduced)
                              ? [
                                  BoxShadow(
                                    color: depthColor.withValues(
                                      alpha: (0.32 * (1.0 - pressProgress.clamp(0.0, 1.0) * 0.5)).clamp(0.0, 1.0),
                                    ),
                                    offset: Offset(0, (2.2 - (1.8 * pressProgress.clamp(0.0, 1.0))).clamp(0.0, 4.0)),
                                    blurRadius: (3.0 - (2.0 * pressProgress.clamp(0.0, 1.0))).clamp(0.0, 6.0),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),

                    // Top Pressable Surface
                    topSurface,
                  ],
                ),
              ),
            ),
          ),
        );

        if (isReduced) {
          return cardBody;
        }

        if (widget.state == AnswerState.correct || widget.state == AnswerState.revealedCorrect) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.center,
            child: cardBody,
          );
        } else if (widget.state == AnswerState.incorrect) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: cardBody,
          );
        }

        return cardBody;
      },
    );
  }
}
