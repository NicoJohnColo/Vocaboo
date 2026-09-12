import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/motion/typography_tokens.dart';

/// Duolingo-style dynamic 3D progress bar.
///
/// Features:
/// - Rounded pill track (border-radius: 12px, height ~22px), light gray background (#E5E7EB).
/// - Inner fill bar in yellow (#FFC800) with bottom depth shadow (#E6B400) and top gloss reflection strip.
/// - Legible dark gold text (#5C4600) on yellow surfaces.
/// - Smooth springy overshoot animation: 400ms using `Cubic(0.34, 1.56, 0.64, 1.0)`.
/// - Brightness pulse (`brightness(1.3)`, ~500ms) on forward progress / correct answers.
/// - Mastery glow (`brightness(1.4)`, ~700ms) at 100%.
/// - Accessibility: Screen reader semantics with value, min (0%), max (100%).
class App3DProgressBar extends StatefulWidget {
  /// Progress value between 0.0 and 1.0 (or 0 to 100).
  final double value;

  /// Height of the track (defaults to 22.0px).
  final double height;

  /// Border radius of the pill track (defaults to 12.0px).
  final double borderRadius;

  /// Primary fill color (defaults to #FFC800).
  final Color fillColor;

  /// Bottom 3D shadow/depth color (defaults to #E6B400).
  final Color depthColor;

  /// Track background color (defaults to #E5E7EB).
  final Color trackColor;

  /// Contrast label text color (defaults to #5C4600).
  final Color textColor;

  /// Whether to display the text label inside/alongside the bar.
  final bool showLabel;

  /// Custom label text override (e.g. "8/10", "80%"). If null, shows "$percentage%".
  final String? customLabel;

  /// Whether to trigger a brightness pulse animation (e.g. upon a correct answer).
  final bool pulseOnIncrease;

  const App3DProgressBar({
    super.key,
    required this.value,
    this.height = 22.0,
    this.borderRadius = 12.0,
    this.fillColor = const Color(0xFFFFC800),
    this.depthColor = const Color(0xFFE6B400),
    this.trackColor = const Color(0xFFE5E7EB),
    this.textColor = const Color(0xFF5C4600),
    this.showLabel = false,
    this.customLabel,
    this.pulseOnIncrease = true,
  });

  @override
  State<App3DProgressBar> createState() => _App3DProgressBarState();
}

class _App3DProgressBarState extends State<App3DProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _brightnessAnimation;
  late Animation<double> _glowAnimation;
  double _lastValue = 0.0;

  static const Cubic _springCurve = Cubic(0.34, 1.56, 0.64, 1.0);

  @override
  void initState() {
    super.initState();
    _lastValue = _normalize(widget.value);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _brightnessAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_pulseController);

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_pulseController);

    if (_lastValue >= 1.0) {
      _triggerMasteryGlow();
    }
  }

  @override
  void didUpdateWidget(covariant App3DProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentVal = _normalize(widget.value);
    final prevVal = _normalize(oldWidget.value);

    if (currentVal > prevVal && widget.pulseOnIncrease) {
      if (currentVal >= 1.0) {
        _triggerMasteryGlow();
      } else {
        _triggerPulse();
      }
    }
    _lastValue = currentVal;
  }

  double _normalize(double val) {
    if (val > 1.0) {
      return (val / 100.0).clamp(0.0, 1.0);
    }
    return val.clamp(0.0, 1.0);
  }

  void _triggerPulse() {
    _pulseController.duration = const Duration(milliseconds: 500);
    _pulseController.forward(from: 0.0);
  }

  void _triggerMasteryGlow() {
    _pulseController.duration = const Duration(milliseconds: 700);
    _pulseController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalized = _normalize(widget.value);
    final percentInt = (normalized * 100).round();
    final labelText = widget.customLabel ?? '$percentInt%';

    return Semantics(
      label: 'Lesson progress',
      value: '$percentInt percent',
      minValue: '0',
      maxValue: '100',
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final brightness = _brightnessAnimation.value;
          final glowOpacity = _glowAnimation.value;

          return Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.trackColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: const Color(0xFFCBD5E1),
                width: 1.5,
              ),
              boxShadow: [
                if (glowOpacity > 0.01)
                  BoxShadow(
                    color: widget.fillColor.withValues(alpha: 0.6 * glowOpacity),
                    blurRadius: 14 * glowOpacity,
                    spreadRadius: 2 * glowOpacity,
                  ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius - 1.5),
              child: Stack(
                children: [
                  // Track background inset gloss
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.trackColor,
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                      ),
                    ),
                  ),

                  // Animated Fill Bar
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: _lastValue, end: normalized),
                    duration: const Duration(milliseconds: 400),
                    curve: _springCurve,
                    builder: (context, animValue, _) {
                      final fillPercent = animValue.clamp(0.0, 1.0);

                      if (fillPercent <= 0.001) {
                        return const SizedBox.shrink();
                      }

                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: fillPercent,
                        child: ColorFiltered(
                          colorFilter: ColorFilter.matrix([
                            brightness, 0, 0, 0, 0,
                            0, brightness, 0, 0, 0,
                            0, 0, brightness, 0, 0,
                            0, 0, 0, 1, 0,
                          ]),
                          child: Container(
                            decoration: BoxDecoration(
                              color: widget.fillColor,
                              borderRadius: BorderRadius.circular(widget.borderRadius),
                              boxShadow: [
                                // Bottom 3D solid depth edge
                                BoxShadow(
                                  color: widget.depthColor,
                                  offset: const Offset(0, 2.5),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Top gloss reflection highlight
                                Positioned(
                                  top: 2,
                                  left: 6,
                                  right: 6,
                                  height: math.max(3.0, widget.height * 0.18),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),

                                // Bottom edge shadow strip
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  height: 3,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: widget.depthColor,
                                      borderRadius: BorderRadius.vertical(
                                        bottom: Radius.circular(widget.borderRadius),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Center contrast label if enabled
                  if (widget.showLabel)
                    Positioned.fill(
                      child: Center(
                        child: Text(
                          labelText,
                          style: AppTypography.baloo2(
                            fontSize: math.min(13.0, widget.height * 0.62),
                            fontWeight: FontWeight.w800,
                            color: widget.textColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
