import 'package:flutter/material.dart';
import '../motion_tokens.dart';

/// An individual staggered fade + slide entrance item wrapper.
class AppStaggeredFadeIn extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration delayPerItem;
  final Duration animationDuration;
  final Offset slideOffset;

  const AppStaggeredFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.delayPerItem = const Duration(milliseconds: 40),
    this.animationDuration = AppDurations.standard,
    this.slideOffset = const Offset(0.0, 0.15),
  });

  @override
  State<AppStaggeredFadeIn> createState() => _AppStaggeredFadeInState();
}

class _AppStaggeredFadeInState extends State<AppStaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppCurves.emphasizedDecelerate,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppCurves.emphasizedDecelerate,
      ),
    );

    // Cap delay to prevent items down a long list from waiting indefinitely
    final delayMs = (widget.index * widget.delayPerItem.inMilliseconds).clamp(0, 450);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        _controller.forward();
      }
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
      return widget.child;
    }

    return RepaintBoundary(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A ListView helper that wraps items in [AppStaggeredFadeIn] automatically.
class AppStaggeredListView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final bool shrinkWrap;

  const AppStaggeredListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.physics,
    this.controller,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      physics: physics ?? const BouncingScrollPhysics(),
      padding: padding,
      shrinkWrap: shrinkWrap,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return AppStaggeredFadeIn(
          index: index,
          child: itemBuilder(context, index),
        );
      },
    );
  }
}
