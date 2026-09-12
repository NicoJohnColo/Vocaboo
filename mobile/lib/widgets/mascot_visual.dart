import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/motion/motion.dart';

enum MascotType { bibo, toti, sippy, starry, group, robi, turtle }

/// Duolingo-style mascot visual with smooth GPU-accelerated idle floating bob,
/// celebratory bouncy reactions, and static grayscale locked states.
class MascotVisual extends StatefulWidget {
  final MascotType type;
  final double size;
  final bool isCelebrating;
  final bool isSad;
  final bool enableIdleBob;
  final bool isLocked;

  const MascotVisual({
    super.key,
    required this.type,
    this.size = 120,
    this.isCelebrating = false,
    this.isSad = false,
    this.enableIdleBob = true,
    this.isLocked = false,
  });

  @override
  State<MascotVisual> createState() => _MascotVisualState();
}

class _MascotVisualState extends State<MascotVisual>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleBobController;
  late Animation<double> _bobAnimation;
  late Animation<double> _celebrationWiggle;

  static const ColorFilter _grayscaleFilter = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ]);

  @override
  void initState() {
    super.initState();
    _idleBobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // Subtle ±3.5px floating bob
    _bobAnimation = Tween<double>(begin: -3.5, end: 3.5).animate(
      CurvedAnimation(
        parent: _idleBobController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Subtle celebration rotation wiggle (±0.05 radians ~ 3°)
    _celebrationWiggle = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(
        parent: _idleBobController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Animation loop is initialized in didChangeDependencies respecting reduced motion
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isReduced = AppMotion.isReducedMotion(context);
    if (isReduced || widget.isLocked || !widget.enableIdleBob) {
      if (_idleBobController.isAnimating) {
        _idleBobController.stop();
        _idleBobController.reset();
      }
    } else if (!_idleBobController.isAnimating) {
      _idleBobController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MascotVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isReduced = AppMotion.isReducedMotion(context);
    if (widget.isLocked || isReduced || !widget.enableIdleBob) {
      if (_idleBobController.isAnimating) {
        _idleBobController.stop();
        _idleBobController.reset();
      }
    } else if (!_idleBobController.isAnimating) {
      _idleBobController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _idleBobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReduced = AppMotion.isReducedMotion(context);

    Widget visual = SizedBox(
      width: widget.size,
      height: widget.size,
      child: _buildVisual(),
    );

    if (widget.isLocked) {
      return Opacity(
        opacity: 0.55,
        child: ColorFiltered(
          colorFilter: _grayscaleFilter,
          child: visual,
        ),
      );
    }

    if (isReduced || !widget.enableIdleBob) {
      return visual;
    }

    return AnimatedBuilder(
      animation: _idleBobController,
      builder: (context, child) {
        double offsetY = _bobAnimation.value;
        double angle = widget.isCelebrating ? _celebrationWiggle.value : 0.0;
        double scale = widget.isCelebrating ? 1.06 : 1.0;

        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: visual,
    );
  }

  Widget _buildVisual() {
    switch (widget.type) {
      case MascotType.bibo:
        return _MascotGif(
          normalGif: 'assets/images/gifs/bibo star cute.gif',
          sadGif: 'assets/images/gifs/bibo star crying.gif',
          celebratingGif: 'assets/images/gifs/bibo star cute.gif',
          size: widget.size,
          isCelebrating: widget.isCelebrating,
          isSad: widget.isSad,
          isLocked: widget.isLocked,
        );
      case MascotType.toti:
        return _MascotGif(
          normalGif: 'assets/images/gifs/grizzy bear dancing.gif',
          sadGif: 'assets/images/gifs/grizzy bear dancing.gif',
          celebratingGif: 'assets/images/gifs/grizzy thumbs up.gif',
          size: widget.size,
          isCelebrating: widget.isCelebrating,
          isSad: widget.isSad,
          isLocked: widget.isLocked,
        );
      case MascotType.sippy:
        return _MascotGif(
          normalGif: 'assets/images/gifs/sippy cup says hi.gif',
          sadGif: 'assets/images/gifs/sippy cup dissapointed.gif',
          celebratingGif: 'assets/images/gifs/sippy cup happy.gif',
          size: widget.size,
          isCelebrating: widget.isCelebrating,
          isSad: widget.isSad,
          isLocked: widget.isLocked,
        );
      case MascotType.starry:
        return _MascotGif(
          normalGif: 'assets/images/gifs/blue rabbit says hi.gif',
          sadGif: 'assets/images/gifs/blue rabbit shocked.gif',
          celebratingGif: 'assets/images/gifs/blue rabbit says hi.gif',
          size: widget.size,
          isCelebrating: widget.isCelebrating,
          isSad: widget.isSad,
          isLocked: widget.isLocked,
        );
      case MascotType.robi:
        return _MascotGif(
          normalGif: 'assets/images/gifs/robi.gif',
          sadGif: 'assets/images/gifs/robi.gif',
          celebratingGif: 'assets/images/gifs/robi.gif',
          size: widget.size,
          isCelebrating: widget.isCelebrating,
          isSad: widget.isSad,
          isLocked: widget.isLocked,
        );
      case MascotType.group:
        return _MascotImage(
          imagePath: 'assets/images/GetStartedMascot.png',
          size: widget.size,
        );
      case MascotType.turtle:
        return Image.asset(
          widget.isCelebrating
              ? 'assets/images/turtle_celebrate.png'
              : 'assets/images/turtle_thumbs_up.png',
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
        );
    }
  }
}

class _MascotImage extends StatelessWidget {
  final String imagePath;
  final double size;

  const _MascotImage({
    required this.imagePath,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
          ),
        );
      },
    );
  }
}

class _MascotGif extends StatelessWidget {
  final String normalGif;
  final String sadGif;
  final String celebratingGif;
  final double size;
  final bool isCelebrating;
  final bool isSad;
  final bool isLocked;

  const _MascotGif({
    required this.normalGif,
    required this.sadGif,
    required this.celebratingGif,
    required this.size,
    required this.isCelebrating,
    required this.isSad,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final gifPath = isCelebrating
        ? celebratingGif
        : isSad
            ? sadGif
            : normalGif;

    if (isLocked) {
      return _StaticMascotFrame(
        assetPath: gifPath,
        size: size,
      );
    }

    return Image.asset(
      gifPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8)),
          ),
        );
      },
    );
  }
}

