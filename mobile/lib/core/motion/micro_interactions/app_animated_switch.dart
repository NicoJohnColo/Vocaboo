import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../motion_tokens.dart';

/// A custom fluid switch widget with spring-driven thumb movement and tactile feedback.
class AppAnimatedSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;

  const AppAnimatedSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = const Color(0xFF0EA5E9),
    this.inactiveColor = const Color(0xFFE2E8F0),
    this.thumbColor = Colors.white,
  });

  void _handleTap() {
    HapticFeedback.selectionClick();
    onChanged(!value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: AppDurations.short,
        curve: AppCurves.emphasizedDecelerate,
        width: 52,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value ? activeColor : inactiveColor,
        ),
        child: AnimatedAlign(
          duration: AppDurations.short,
          curve: AppCurves.springBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: thumbColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A custom animated checkbox with scale pop and checkmark draw animation.
class AppAnimatedCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final double size;

  const AppAnimatedCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = const Color(0xFF0EA5E9),
    this.size = 24.0,
  });

  void _handleTap() {
    HapticFeedback.selectionClick();
    onChanged(!value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: AppDurations.micro,
        curve: AppCurves.springBack,
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: value ? activeColor : Colors.white,
          border: Border.all(
            color: value ? activeColor : const Color(0xFFCBD5E1),
            width: 2.0,
          ),
        ),
        child: AnimatedScale(
          scale: value ? 1.0 : 0.0,
          duration: AppDurations.micro,
          curve: AppCurves.springBack,
          child: const Icon(
            Icons.check_rounded,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
