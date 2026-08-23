import 'package:flutter/material.dart';
import '../motion_tokens.dart';

enum AppButtonState { idle, loading, success, disabled }

/// An interactive button that smoothly morphs its width and content into an
/// inline circular progress indicator or success checkmark without layout jumps.
class AppInlineLoadingButton extends StatefulWidget {
  final String text;
  final Future<void> Function()? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final double width;
  final double borderRadius;
  final bool isFullWidth;

  const AppInlineLoadingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor = const Color(0xFF0EA5E9),
    this.textColor = Colors.white,
    this.height = 54.0,
    this.width = 240.0,
    this.borderRadius = 16.0,
    this.isFullWidth = true,
  });

  @override
  State<AppInlineLoadingButton> createState() => _AppInlineLoadingButtonState();
}

class _AppInlineLoadingButtonState extends State<AppInlineLoadingButton>
    with SingleTickerProviderStateMixin {
  AppButtonState _state = AppButtonState.idle;
  bool _isPressed = false;

  Future<void> _handlePress() async {
    if (_state != AppButtonState.idle || widget.onPressed == null) return;

    setState(() => _state = AppButtonState.loading);

    try {
      await widget.onPressed!();
      if (mounted) {
        setState(() => _state = AppButtonState.success);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          setState(() => _state = AppButtonState.idle);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _state = AppButtonState.idle);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isActionDisabled = widget.onPressed == null || _state == AppButtonState.disabled;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : widget.width;

        final double targetWidth = (_state == AppButtonState.loading || _state == AppButtonState.success)
            ? widget.height
            : (widget.isFullWidth ? maxWidth : widget.width);

        return RepaintBoundary(
          child: Center(
            child: GestureDetector(
              onTapDown: isActionDisabled ? null : (_) => setState(() => _isPressed = true),
              onTapUp: isActionDisabled ? null : (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: isActionDisabled ? null : _handlePress,
              child: AnimatedScale(
                scale: _isPressed ? 0.96 : 1.0,
                duration: AppDurations.micro,
                curve: AppCurves.springBack,
                child: AnimatedContainer(
                  duration: AppDurations.standard,
                  curve: AppCurves.emphasizedDecelerate,
                  height: widget.height,
                  width: targetWidth,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActionDisabled
                        ? const Color(0xFFCBD5E1)
                        : (_state == AppButtonState.success
                            ? const Color(0xFF10B981) // Emerald for success
                            : widget.backgroundColor),
                    borderRadius: BorderRadius.circular(
                      (_state == AppButtonState.loading || _state == AppButtonState.success)
                          ? widget.height / 2
                          : widget.borderRadius,
                    ),
                    boxShadow: isActionDisabled
                        ? null
                        : [
                            BoxShadow(
                              color: widget.backgroundColor.withValues(alpha: _isPressed ? 0.15 : 0.28),
                              blurRadius: _isPressed ? 8 : 16,
                              offset: Offset(0, _isPressed ? 3 : 6),
                            ),
                          ],
                  ),
                  child: AnimatedSwitcher(
                    duration: AppDurations.short,
                    switchInCurve: AppCurves.emphasizedDecelerate,
                    switchOutCurve: AppCurves.emphasizedAccelerate,
                    child: _buildButtonChild(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtonChild() {
    switch (_state) {
      case AppButtonState.loading:
        return const SizedBox(
          key: ValueKey('loading'),
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.8,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );

      case AppButtonState.success:
        return const Icon(
          Icons.check_rounded,
          key: ValueKey('success'),
          color: Colors.white,
          size: 28,
        );

      case AppButtonState.idle:
      case AppButtonState.disabled:
        return Row(
          key: const ValueKey('idle'),
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: widget.textColor, size: 20),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                widget.text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.textColor,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
    }
  }
}
