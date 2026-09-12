import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/motion/motion.dart';

enum App3DButtonVariant {
  primary,
  secondary,
  success,
  danger,
  warning,
  dark,
}

enum App3DButtonFeedback {
  none,
  correct,
  wrong,
}

/// A tactile, chunky physical 3D button inspired by Duolingo's signature press animation.
///
/// Features:
/// - Solid 3D bottom-depth edge (4–6px deep) using a darker shade of the button color.
/// - Press-down translation (`translateY(depth)`) flattening the edge to 0 in ~90ms.
/// - Bouncy release with playful spring overshoot (`Cubic(0.34, 1.56, 0.64, 1.0)`).
/// - Flattened disabled state with desaturated colors.
/// - Full accessibility support (respects Reduce Motion).
class App3DButton extends StatefulWidget {
  final Widget? child;
  final String? text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final App3DButtonVariant variant;
  final double height;
  final double? width;
  final double depth;
  final double borderRadius;
  final bool isLoading;
  final bool isDisabled;
  final bool isFullWidth;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final Color? customBaseColor;
  final Color? customDepthColor;
  final Color? customTextColor;
  final Color? customBorderColor;
  final App3DButtonFeedback feedback;

  const App3DButton({
    super.key,
    this.child,
    this.text,
    this.icon,
    required this.onPressed,
    this.variant = App3DButtonVariant.primary,
    this.height = 52.0,
    this.width,
    this.depth = 4.5,
    this.borderRadius = 16.0,
    this.isLoading = false,
    this.isDisabled = false,
    this.isFullWidth = false,
    this.textStyle,
    this.padding,
    this.customBaseColor,
    this.customDepthColor,
    this.customTextColor,
    this.customBorderColor,
    this.feedback = App3DButtonFeedback.none,
  }) : assert(child != null || text != null, 'Either child or text must be provided');

  factory App3DButton.primary({
    Key? key,
    Widget? child,
    String? text,
    IconData? icon,
    required VoidCallback? onPressed,
    double height = 52.0,
    double? width,
    double depth = 4.5,
    double borderRadius = 16.0,
    bool isLoading = false,
    bool isDisabled = false,
    bool isFullWidth = false,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
  }) {
    return App3DButton(
      key: key,
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: App3DButtonVariant.primary,
      height: height,
      width: width,
      depth: depth,
      borderRadius: borderRadius,
      isLoading: isLoading,
      isDisabled: isDisabled,
      isFullWidth: isFullWidth,
      textStyle: textStyle,
      padding: padding,
      child: child,
    );
  }

  factory App3DButton.success({
    Key? key,
    Widget? child,
    String? text,
    IconData? icon,
    required VoidCallback? onPressed,
    double height = 52.0,
    double? width,
    double depth = 4.5,
    double borderRadius = 16.0,
    bool isLoading = false,
    bool isDisabled = false,
    bool isFullWidth = false,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
  }) {
    return App3DButton(
      key: key,
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: App3DButtonVariant.success,
      height: height,
      width: width,
      depth: depth,
      borderRadius: borderRadius,
      isLoading: isLoading,
      isDisabled: isDisabled,
      isFullWidth: isFullWidth,
      textStyle: textStyle,
      padding: padding,
      child: child,
    );
  }

  factory App3DButton.danger({
    Key? key,
    Widget? child,
    String? text,
    IconData? icon,
    required VoidCallback? onPressed,
    double height = 52.0,
    double? width,
    double depth = 4.5,
    double borderRadius = 16.0,
    bool isLoading = false,
    bool isDisabled = false,
    bool isFullWidth = false,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
  }) {
    return App3DButton(
      key: key,
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: App3DButtonVariant.danger,
      height: height,
      width: width,
      depth: depth,
      borderRadius: borderRadius,
      isLoading: isLoading,
      isDisabled: isDisabled,
      isFullWidth: isFullWidth,
      textStyle: textStyle,
      padding: padding,
      child: child,
    );
  }