/// Freezes the first frame of a GIF to ensure locked nodes are completely static
/// with zero animation timers or loops running.
class _StaticMascotFrame extends StatefulWidget {
  final String assetPath;
  final double size;

  const _StaticMascotFrame({
    required this.assetPath,
    required this.size,
  });

  @override
  State<_StaticMascotFrame> createState() => _StaticMascotFrameState();
}

class _StaticMascotFrameState extends State<_StaticMascotFrame> {
  ui.Image? _frame;
  ImageStream? _imageStream;
  ImageStreamListener? _streamListener;

  @override
  void initState() {
    super.initState();
    _loadFirstFrame();
  }

  @override
  void didUpdateWidget(_StaticMascotFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _cleanUpStream();
      _loadFirstFrame();
    }
  }

  void _loadFirstFrame() {
    _imageStream = AssetImage(widget.assetPath).resolve(ImageConfiguration.empty);
    _streamListener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
      if (mounted) {
        setState(() {
          _frame = info.image;
        });
      }
      _cleanUpStream(); // Detach immediately after first frame
    });
    _imageStream?.addListener(_streamListener!);
  }

  void _cleanUpStream() {
    if (_imageStream != null && _streamListener != null) {
      _imageStream?.removeListener(_streamListener!);
      _imageStream = null;
      _streamListener = null;
    }
  }

  @override
  void dispose() {
    _cleanUpStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_frame == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const SizedBox.shrink(),
      );
    }
    return RawImage(
      image: _frame,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
    );
  }
}
