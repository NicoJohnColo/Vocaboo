import 'package:flutter/material.dart';
import '../core/motion/motion.dart';

/// Floating "+XP" particle feedback animation.
///
/// Spawns an animated badge that floats upward ~40px while fading to opacity 0 over 700ms.
class AppXpFeedback extends StatefulWidget {
  final int points;
  final VoidCallback? onComplete;

  const AppXpFeedback({
    super.key,
    required this.points,
    this.onComplete,
  });

  @override
  State<AppXpFeedback> createState() => _AppXpFeedbackState();
}

class _AppXpFeedbackState extends State<AppXpFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _translateAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _translateAnimation = Tween<double>(begin: 0.0, end: -45.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.25), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 65),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward().then((_) {
      if (mounted) widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.isReducedMotion(context)) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _translateAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B), // Amber Gold
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD97706), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40F59E0B),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 4),
            Text(
              '+${widget.points} XP',
              style: AppTypography.displayLarge.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper class to spawn a floating +XP badge anywhere on the screen overlay.
class AppXpOverlay {
  static void show(BuildContext context, int points, {Offset? position}) {
    if (AppMotion.isReducedMotion(context)) return;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    final targetPos = position ??
        (renderBox != null
            ? renderBox.localToGlobal(Offset(renderBox.size.width / 2 - 40, renderBox.size.height / 2))
            : const Offset(160, 300));

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: targetPos.dx,
        top: targetPos.dy,
        child: IgnorePointer(
          child: AppXpFeedback(
            points: points,
            onComplete: () {
              entry.remove();
            },
          ),
        ),
      ),
    );

    overlay.insert(entry);
  }
}