  factory App3DButton.secondary({
    Key? key,
    Widget? child,
    String? text,
    IconData? icon,
    required VoidCallback? onPressed,
    double height = 52.0,
    double? width,
    double depth = 4.5,
    double borderRadius = 16.0,
    bool isLoading = false,
    bool isDisabled = false,
    bool isFullWidth = false,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
  }) {
    return App3DButton(
      key: key,
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: App3DButtonVariant.secondary,
      height: height,
      width: width,
      depth: depth,
      borderRadius: borderRadius,
      isLoading: isLoading,
      isDisabled: isDisabled,
      isFullWidth: isFullWidth,
      textStyle: textStyle,
      padding: padding,
      child: child,
    );
  }

  factory App3DButton.warning({
    Key? key,
    Widget? child,
    String? text,
    IconData? icon,
    required VoidCallback? onPressed,
    double height = 52.0,
    double? width,
    double depth = 4.5,
    double borderRadius = 16.0,
    bool isLoading = false,
    bool isDisabled = false,
    bool isFullWidth = false,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
  }) {
    return App3DButton(
      key: key,
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: App3DButtonVariant.warning,
      height: height,
      width: width,
      depth: depth,
      borderRadius: borderRadius,
      isLoading: isLoading,
      isDisabled: isDisabled,
      isFullWidth: isFullWidth,
      textStyle: textStyle,
      padding: padding,
      child: child,
    );
  }

  @override
  State<App3DButton> createState() => _App3DButtonState();
}

