import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/motion/motion.dart';

enum App3DChoiceState {
  idle,
  selected,
  correct,
  wrong,
  disabled,
  placedSlot,
}

/// A tactile, chunky 3D choice tile / quiz option card inspired by Duolingo.
///
/// Features:
/// - Chunky 3D bottom edge (3.5–4.5px deep).
/// - Instant press-down response (`translateY(depth)`).
/// - Playful spring bounce-back on release (`Cubic(0.34, 1.56, 0.64, 1.0)`).
/// - State-driven color theming (idle, selected, correct green bounce, wrong red shake).
/// - Support for option index badges (e.g. 1, 2, 3 or A, B, C), icons, and subtitles.
class App3DChoiceTile extends StatefulWidget {
  final String text;
  final String? subtitle;
  final String? badgeText;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final App3DChoiceState state;
  final double depth;
  final double borderRadius;
  final double? minHeight;
  final EdgeInsetsGeometry padding;
  final bool isFullWidth;

  const App3DChoiceTile({
    super.key,
    required this.text,
    this.subtitle,
    this.badgeText,
    this.icon,
    this.leading,
    this.trailing,
    required this.onTap,
    this.state = App3DChoiceState.idle,
    this.depth = 4.0,
    this.borderRadius = 16.0,
    this.minHeight = 56.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.isFullWidth = true,
  });

  @override
  State<App3DChoiceTile> createState() => _App3DChoiceTileState();
}

class _App3DChoiceTileState extends State<App3DChoiceTile> with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _feedbackController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;

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

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: _duoSpring)), weight: 60),
    ]).animate(_feedbackController);

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 20),
    ]).animate(_feedbackController);

    if (widget.state == App3DChoiceState.correct || widget.state == App3DChoiceState.wrong) {
      _feedbackController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant App3DChoiceTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      if (widget.state == App3DChoiceState.correct || widget.state == App3DChoiceState.wrong) {
        _feedbackController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  bool get _enabled =>
      widget.onTap != null &&
      widget.state != App3DChoiceState.disabled &&
      widget.state != App3DChoiceState.placedSlot;

  Color _getBaseColor() {
    switch (widget.state) {
      case App3DChoiceState.idle:
        return Colors.white;
      case App3DChoiceState.selected:
        return const Color(0xFFEFF6FF); // Light blue
      case App3DChoiceState.correct:
        return const Color(0xFFDCFCE7); // Light emerald
      case App3DChoiceState.wrong:
        return const Color(0xFFFEE2E2); // Light red
      case App3DChoiceState.disabled:
        return const Color(0xFFF8FAFC);
      case App3DChoiceState.placedSlot:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _getDepthColor() {
    switch (widget.state) {
      case App3DChoiceState.idle:
        return const Color(0xFFCBD5E1); // Neutral gray 3D edge
      case App3DChoiceState.selected:
        return const Color(0xFF0284C7); // Deep blue 3D edge
      case App3DChoiceState.correct:
        return const Color(0xFF16A34A); // Deep green 3D edge
      case App3DChoiceState.wrong:
        return const Color(0xFFDC2626); // Deep red 3D edge
      case App3DChoiceState.disabled:
      case App3DChoiceState.placedSlot:
        return const Color(0xFFE2E8F0);
    }
  }

  Color _getBorderColor() {
    switch (widget.state) {
      case App3DChoiceState.idle:
        return const Color(0xFFE2E8F0);
      case App3DChoiceState.selected:
        return const Color(0xFF0EA5E9);
      case App3DChoiceState.correct:
        return const Color(0xFF22C55E);
      case App3DChoiceState.wrong:
        return const Color(0xFFEF4444);
      case App3DChoiceState.disabled:
        return const Color(0xFFE2E8F0);
      case App3DChoiceState.placedSlot:
        return const Color(0xFFCBD5E1);
    }
  }

  Color _getTextColor() {
    switch (widget.state) {
      case App3DChoiceState.idle:
        return const Color(0xFF0F172A);
      case App3DChoiceState.selected:
        return const Color(0xFF0369A1);
      case App3DChoiceState.correct:
        return const Color(0xFF15803D);
      case App3DChoiceState.wrong:
        return const Color(0xFFB91C1C);
      case App3DChoiceState.disabled:
      case App3DChoiceState.placedSlot:
        return const Color(0xFF94A3B8);
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_enabled || _isHandlingTap) return;
    _tapDownTime = DateTime.now();
    HapticFeedback.lightImpact();
    _pressController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 65),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handleTap() async {
    if (!_enabled || _isHandlingTap) return;
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

      if (mounted && _enabled) {
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

  @override
  Widget build(BuildContext context) {
    final isReduced = AppMotion.isReducedMotion(context);
    final baseColor = _getBaseColor();
    final depthColor = _getDepthColor();
    final borderColor = _getBorderColor();
    final textColor = _getTextColor();
    final effectiveDepth = (widget.state == App3DChoiceState.placedSlot || widget.state == App3DChoiceState.disabled)
        ? 1.5
        : widget.depth;

    final content = Row(
      children: [
        if (widget.badgeText != null) ...[
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.state == App3DChoiceState.selected
                  ? const Color(0xFF0EA5E9)
                  : (widget.state == App3DChoiceState.correct
                      ? const Color(0xFF22C55E)
                      : (widget.state == App3DChoiceState.wrong
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF1F5F9))),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.state == App3DChoiceState.idle ? const Color(0xFFE2E8F0) : Colors.transparent,
              ),
            ),
            child: Text(
              widget.badgeText!,
              style: AppTypography.baloo2(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: widget.state == App3DChoiceState.idle ? const Color(0xFF64748B) : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ] else if (widget.leading != null) ...[
          widget.leading!,
          const SizedBox(width: 12),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, color: textColor, size: 22),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.text,
                style: AppTypography.baloo2(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 3),
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
        if (widget.trailing != null) ...[
          const SizedBox(width: 8),
          widget.trailing!,
        ] else if (widget.state == App3DChoiceState.correct) ...[
          const SizedBox(width: 8),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 22),
        ] else if (widget.state == App3DChoiceState.wrong) ...[
          const SizedBox(width: 8),
          const Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 22),
        ],
      ],
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_pressController, _feedbackController]),
      builder: (context, child) {
        final pressProgress = isReduced ? 0.0 : _pressController.value;
        final translateY = pressProgress * effectiveDepth;
        final pressScale = 1.0 - (0.015 * pressProgress);

        final Widget topSurface = Transform.translate(
          offset: Offset(0, translateY),
          child: Container(
            constraints: BoxConstraints(minHeight: widget.minHeight ?? 0),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: borderColor,
                width: (widget.state == App3DChoiceState.selected ||
                        widget.state == App3DChoiceState.correct ||
                        widget.state == App3DChoiceState.wrong)
                    ? 2.2
                    : 1.5,
              ),
            ),
            child: content,
          ),
        );

        Widget tileCore = SizedBox(
          width: widget.isFullWidth ? double.infinity : null,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapCancel: _handleTapCancel,
            onTap: _enabled ? _handleTap : null,
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
                    Positioned.fill(
                      top: effectiveDepth,
                      bottom: -effectiveDepth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: depthColor,
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          boxShadow: (_enabled && !isReduced)
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
          return tileCore;
        }

        if (widget.state == App3DChoiceState.correct) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.center,
            child: tileCore,
          );
        } else if (widget.state == App3DChoiceState.wrong) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: tileCore,
          );
        }

        return tileCore;
      },
    );
  }
}
