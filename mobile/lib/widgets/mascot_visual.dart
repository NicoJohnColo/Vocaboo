import 'dart:math';
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
        return CustomPaint(
          painter: _BiboPainter(isCelebrating: isCelebrating, isSad: isSad),
        );
      case MascotType.toti:
        return CustomPaint(
          painter: _TotiPainter(isCelebrating: isCelebrating, isSad: isSad),
        );
      case MascotType.sippy:
        return CustomPaint(
          painter: _SippyPainter(isCelebrating: isCelebrating, isSad: isSad),
        );
      case MascotType.starry:
        return CustomPaint(
          painter: _StarryPainter(isCelebrating: isCelebrating, isSad: isSad),
        );
      case MascotType.group:
        return _GroupMascotWidget(size: size);
    }
  }
}

class _BiboPainter extends CustomPainter {
  final bool isCelebrating;
  final bool isSad;
  _BiboPainter({required this.isCelebrating, required this.isSad});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h * 0.6);
    final bodyRadius = w * 0.3;

    // Ears Paint
    final bodyPaint = Paint()
      ..color = const Color(0xFF0EA5E9) // Turquoise Blue
      ..style = PaintingStyle.fill;
    final innerEarPaint = Paint()
      ..color = const Color(0xFFF472B6) // Pink
      ..style = PaintingStyle.fill;

    // Left Ear
    final leftEarPath = Path();
    leftEarPath.addOval(Rect.fromLTWH(w * 0.25, h * 0.05, w * 0.15, h * 0.4));
    canvas.save();
    canvas.translate(w * 0.3, h * 0.25);
    canvas.rotate(-0.1);
    canvas.translate(-w * 0.3, -h * 0.25);
    canvas.drawPath(leftEarPath, bodyPaint);
    final leftInnerEarPath = Path();
    leftInnerEarPath.addOval(Rect.fromLTWH(w * 0.28, h * 0.1, w * 0.09, h * 0.3));
    canvas.drawPath(leftInnerEarPath, innerEarPaint);
    canvas.restore();

    // Right Ear
    final rightEarPath = Path();
    rightEarPath.addOval(Rect.fromLTWH(w * 0.6, h * 0.05, w * 0.15, h * 0.4));
    canvas.save();
    canvas.translate(w * 0.7, h * 0.25);
    canvas.rotate(0.1);
    canvas.translate(-w * 0.7, -h * 0.25);
    canvas.drawPath(rightEarPath, bodyPaint);
    final rightInnerEarPath = Path();
    rightInnerEarPath.addOval(Rect.fromLTWH(w * 0.63, h * 0.1, w * 0.09, h * 0.3));
    canvas.drawPath(rightInnerEarPath, innerEarPaint);
    canvas.restore();

    // Body
    canvas.drawCircle(center, bodyRadius, bodyPaint);

    // Eyes
    final eyePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    if (isSad) {
      // Draw closed down-curved eyes
      final leftEyePath = Path()
        ..moveTo(w * 0.38, h * 0.58)
        ..quadraticBezierTo(w * 0.42, h * 0.54, w * 0.46, h * 0.58);
      final rightEyePath = Path()
        ..moveTo(w * 0.54, h * 0.58)
        ..quadraticBezierTo(w * 0.58, h * 0.54, w * 0.62, h * 0.58);
      final strokePaint = Paint()
        ..color = const Color(0xFF0F172A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawPath(leftEyePath, strokePaint);
      canvas.drawPath(rightEyePath, strokePaint);
    } else {
      // Draw big open eyes
      canvas.drawCircle(Offset(w * 0.4, h * 0.56), 6, eyePaint);
      canvas.drawCircle(Offset(w * 0.6, h * 0.56), 6, eyePaint);
      // Highlights
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(w * 0.38, h * 0.54), 2, whitePaint);
      canvas.drawCircle(Offset(w * 0.58, h * 0.54), 2, whitePaint);
    }

    // Rosy cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFFCA5A5).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.32, h * 0.62), 6, cheekPaint);
    canvas.drawCircle(Offset(w * 0.68, h * 0.62), 6, cheekPaint);

    // Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final mouthPath = Path();
    if (isSad) {
      mouthPath.moveTo(w * 0.46, h * 0.68);
      mouthPath.quadraticBezierTo(w * 0.5, h * 0.64, w * 0.54, h * 0.68);
    } else {
      mouthPath.moveTo(w * 0.46, h * 0.64);
      mouthPath.quadraticBezierTo(w * 0.5, h * 0.68, w * 0.54, h * 0.64);
    }
    canvas.drawPath(mouthPath, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TotiPainter extends CustomPainter {
  final bool isCelebrating;
  final bool isSad;
  _TotiPainter({required this.isCelebrating, required this.isSad});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shell background (backpack)
    final bpPaint = Paint()..color = const Color(0xFFD97706); // Brownish Orange
    canvas.drawCircle(Offset(w * 0.32, h * 0.55), w * 0.26, bpPaint);

    // Turtle Shell / Body
    final shellPaint = Paint()..color = const Color(0xFF10B981); // Emerald Green
    canvas.drawCircle(Offset(w * 0.52, h * 0.58), w * 0.3, shellPaint);

    // Turtle Head
    final headPaint = Paint()..color = const Color(0xFF34D399); // Lighter Green
    canvas.drawCircle(Offset(w * 0.52, h * 0.3), w * 0.18, headPaint);

    // Glasses
    final glassesPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(Offset(w * 0.44, h * 0.28), w * 0.07, glassesPaint);
    canvas.drawCircle(Offset(w * 0.6, h * 0.28), w * 0.07, glassesPaint);
    canvas.drawLine(Offset(w * 0.51, h * 0.28), Offset(w * 0.53, h * 0.28), glassesPaint);

    // Eyes behind glasses
    final eyePaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawCircle(Offset(w * 0.44, h * 0.28), 3, eyePaint);
    canvas.drawCircle(Offset(w * 0.6, h * 0.28), 3, eyePaint);

    // Rosy cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFFCA5A5).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.38, h * 0.34), 4, cheekPaint);
    canvas.drawCircle(Offset(w * 0.66, h * 0.34), 4, cheekPaint);

    // Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final mouthPath = Path();
    if (isSad) {
      mouthPath.moveTo(w * 0.48, h * 0.38);
      mouthPath.quadraticBezierTo(w * 0.52, h * 0.35, w * 0.56, h * 0.38);
    } else {
      mouthPath.moveTo(w * 0.48, h * 0.35);
      mouthPath.quadraticBezierTo(w * 0.52, h * 0.39, w * 0.56, h * 0.35);
    }
    canvas.drawPath(mouthPath, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SippyPainter extends CustomPainter {
  final bool isCelebrating;
  final bool isSad;
  _SippyPainter({required this.isCelebrating, required this.isSad});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Straw (diagonal red/white)
    final strawPaint = Paint()..color = const Color(0xFFEF4444);
    final strawPath = Path();
    strawPath.moveTo(w * 0.52, h * 0.22);
    strawPath.lineTo(w * 0.65, h * 0.05);
    strawPath.lineTo(w * 0.72, h * 0.09);
    strawPath.lineTo(w * 0.59, h * 0.22);
    strawPath.close();
    canvas.drawPath(strawPath, strawPaint);

    // Straw white stripes
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.58, h * 0.14), 3, whitePaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.07), 3, whitePaint);

    // Cup Body (Trapezoid-like, Blue)
    final cupPaint = Paint()..color = const Color(0xFF6366F1); // Indigo Blue
    final cupPath = Path();
    cupPath.moveTo(w * 0.3, h * 0.3);
    cupPath.lineTo(w * 0.7, h * 0.3);
    cupPath.lineTo(w * 0.64, h * 0.85);
    cupPath.lineTo(w * 0.36, h * 0.85);
    cupPath.close();
    canvas.drawPath(cupPath, cupPaint);

    // Lid (White Oval)
    final lidPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    final lidBorderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final lidRect = Rect.fromLTRB(w * 0.26, h * 0.22, w * 0.74, h * 0.32);
    canvas.drawOval(lidRect, lidPaint);
    canvas.drawOval(lidRect, lidBorderPaint);

    // Eyes
    final eyePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.44, h * 0.48), 5, eyePaint);
    canvas.drawCircle(Offset(w * 0.56, h * 0.48), 5, eyePaint);

    // Rosy cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFFCA5A5).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.38, h * 0.54), 4, cheekPaint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.54), 4, cheekPaint);

    // Mouth (smiling)
    final mouthPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final mouthPath = Path();
    if (isSad) {
      mouthPath.moveTo(w * 0.47, h * 0.58);
      mouthPath.quadraticBezierTo(w * 0.5, h * 0.55, w * 0.53, h * 0.58);
    } else {
      mouthPath.moveTo(w * 0.46, h * 0.54);
      mouthPath.quadraticBezierTo(w * 0.5, h * 0.6, w * 0.54, h * 0.54);
    }
    canvas.drawPath(mouthPath, mouthPaint);

    // Cute small hands/legs
    final limbPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    // Left leg
    canvas.drawLine(Offset(w * 0.42, h * 0.85), Offset(w * 0.42, h * 0.94), limbPaint);
    // Right leg
    canvas.drawLine(Offset(w * 0.58, h * 0.85), Offset(w * 0.58, h * 0.94), limbPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarryPainter extends CustomPainter {
  final bool isCelebrating;
  final bool isSad;
  _StarryPainter({required this.isCelebrating, required this.isSad});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // 5-pointed Star Path
    final starPaint = Paint()
      ..color = const Color(0xFFFBBF24) // Yellow/Amber
      ..style = PaintingStyle.fill;
    final starPath = Path();
    
    int points = 5;
    double outerRadius = w * 0.42;
    double innerRadius = w * 0.18;
    double angle = -pi / 2;
    double rotation = pi / points;

    for (int i = 0; i < points * 2; i++) {
      double r = i.isEven ? outerRadius : innerRadius;
      double x = cx + cos(angle) * r;
      double y = cy + sin(angle) * r;
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
      angle += rotation;
    }
    starPath.close();
    canvas.drawPath(starPath, starPaint);

    // Eyes
    final eyePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 10, cy - 4), 4.5, eyePaint);
    canvas.drawCircle(Offset(cx + 10, cy - 4), 4.5, eyePaint);

    // Cheek paints
    final cheekPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 18, cy + 2), 4, cheekPaint);
    canvas.drawCircle(Offset(cx + 18, cy + 2), 4, cheekPaint);

    // Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final mouthPath = Path();
    if (isSad) {
      mouthPath.moveTo(cx - 5, cy + 8);
      mouthPath.quadraticBezierTo(cx, cy + 5, cx + 5, cy + 8);
    } else {
      mouthPath.moveTo(cx - 5, cy + 6);
      mouthPath.quadraticBezierTo(cx, cy + 10, cx + 5, cy + 6);
    }
    canvas.drawPath(mouthPath, mouthPaint);

    // Hands
    final handPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    // Left hand
    canvas.drawLine(Offset(cx - 16, cy + 8), Offset(cx - 24, cy + 12), handPaint);
    // Right hand
    canvas.drawLine(Offset(cx + 16, cy + 8), Offset(cx + 24, cy + 12), handPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GroupMascotWidget extends StatelessWidget {
  final double size;
  const _GroupMascotWidget({required this.size});

  @override
  Widget build(BuildContext context) {
    final itemSize = size * 0.45;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Starry (Top center)
        Positioned(
          top: 0,
          child: MascotVisual(type: MascotType.starry, size: itemSize),
        ),
        // Sippy (Top Right)
        Positioned(
          top: size * 0.2,
          right: 0,
          child: MascotVisual(type: MascotType.sippy, size: itemSize),
        ),
        // Bibo (Bottom Left)
        Positioned(
          bottom: 0,
          left: 0,
          child: MascotVisual(type: MascotType.bibo, size: itemSize),
        ),
        // Toti (Bottom Right)
        Positioned(
          bottom: 0,
          right: size * 0.15,
          child: MascotVisual(type: MascotType.toti, size: itemSize),
        ),
      ],
    );
  }
}