class _App3DButtonState extends State<App3DButton> with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _feedbackController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;

  // Duolingo's signature spring curve with playful overshoot
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
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0).chain(CurveTween(curve: _duoSpring)), weight: 60),
    ]).animate(_feedbackController);

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 20),
    ]).animate(_feedbackController);

    if (widget.feedback != App3DButtonFeedback.none) {
      _feedbackController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant App3DButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.feedback != oldWidget.feedback && widget.feedback != App3DButtonFeedback.none) {
      _feedbackController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null && !widget.isDisabled && !widget.isLoading;

  Color _getBaseColor() {
    if (widget.customBaseColor != null) return widget.customBaseColor!;
    switch (widget.variant) {
      case App3DButtonVariant.primary:
        return const Color(0xFF0EA5E9); // Vocaboo Sky Blue
      case App3DButtonVariant.secondary:
        return Colors.white;
      case App3DButtonVariant.success:
        return const Color(0xFF58CC02); // Duolingo Emerald Green (#58CC02 / #10B981)
      case App3DButtonVariant.danger:
        return const Color(0xFFEF4444); // Coral Red
      case App3DButtonVariant.warning:
        return const Color(0xFFF59E0B); // Amber Gold
      case App3DButtonVariant.dark:
        return const Color(0xFF0F172A); // Dark Slate
    }
  }

  Color _getDepthColor() {
    if (widget.customDepthColor != null) return widget.customDepthColor!;
    switch (widget.variant) {
      case App3DButtonVariant.primary:
        return const Color(0xFF0284C7); // Darker Blue
      case App3DButtonVariant.secondary:
        return const Color(0xFFCBD5E1); // Darker Gray Edge
      case App3DButtonVariant.success:
        return const Color(0xFF46A302); // Darker Green Edge
      case App3DButtonVariant.danger:
        return const Color(0xFFDC2626); // Darker Red
      case App3DButtonVariant.warning:
        return const Color(0xFFD97706); // Darker Gold
      case App3DButtonVariant.dark:
        return const Color(0xFF020617); // Deepest Black
    }
  }

  Color _getTextColor() {
    if (widget.customTextColor != null) return widget.customTextColor!;
    if (widget.variant == App3DButtonVariant.secondary) {
      return const Color(0xFF0EA5E9);
    }
    return Colors.white;
  }

  Color _getBorderColor() {
    if (widget.customBorderColor != null) return widget.customBorderColor!;
    if (widget.variant == App3DButtonVariant.secondary) {
      return const Color(0xFFE2E8F0);
    }
    return Colors.transparent;
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
          // Direct tap without tapDown (e.g. accessibility / programmatic tap)
          await _pressController.animateTo(
            1.0,
            duration: const Duration(milliseconds: 65),
            curve: Curves.easeOutCubic,
          );
          await Future.delayed(const Duration(milliseconds: 30));
        }

        if (!mounted) return;

        // Trigger spring release bounce
        _pressController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 140),
          curve: _duoSpring,
        );
        HapticFeedback.selectionClick();

        // Brief delay (50ms) so the snappy spring return is visible before potential navigation/unmount
        await Future.delayed(const Duration(milliseconds: 50));
      }

      if (mounted && _enabled) {
        widget.onPressed?.call();
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
    final baseColor = _enabled ? _getBaseColor() : const Color(0xFFE2E8F0);
    final depthColor = _enabled ? _getDepthColor() : const Color(0xFFCBD5E1);
    final textColor = _enabled ? _getTextColor() : const Color(0xFF94A3B8);
    final borderColor = _enabled ? _getBorderColor() : const Color(0xFFE2E8F0);
    final effectiveDepth = _enabled ? widget.depth : 2.0;

    Widget buttonContent;
    if (widget.isLoading) {
      buttonContent = SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          color: textColor,
          strokeWidth: 2.5,
        ),
      );
    } else if (widget.child != null) {
      buttonContent = widget.child!;
    } else {
      final style = widget.textStyle ??
          AppTypography.baloo2(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          );

      if (widget.icon != null) {
        buttonContent = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(widget.icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(widget.text!, style: style),
          ],
        );
      } else {
        buttonContent = Text(widget.text!, style: style, textAlign: TextAlign.center);
      }
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_pressController, _feedbackController]),
      builder: (context, child) {
        final pressProgress = isReduced ? 0.0 : _pressController.value;
        final translateY = pressProgress * effectiveDepth;
        // Subtle scale compression: 1.0 down to ~0.985 at full press
        final pressScale = 1.0 - (0.016 * pressProgress);

        final Widget topSurface = Transform.translate(
          offset: Offset(0, translateY),
          child: Container(
            height: widget.height,
            padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: borderColor,
                width: widget.variant == App3DButtonVariant.secondary ? 2.0 : 1.0,
              ),
              gradient: (widget.variant != App3DButtonVariant.secondary && _enabled)
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.lerp(baseColor, Colors.white, 0.08)!,
                        baseColor,
                      ],
                    )
                  : null,
            ),
            child: buttonContent,
          ),
        );

        final Widget buttonCore = SizedBox(
          width: widget.isFullWidth ? double.infinity : widget.width,
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
                    // Solid 3D Depth Layer (bottom block)
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
                                      alpha: (0.35 * (1.0 - pressProgress.clamp(0.0, 1.0) * 0.5)).clamp(0.0, 1.0),
                                    ),
                                    offset: Offset(0, (2.5 - (2.0 * pressProgress.clamp(0.0, 1.0))).clamp(0.0, 4.0)),
                                    blurRadius: (3.5 - (2.5 * pressProgress.clamp(0.0, 1.0))).clamp(0.0, 6.0),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),

                    // Top Pressable Surface Layer
                    topSurface,
                  ],
                ),
              ),
            ),
          ),
        );

        if (isReduced || widget.feedback == App3DButtonFeedback.none) {
          return buttonCore;
        }

        if (widget.feedback == App3DButtonFeedback.correct) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.center,
            child: buttonCore,
          );
        } else if (widget.feedback == App3DButtonFeedback.wrong) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: buttonCore,
          );
        }

        return buttonCore;
      },
    );
  }
}
