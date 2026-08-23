import 'package:flutter/material.dart';
import '../motion_tokens.dart';

/// An initial cold-start splash transition widget that sequences logo pop,
/// brand glow expansion, and seamless cross-dissolve into the destination screen.
class AppSplashTransition extends StatefulWidget {
  final Widget child;
  final Widget? logoWidget;
  final String title;
  final String subtitle;
  final VoidCallback? onAnimationComplete;
  final Duration duration;

  const AppSplashTransition({
    super.key,
    required this.child,
    this.logoWidget,
    this.title = 'Vocaboo',
    this.subtitle = 'Fun & Adaptive Vocabulary Learning',
    this.onAnimationComplete,
    this.duration = const Duration(milliseconds: 1800),
  });

  @override
  State<AppSplashTransition> createState() => _AppSplashTransitionState();
}

class _AppSplashTransitionState extends State<AppSplashTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _glowRadius;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _contentReveal;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // 0% - 40%: Logo pops in with subtle elastic overshoot
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: AppCurves.springBack),
      ),
    );

    // 10% - 50%: Background glow expands
    _glowRadius = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.55, curve: Curves.easeOut),
      ),
    );

    // 35% - 65%: Brand text slides up and fades in
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.65, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.65, curve: AppCurves.emphasizedDecelerate),
      ),
    );

    // 75% - 100%: Splash dissolves, revealing target child screen seamlessly
    _contentReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward().then((_) {
      widget.onAnimationComplete?.call();
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

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final revealProgress = _contentReveal.value;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Destination screen (fading in)
            Opacity(
              opacity: revealProgress,
              child: widget.child,
            ),

            // Splash Overlay (fading out at the end)
            if (revealProgress < 1.0)
              Opacity(
                opacity: (1.0 - revealProgress).clamp(0.0, 1.0),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF0284C7)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with animated radial glow
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 160 * _glowRadius.value,
                              height: 160 * _glowRadius.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.25 * (1.0 - revealProgress)),
                              ),
                            ),
                            ScaleTransition(
                              scale: _logoScale,
                              child: widget.logoWidget ??
                                  Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.auto_stories_rounded,
                                      size: 52,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Title + Subtitle entrance
                        SlideTransition(
                          position: _textSlide,
                          child: FadeTransition(
                            opacity: _textFade,
                            child: Column(
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.subtitle,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
