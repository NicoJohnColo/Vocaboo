import 'package:flutter/material.dart';
import '../motion_tokens.dart';
import '../typography_tokens.dart';

/// Smooth, rounded animated progress bar for young learners (ages 9-12).
///
/// Animates progress value changes using [AppCurves.emphasizedDecelerate] with
/// optional glowing leading edge and text percentage label.
class AppAnimatedProgressBar extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color? trackColor;
  final Color? progressColor;
  final Gradient? progressGradient;
  final Duration? duration;
  final bool showLabel;
  final BorderRadius? borderRadius;

  const AppAnimatedProgressBar({
    super.key,
    required this.progress,
    this.height = 12,
    this.trackColor,
    this.progressColor,
    this.progressGradient,
    this.duration,
    this.showLabel = false,
    this.borderRadius,
  });

  @override
  State<AppAnimatedProgressBar> createState() => _AppAnimatedProgressBarState();
}

class _AppAnimatedProgressBarState extends State<AppAnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _oldProgress = widget.progress.clamp(0.0, 1.0);
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? AppDurations.emphasized,
    );
    _animation = Tween<double>(begin: _oldProgress, end: _oldProgress).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppCurves.emphasizedDecelerate,
      ),
    );
  }

  @override
  void didUpdateWidget(AppAnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      if (AppMotion.isReducedMotion(context)) {
        _oldProgress = widget.progress.clamp(0.0, 1.0);
        return;
      }
      _oldProgress = _animation.value;
      _controller.duration = widget.duration ?? AppDurations.emphasized;
      _animation = Tween<double>(
        begin: _oldProgress,
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: AppCurves.emphasizedDecelerate,
        ),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(widget.height / 2);
    final isReduced = AppMotion.isReducedMotion(context);
    final effectiveProgress = isReduced ? widget.progress.clamp(0.0, 1.0) : _animation.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showLabel) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progress', style: AppTypography.caption),
                Text(
                  '${(widget.progress * 100).round()}%',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.trackColor ?? const Color(0xFFE2E8F0),
            borderRadius: radius,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              if (isReduced) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: maxWidth * effectiveProgress,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: widget.progressColor ?? const Color(0xFF10B981),
                      gradient: widget.progressGradient ??
                          const LinearGradient(
                            colors: [Color(0xFF34D399), Color(0xFF10B981)],
                          ),
                      borderRadius: radius,
                    ),
                  ),
                );
              }

              return AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final currentWidth = maxWidth * _animation.value;
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: currentWidth,
                      height: widget.height,
                      decoration: BoxDecoration(
                        color: widget.progressColor ?? const Color(0xFF10B981),
                        gradient: widget.progressGradient ??
                            const LinearGradient(
                              colors: [Color(0xFF34D399), Color(0xFF10B981)],
                            ),
                        borderRadius: radius,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
