import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../motion_tokens.dart';

/// A universal tactile press feedback wrapper.
///
/// Shrinks slightly (0.96x) on pointer down with subtle opacity, and springs
/// back with [AppCurves.springBack] on release. Does not trigger unnecessary layout rebuilds.
class AppPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final double pressedOpacity;
  final Duration duration;
  final bool enableHaptic;
  final HitTestBehavior behavior;

  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.pressedOpacity = 0.92,
    this.duration = AppDurations.micro,
    this.enableHaptic = true,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    if (widget.enableHaptic) {
      HapticFeedback.selectionClick();
    }
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = widget.onTap != null || widget.onLongPress != null;

    if (!isInteractive || AppMotion.isReducedMotion(context)) {
      return GestureDetector(
        behavior: widget.behavior,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: widget.child,
      );
    }

    return RepaintBoundary(
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _isPressed ? widget.pressedScale : 1.0,
          duration: widget.duration,
          curve: _isPressed ? Curves.easeOut : AppCurves.springBack,
          child: AnimatedOpacity(
            opacity: _isPressed ? widget.pressedOpacity : 1.0,
            duration: widget.duration,
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
