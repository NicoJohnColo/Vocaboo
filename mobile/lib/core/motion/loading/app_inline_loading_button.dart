import 'package:flutter/material.dart';
import '../motion_tokens.dart';
import '../typography_tokens.dart';

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

  Color _getDepthColor(Color base) {
    if (base == const Color(0xFF0EA5E9)) return const Color(0xFF0284C7);
    if (base == const Color(0xFF10B981) || base == const Color(0xFF58CC02)) return const Color(0xFF059669);
    if (base == const Color(0xFFEF4444)) return const Color(0xFFDC2626);
    if (base == const Color(0xFFF59E0B)) return const Color(0xFFD97706);
    return HSLColor.fromColor(base).withLightness((HSLColor.fromColor(base).lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final bool isActionDisabled = widget.onPressed == null || _state == AppButtonState.disabled;
    const double depth = 4.5;
    final double effectiveDepth = isActionDisabled ? 2.0 : depth;
    final double translateY = (_isPressed && !isActionDisabled) ? depth : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : widget.width;

        final double targetWidth = (_state == AppButtonState.loading || _state == AppButtonState.success)
            ? widget.height
            : (widget.isFullWidth ? maxWidth : widget.width);

        final Color baseColor = isActionDisabled
            ? const Color(0xFFCBD5E1)
            : (_state == AppButtonState.success
                ? const Color(0xFF10B981)
                : widget.backgroundColor);

        final Color depthColor = isActionDisabled
            ? const Color(0xFF94A3B8)
            : (_state == AppButtonState.success
                ? const Color(0xFF059669)
                : _getDepthColor(widget.backgroundColor));

        final double borderRadius = (_state == AppButtonState.loading || _state == AppButtonState.success)
            ? widget.height / 2
            : widget.borderRadius;

        return RepaintBoundary(
          child: Center(
            child: SizedBox(
              width: targetWidth,
              height: widget.height + effectiveDepth,
              child: GestureDetector(
                onTapDown: isActionDisabled ? null : (_) => setState(() => _isPressed = true),
                onTapUp: isActionDisabled ? null : (_) => setState(() => _isPressed = false),
                onTapCancel: () => setState(() => _isPressed = false),
                onTap: isActionDisabled ? null : _handlePress,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Solid 3D Bottom Depth Layer
                    Positioned(
                      top: effectiveDepth,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: widget.height,
                        decoration: BoxDecoration(
                          color: depthColor,
                          borderRadius: BorderRadius.circular(borderRadius),
                        ),
                      ),
                    ),

                    // Top Pressable Surface Layer
                    AnimatedPositioned(
                      duration: Duration(milliseconds: _isPressed ? 90 : 160),
                      curve: _isPressed ? Curves.easeOut : const Cubic(0.34, 1.56, 0.64, 1.0),
                      top: translateY,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: widget.height,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(borderRadius),
                        ),
                        child: AnimatedSwitcher(
                          duration: AppDurations.short,
                          switchInCurve: AppCurves.emphasizedDecelerate,
                          switchOutCurve: AppCurves.emphasizedAccelerate,
                          child: _buildButtonChild(),
                        ),
                      ),
                    ),
                  ],
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
                style: AppTypography.baloo2(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
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
