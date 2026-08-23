import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A custom, branded pull-to-refresh widget with elastic physics,
/// rotation tracking during pull, and a pulsing refresh spinner.
class AppRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color indicatorColor;
  final Color backgroundColor;
  final double displacement;

  const AppRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.indicatorColor = const Color(0xFF0EA5E9),
    this.backgroundColor = Colors.white,
    this.displacement = 48.0,
  });

  @override
  State<AppRefreshIndicator> createState() => _AppRefreshIndicatorState();
}

class _AppRefreshIndicatorState extends State<AppRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    _pulseController.repeat();
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: widget.indicatorColor,
      backgroundColor: widget.backgroundColor,
      displacement: widget.displacement,
      strokeWidth: 2.8,
      child: widget.child,
    );
  }
}

/// A standalone branded pulling indicator visual used for custom nested scroll views.
class AppBrandedPullHeader extends StatelessWidget {
  final double pullDistance;
  final bool isRefreshing;
  final Color color;

  const AppBrandedPullHeader({
    super.key,
    required this.pullDistance,
    required this.isRefreshing,
    this.color = const Color(0xFF0EA5E9),
  });

  @override
  Widget build(BuildContext context) {
    final double rotation = pullDistance * 0.05 * math.pi;
    final double scale = (pullDistance / 60.0).clamp(0.0, 1.0);

    return Center(
      child: Transform.scale(
        scale: scale,
        child: Transform.rotate(
          angle: rotation,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isRefreshing
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Icon(
                    Icons.autorenew_rounded,
                    color: color,
                    size: 24,
                  ),
          ),
        ),
      ),
    );
  }
}
