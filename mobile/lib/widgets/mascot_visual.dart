import 'package:flutter/material.dart';

enum MascotType { bibo, toti, sippy, starry, group }

class MascotVisual extends StatelessWidget {
  final MascotType type;
  final double size;
  final bool isCelebrating;
  final bool isSad;

  const MascotVisual({
    super.key,
    required this.type,
    this.size = 120,
    this.isCelebrating = false,
    this.isSad = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: _buildVisual(),
    );
  }

  Widget _buildVisual() {
    switch (type) {
      case MascotType.bibo:
        return _MascotImage(imagePath: 'assets/images/GetStartedMascot.png', size: size);
      case MascotType.toti:
        return _MascotImage(imagePath: 'assets/images/GetStartedMascot.png', size: size);
      case MascotType.sippy:
        return _MascotImage(imagePath: 'assets/images/GetStartedMascot.png', size: size);
      case MascotType.starry:
        return _MascotImage(imagePath: 'assets/images/GetStartedMascot.png', size: size);
      case MascotType.group:
        return _GroupMascotWidget(size: size);
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Center(
            child: Icon(Icons.broken_image, color: Color(0xFF94A3B8)),
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

  const _MascotGif({
    required this.normalGif,
    required this.sadGif,
    required this.celebratingGif,
    required this.size,
    required this.isCelebrating,
    required this.isSad,
  });

  @override
  Widget build(BuildContext context) {
    final gifPath = isCelebrating
        ? celebratingGif
        : isSad
            ? sadGif
            : normalGif;

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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Center(
            child: Icon(Icons.broken_image, color: Color(0xFF94A3B8)),
          ),
        );
      },
    );
  }
}

// Old CustomPainter classes kept for reference but not used
// class _BiboPainter extends CustomPainter { ... }
// class _TotiPainter extends CustomPainter { ... }
// class _SippyPainter extends CustomPainter { ... }
// class _StarryPainter extends CustomPainter { ... }

class _GroupMascotWidget extends StatelessWidget {
  final double size;
  const _GroupMascotWidget({required this.size});

  @override
  Widget build(BuildContext context) {
    final itemSize = size * 0.5;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Starry (Top center)
        Positioned(
          top: 0,
          child: _MascotImage(imagePath: 'assets/images/GetStartedMascot.png', size: itemSize),
        ),
        // Sippy (Top Right)
        Positioned(
          top: size * 0.2,
          right: 0,
          child: _MascotImage(imagePath: 'assets/images/GetStartedMascot.png', size: itemSize),
        ),
        // Bibo (Bottom Left)
        Positioned(
          bottom: 0,
          left: 0,
          child: _MascotImage(imagePath: 'assets/images/GetStartedMascot.png', size: itemSize),
        ),
        // Toti (Bottom Right)
        Positioned(
          bottom: 0,
          right: size * 0.15,
          child: _MascotImage(imagePath: 'assets/images/GetStartedMascot.png', size: itemSize),
        ),
      ],
    );
  }
}
