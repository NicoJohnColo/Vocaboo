import 'package:flutter/material.dart';
import '../motion_tokens.dart';

/// A high-performance, gradient-sweep shimmer skeleton widget.
///
/// Designed to run with zero layout recalculation overhead by updating
/// shader matrix transforms within an isolated [RepaintBoundary].
class AppShimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE2E8F0), // Slate-200
    this.highlightColor = const Color(0xFFF8FAFC), // Slate-50
    this.duration = const Duration(milliseconds: 1500),
  });

  /// Preset: Card placeholder shimmer.
  factory AppShimmer.card({
    Key? key,
    double height = 140,
    double width = double.infinity,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(20)),
  }) {
    return AppShimmer(
      key: key,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  /// Preset: Standard ListTile placeholder shimmer.
  factory AppShimmer.listTile({Key? key}) {
    return AppShimmer(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 11,
                    width: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Preset: Circular avatar shimmer.
  factory AppShimmer.avatar({Key? key, double size = 48}) {
    return AppShimmer(
      key: key,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFE2E8F0),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// Preset: Text line skeleton.
  factory AppShimmer.textLine({
    Key? key,
    double height = 14,
    double width = 120,
    double radius = 6,
  }) {
    return AppShimmer(
      key: key,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  /// Preset: Grid of card shimmers.
  factory AppShimmer.grid({
    Key? key,
    int itemCount = 4,
    int crossAxisCount = 2,
  }) {
    return AppShimmer(
      key: key,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.isReducedMotion(context)) {
      // Reduced motion: Show a static, low-contrast placeholder
      return widget.child;
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              final double shimmerTranslate = _controller.value * (bounds.width * 2) - bounds.width;
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.baseColor,
                  widget.highlightColor,
                  widget.baseColor,
                ],
                stops: const [0.1, 0.5, 0.9],
                transform: _SlideGradientTransform(shimmerTranslate),
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  final double offset;
  const _SlideGradientTransform(this.offset);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(offset, 0.0, 0.0);
  }
}
