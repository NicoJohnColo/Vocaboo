import 'package:flutter/material.dart';
import 'mascot_visual.dart';
import '../services/tts_service.dart';

class MascotBubble extends StatelessWidget {
  final String mascotName;
  final String speechText;
  final String? ttsText;
  final bool isSad;
  final bool isCelebrating;
  final double avatarSize;

  const MascotBubble({
    super.key,
    required this.mascotName,
    required this.speechText,
    this.ttsText,
    this.isSad = false,
    this.isCelebrating = false,
    this.avatarSize = 120,
  });

  MascotType _getMascotType() {
    switch (mascotName.toLowerCase()) {
      case 'bibo':
        return MascotType.bibo;
      case 'toti':
        return MascotType.toti;
      case 'sippy':
        return MascotType.sippy;
      case 'starry':
        return MascotType.starry;
      case 'robi':
        return MascotType.robi;
      default:
        return MascotType.bibo;
    }
  }

  Color _getMascotColor() {
    switch (mascotName.toLowerCase()) {
      case 'bibo':
        return const Color(0xFF0EA5E9); // Turquoise Blue
      case 'toti':
        return const Color(0xFF10B981); // Emerald Green
      case 'sippy':
        return const Color(0xFF6366F1); // Indigo Purple
      case 'starry':
        return const Color(0xFFF59E0B); // Amber Gold
      case 'robi':
        return const Color(0xFF06A6FF); // Sky Blue
      default:
        return const Color(0xFF0EA5E9);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mascotColor = _getMascotColor();
    final mascotType = _getMascotType();
    final frameSize = avatarSize;
    final mascotSize = avatarSize * 1.3;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mascot Avatar Column
          Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Celebrating sparkles or Sad drops backdrops
                  // Removed yellow celebration backdrop to keep mascots clean

                  SizedBox(
                    width: frameSize,
                    height: frameSize,
                    child: Center(
                      child: MascotVisual(
                        type: mascotType,
                        size: mascotSize,
                        isCelebrating: isCelebrating,
                        isSad: isSad,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: mascotColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mascotName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Speech Bubble Column
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Speech bubble triangle pointing left
                Positioned(
                  left: -6,
                  top: 22,
                  child: CustomPaint(
                    size: const Size(6, 12),
                    painter: _BubbleTrianglePainter(mascotColor),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                       boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          speechText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Speak button
                      GestureDetector(
                        onTap: () {
                          TTSService.speak(ttsText ?? speechText);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: mascotColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.volume_up_rounded,
                            size: 20,
                            color: mascotColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleTrianglePainter extends CustomPainter {
  final Color color;
  _BubbleTrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(0, size.height / 2);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Inner white overlay
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final innerPath = Path();
    innerPath.moveTo(size.width, 1.5);
    innerPath.lineTo(1.5, size.height / 2);
    innerPath.lineTo(size.width, size.height - 1.5);
    innerPath.close();
    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
