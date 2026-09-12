import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/motion/motion.dart';

enum AppCardStatus {
  normal,
  selected,
  completed,
  locked,
  incorrect,
}

/// A Duolingo-inspired tactile game card with 20–24px rounded corners,
/// die-cut sticker borders (1.5–2px), functional elevation, and spring tap feedback.
class AppGameCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final AppCardStatus status;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final int? starCount; // 0 to 3 stars for completed state
  final bool enableHaptic;

  const AppGameCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.status = AppCardStatus.normal,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 22.0,
    this.padding = const EdgeInsets.all(18.0),
    this.margin,
    this.width,
    this.height,
    this.starCount,
    this.enableHaptic = true,
  });

  @override
  State<AppGameCard> createState() => _AppGameCardState();
}

class _AppGameCardState extends State<AppGameCard> {
  bool _isPressed = false;

  bool get _isInteractive =>
      widget.status != AppCardStatus.locked &&
      (widget.onTap != null || widget.onLongPress != null);

  void _handleTapDown(TapDownDetails details) {
    if (!_isInteractive) return;
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

  Color _getBackgroundColor() {
    if (widget.status == AppCardStatus.locked) {
      return const Color(0xFFF1F5F9);
    }
    if (widget.status == AppCardStatus.selected) {
      return const Color(0xFFF0F9FF);
    }
    if (widget.status == AppCardStatus.completed) {
      return widget.backgroundColor ?? Colors.white;
    }
    if (widget.status == AppCardStatus.incorrect) {
      return const Color(0xFFFEF2F2);
    }
    return widget.backgroundColor ?? Colors.white;
  }

  Color _getBorderColor() {
    if (widget.borderColor != null && widget.status == AppCardStatus.normal) {
      return widget.borderColor!;
    }
    switch (widget.status) {
      case AppCardStatus.normal:
        return const Color(0xFFE2E8F0);
      case AppCardStatus.selected:
        return const Color(0xFF0EA5E9);
      case AppCardStatus.completed:
        return const Color(0xFF10B981);
      case AppCardStatus.locked:
        return const Color(0xFFCBD5E1);
      case AppCardStatus.incorrect:
        return const Color(0xFFEF4444);
    }
  }

  Color _getDepthColor() {
    switch (widget.status) {
      case AppCardStatus.normal:
        return const Color(0xFFCBD5E1);
      case AppCardStatus.selected:
        return const Color(0xFF0284C7);
      case AppCardStatus.completed:
        return const Color(0xFF059669);
      case AppCardStatus.locked:
        return const Color(0xFFE2E8F0);
      case AppCardStatus.incorrect:
        return const Color(0xFFDC2626);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReduced = AppMotion.isReducedMotion(context);
    final bgColor = _getBackgroundColor();
    final borderColor = _getBorderColor();
    final depthColor = _getDepthColor();
    const double depth = 4.0;
    final double effectiveDepth = widget.status == AppCardStatus.locked ? 2.0 : depth;
    final double translateY = (_isPressed && _isInteractive && !isReduced) ? effectiveDepth : 0.0;

    return RepaintBoundary(
      child: Padding(
        padding: widget.margin ?? EdgeInsets.zero,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool hasBoundedW = constraints.hasBoundedWidth && constraints.maxWidth.isFinite;
            final bool hasBoundedH = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;

            final double? cardWidth = widget.width ?? (hasBoundedW ? constraints.maxWidth : null);
            final double? cardHeight = widget.height ?? (hasBoundedH ? constraints.maxHeight : null);

            Widget content = Container(
              width: cardWidth,
              height: cardHeight,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: borderColor,
                  width: widget.status == AppCardStatus.normal ? 1.5 : 2.0,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main Body
                  if (cardHeight != null)
                    Positioned.fill(
                      child: Opacity(
                        opacity: widget.status == AppCardStatus.locked ? 0.55 : 1.0,
                        child: widget.child,
                      ),
                    )
                  else
                    SizedBox(
                      width: cardWidth,
                      child: Opacity(
                        opacity: widget.status == AppCardStatus.locked ? 0.55 : 1.0,
                        child: widget.child,
                      ),
                    ),

                  // Completed Checkmark Badge
                  if (widget.status == AppCardStatus.completed)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x3310B981),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),

                  // Locked Padlock Overlay Icon
                  if (widget.status == AppCardStatus.locked)
                    const Positioned.fill(
                      child: Center(
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0xFF94A3B8),
                          child: Icon(Icons.lock_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                ],
              ),
            );

            // If unbounded height (e.g. in a ListView or unconstrained Column)
            if (cardHeight == null) {
              return SizedBox(
                width: cardWidth,
                child: GestureDetector(
                  onTapDown: _handleTapDown,
                  onTapUp: _handleTapUp,
                  onTapCancel: _handleTapCancel,
                  onTap: _isInteractive ? widget.onTap : null,
                  onLongPress: _isInteractive ? widget.onLongPress : null,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: effectiveDepth),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 3D Depth Layer (matches intrinsic size of top surface)
                        Positioned.fill(
                          top: effectiveDepth,
                          bottom: -effectiveDepth,
                          child: Container(
                            decoration: BoxDecoration(
                              color: depthColor,
                              borderRadius: BorderRadius.circular(widget.borderRadius),
                            ),
                          ),
                        ),

                        // Top pressable surface
                        AnimatedContainer(
                          duration: Duration(milliseconds: _isPressed ? 90 : 160),
                          curve: _isPressed ? Curves.easeOut : const Cubic(0.34, 1.56, 0.64, 1.0),
                          transform: Matrix4.translationValues(0, translateY, 0),
                          width: cardWidth,
                          child: content,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Bounded width & height (e.g. inside GridView cell)
            return SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: GestureDetector(
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                onTap: _isInteractive ? widget.onTap : null,
                onLongPress: _isInteractive ? widget.onLongPress : null,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.only(bottom: effectiveDepth),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 3D Depth Layer - exactly fills the card frame
                      Positioned(
                        left: 0,
                        right: 0,
                        top: effectiveDepth,
                        bottom: -effectiveDepth,
                        child: Container(
                          decoration: BoxDecoration(
                            color: depthColor,
                            borderRadius: BorderRadius.circular(widget.borderRadius),
                          ),
                        ),
                      ),

                      // Top Pressable Surface - exactly fills the card frame
                      Positioned.fill(
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: _isPressed ? 90 : 160),
                          curve: _isPressed ? Curves.easeOut : const Cubic(0.34, 1.56, 0.64, 1.0),
                          transform: Matrix4.translationValues(0, translateY, 0),
                          child: content,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
