import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/motion/motion.dart';

enum AppPathNodeStatus {
  locked,
  available,
  inProgress,
  completed,
}

/// A Duolingo-style game board path node widget.
///
/// Supports:
/// - Gentle idle breathing pulse for available/active node (1.0 -> 1.03 -> 1.0, 2s loop).
/// - Tactile bounce overshoot on tap (`1.0 -> 1.15 -> 1.0`).
/// - 1-3 star rating underneath completed nodes.
/// - Locked state with padlock and desaturated styling.
class AppPathNodeWidget extends StatefulWidget {
  final int lessonIndex;
  final String title;
  final IconData icon;
  final AppPathNodeStatus status;
  final int stars; // 0 to 3
  final VoidCallback? onTap;
  final Color primaryColor;
  final double size;

  const AppPathNodeWidget({
    super.key,
    required this.lessonIndex,
    required this.title,
    this.icon = Icons.star_rounded,
    this.status = AppPathNodeStatus.available,
    this.stars = 0,
    this.onTap,
    this.primaryColor = const Color(0xFF0EA5E9),
    this.size = 72.0,
  });

  @override
  State<AppPathNodeWidget> createState() => _AppPathNodeWidgetState();
}

class _AppPathNodeWidgetState extends State<AppPathNodeWidget>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Idle breathing animation for active/available node
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOutSine,
      ),
    );

    if (widget.status == AppPathNodeStatus.available ||
        widget.status == AppPathNodeStatus.inProgress) {
      _breathingController.repeat(reverse: true);
    }

    // Tap bounce overshoot animation
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.90), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 30),
    ]).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void didUpdateWidget(AppPathNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      if (widget.status == AppPathNodeStatus.available ||
          widget.status == AppPathNodeStatus.inProgress) {
        if (!_breathingController.isAnimating) {
          _breathingController.repeat(reverse: true);
        }
      } else {
        _breathingController.stop();
        _breathingController.reset();
      }
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.status == AppPathNodeStatus.locked) return;
    HapticFeedback.lightImpact();
    _bounceController.forward(from: 0.0).then((_) {
      if (mounted) widget.onTap?.call();
    });
  }

  Color _getNodeColor() {
    switch (widget.status) {
      case AppPathNodeStatus.locked:
        return const Color(0xFFE2E8F0);
      case AppPathNodeStatus.available:
      case AppPathNodeStatus.inProgress:
        return widget.primaryColor;
      case AppPathNodeStatus.completed:
        return const Color(0xFF10B981);
    }
  }

  Color _getDepthColor() {
    switch (widget.status) {
      case AppPathNodeStatus.locked:
        return const Color(0xFFCBD5E1);
      case AppPathNodeStatus.available:
      case AppPathNodeStatus.inProgress:
        return HSLColor.fromColor(widget.primaryColor)
            .withLightness((HSLColor.fromColor(widget.primaryColor).lightness - 0.15).clamp(0.0, 1.0))
            .toColor();
      case AppPathNodeStatus.completed:
        return const Color(0xFF059669);
    }
  }

  IconData _getIcon() {
    switch (widget.status) {
      case AppPathNodeStatus.locked:
        return Icons.lock_rounded;
      case AppPathNodeStatus.available:
      case AppPathNodeStatus.inProgress:
        return widget.icon;
      case AppPathNodeStatus.completed:
        return Icons.check_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReduced = AppMotion.isReducedMotion(context);
    final nodeColor = _getNodeColor();
    final depthColor = _getDepthColor();
    final iconData = _getIcon();
    final isInteractive = widget.status != AppPathNodeStatus.locked;

    Widget nodeCircle = SizedBox(
      width: widget.size,
      height: widget.size + 8,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 3D Bottom Depth Rim
          Positioned(
            top: 8,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: depthColor,
              ),
            ),
          ),

          // Main Surface Node
          Positioned(
            top: 0,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: nodeColor,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 3.5,
                ),
                boxShadow: isInteractive
                    ? [
                        BoxShadow(
                          color: depthColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  iconData,
                  color: widget.status == AppPathNodeStatus.locked
                      ? const Color(0xFF94A3B8)
                      : Colors.white,
                  size: widget.size * 0.44,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Combine animations
    Widget animatedNode = AnimatedBuilder(
      animation: Listenable.merge([_breathingController, _bounceController]),
      builder: (context, child) {
        if (isReduced) return child!;
        double scale = _bounceController.isAnimating
            ? _bounceAnimation.value
            : (_breathingController.isAnimating ? _breathingAnimation.value : 1.0);

        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: nodeCircle,
    );

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          animatedNode,
          const SizedBox(height: 6),

          // Stars under completed node
          if (widget.status == AppPathNodeStatus.completed)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final bool earned = i < widget.stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Icon(
                    earned ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: earned ? const Color(0xFFFBBF24) : const Color(0xFFCBD5E1),
                    size: 16,
                  ),
                );
              }),
            ),

          // Title label under node
          if (widget.title.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              widget.title,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: widget.status == AppPathNodeStatus.locked
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
