// streak_and_break_animations.dart
//
// Two boredom-reduction features for Vocaboo, built as drop-in Flutter
// widgets that sit ON TOP of existing logic — neither one touches
// mastery tiers, the reinforcement queue, or the database schema.
//
// 1. StreakCelebrationOverlay — a full-screen "surprise" burst shown when
//    a learner hits a correct-streak milestone (3, 6, 9... in a row).
//
// 2. MicroBreakScreen — a short, low-stakes breather screen shown every
//    N questions (e.g. every 8 questions) with a bouncy mascot, animated counting
//    stats, and a "Continue" button.

import 'dart:math';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════
// 1. STREAK CELEBRATION OVERLAY
// ═══════════════════════════════════════════════════════════════════════

class StreakCelebrationOverlay {
  /// Inserts itself into the Overlay and removes itself when the animation finishes.
  static void show(
    BuildContext context, {
    required int streakCount,
    String? message,
  }) {
    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) return;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _StreakBurst(
        streakCount: streakCount,
        message: message ?? _defaultMessageFor(streakCount),
        onComplete: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );

    overlayState.insert(entry);
  }

  static String _defaultMessageFor(int streak) {
    if (streak >= 9) return "Unstoppable! ⚡";
    if (streak >= 6) return "Amazing streak! 🌟";
    return "You're on fire! 🔥";
  }
}

class _StreakBurst extends StatefulWidget {
  final int streakCount;
  final String message;
  final VoidCallback onComplete;

  const _StreakBurst({
    required this.streakCount,
    required this.message,
    required this.onComplete,
  });

  @override
  State<_StreakBurst> createState() => _StreakBurstState();
}

class _StreakBurstState extends State<_StreakBurst>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _particles;
  late final List<_Particle> _particleList;

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _particles = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _particleList = List.generate(24, (i) => _Particle.random());

    _entrance.forward();
    _particles.forward();

    // Auto-dismiss after the show is done
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _particles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Confetti particles
            AnimatedBuilder(
              animation: _particles,
              builder: (context, _) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _ConfettiPainter(
                    particles: _particleList,
                    progress: _particles.value,
                  ),
                );
              },
            ),

            // Central badge + message
            Center(
              child: AnimatedBuilder(
                animation: _entrance,
                builder: (context, child) {
                  final scale = Curves.easeOutBack.transform(_entrance.value);
                  final fade = Curves.easeOut.transform(
                    (_entrance.value * 2).clamp(0.0, 1.0),
                  );
                  return Opacity(
                    opacity: fade,
                    child: Transform.scale(scale: scale, child: child),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrange.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Colors.yellowAccent, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.streakCount} IN A ROW!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final double rotationSpeed;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotationSpeed,
  });

  static final _rand = Random();
  static const _colors = [
    Color(0xFFFFC107),
    Color(0xFFFF7043),
    Color(0xFF66BB6A),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
  ];

  factory _Particle.random() {
    return _Particle(
      angle: _rand.nextDouble() * 2 * pi,
      speed: 80 + _rand.nextDouble() * 160,
      size: 6 + _rand.nextDouble() * 6,
      color: _colors[_rand.nextInt(_colors.length)],
      rotationSpeed: (_rand.nextDouble() - 0.5) * 10,
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);

    for (final p in particles) {
      final burstProgress = Curves.easeOut.transform(
        (progress * 2.2).clamp(0.0, 1.0),
      );
      final fallProgress = ((progress - 0.3) / 0.7).clamp(0.0, 1.0);

      final dx = cos(p.angle) * p.speed * burstProgress;
      final dy = sin(p.angle) * p.speed * burstProgress +
          (fallProgress * fallProgress * 220);

      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(center.dx + dx, center.dy + dy);
      canvas.rotate(p.rotationSpeed * progress * pi);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════
// 2. MICRO-BREAK SCREEN
// ═══════════════════════════════════════════════════════════════════════

class MicroBreakScreen extends StatefulWidget {
  final int wordsLearnedToday;
  final VoidCallback onContinue;

  const MicroBreakScreen({
    super.key,
    required this.wordsLearnedToday,
    required this.onContinue,
  });

  @override
  State<MicroBreakScreen> createState() => _MicroBreakScreenState();
}

class _MicroBreakScreenState extends State<MicroBreakScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mascotController;
  late final AnimationController _countController;
  late final Animation<int> _countAnimation;

  @override
  void initState() {
    super.initState();

    _mascotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _countAnimation = IntTween(begin: 0, end: widget.wordsLearnedToday)
        .animate(CurvedAnimation(
      parent: _countController,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _countController.forward();
    });
  }

  @override
  void dispose() {
    _mascotController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Bouncing mascot visual
                AnimatedBuilder(
                  animation: _mascotController,
                  builder: (context, child) {
                    final bounce =
                        Curves.easeInOut.transform(_mascotController.value);
                    return Transform.translate(
                      offset: Offset(0, -12 * bounce),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B3FA0),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5B3FA0).withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🌟', style: TextStyle(fontSize: 64)),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'Nice work! Take a breather 🌤️',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3B2172),
                    letterSpacing: -0.2,
                  ),
                ),

                const SizedBox(height: 24),

                // Animated count-up stat card
                AnimatedBuilder(
                  animation: _countAnimation,
                  builder: (context, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📚', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Text(
                            '${_countAnimation.value} words practiced today!',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3B2172),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 36),

                // Continue button
                _BouncyContinueButton(onPressed: widget.onContinue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable press-feedback button
class _BouncyContinueButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _BouncyContinueButton({required this.onPressed});

  @override
  State<_BouncyContinueButton> createState() => _BouncyContinueButtonState();
}

class _BouncyContinueButtonState extends State<_BouncyContinueButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
    lowerBound: 0.0,
    upperBound: 0.08,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1.0 - _controller.value;
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF5B3FA0),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B3FA0).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            'Continue',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
