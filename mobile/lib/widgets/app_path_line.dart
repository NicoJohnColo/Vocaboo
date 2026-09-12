import 'package:flutter/material.dart';

enum PathNodeAlignment { left, center, right }

/// A custom path line connecting lesson nodes on the lesson map.
/// Connects the horizontal position of one node to the next with a smooth S-curve.
/// Supports vibrant solid glowing lines for unlocked/completed paths and clean dashed curves for locked paths.
class AppPathLine extends StatelessWidget {
  final bool isUnlocked;
  final Color solidColor;
  final Color dashedColor;
  final double height;
  final double width;
  final double dashLength;
  final double dashGap;
  final PathNodeAlignment fromAlignment;
  final PathNodeAlignment toAlignment;
  final double nodeCenterOffset;

  const AppPathLine({
    super.key,
    required this.isUnlocked,
    this.solidColor = const Color(0xFFDDD6FE),
    this.dashedColor = const Color(0xFFE2E8F0),
    this.height = 58.0,
    this.width = 15.0,
    this.dashLength = 7.0,
    this.dashGap = 5.0,
    this.fromAlignment = PathNodeAlignment.center,
    this.toAlignment = PathNodeAlignment.center,
    this.nodeCenterOffset = 96.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _PathCurvePainter(
          isUnlocked: isUnlocked,
          solidColor: solidColor,
          dashedColor: dashedColor,
          strokeWidth: width,
          dashLength: dashLength,
          dashGap: dashGap,
          fromAlignment: fromAlignment,
          toAlignment: toAlignment,
          nodeCenterOffset: nodeCenterOffset,
        ),
      ),
    );
  }
}

class _PathCurvePainter extends CustomPainter {
  final bool isUnlocked;
  final Color solidColor;
  final Color dashedColor;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;
  final PathNodeAlignment fromAlignment;
  final PathNodeAlignment toAlignment;
  final double nodeCenterOffset;

  _PathCurvePainter({
    required this.isUnlocked,
    required this.solidColor,
    required this.dashedColor,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashGap,
    required this.fromAlignment,
    required this.toAlignment,
    required this.nodeCenterOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    double startX;
    switch (fromAlignment) {
      case PathNodeAlignment.left:
        startX = nodeCenterOffset.clamp(0.0, size.width / 2);
        break;
      case PathNodeAlignment.right:
        startX = size.width - nodeCenterOffset.clamp(0.0, size.width / 2);
        break;
      case PathNodeAlignment.center:
        startX = size.width / 2;
        break;
    }

    double endX;
    switch (toAlignment) {
      case PathNodeAlignment.left:
        endX = nodeCenterOffset.clamp(0.0, size.width / 2);
        break;
      case PathNodeAlignment.right:
        endX = size.width - nodeCenterOffset.clamp(0.0, size.width / 2);
        break;
      case PathNodeAlignment.center:
        endX = size.width / 2;
        break;
    }

    final startPoint = Offset(startX, 0);
    final endPoint = Offset(endX, size.height);

    final path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);

    if ((startX - endX).abs() < 2.0) {
      // Straight vertical line
      path.lineTo(endPoint.dx, endPoint.dy);
    } else {
      // Smooth S-curve (cubic bezier)
      final midY = size.height * 0.5;
      path.cubicTo(
        startX, midY,
        endX, midY,
        endPoint.dx, endPoint.dy,
      );
    }

    if (isUnlocked) {
      // 1. Soft wide pastel ribbon road
      final ribbonPaint = Paint()
        ..color = solidColor
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, ribbonPaint);

      // 2. White dashed centerline running through the middle of the ribbon
      final centerDashPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = (strokeWidth * 0.25).clamp(2.5, 4.0)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (final metric in path.computeMetrics()) {
        double distance = 4.0;
        while (distance < metric.length - 4.0) {
          final double nextDistance =
              (distance + dashLength).clamp(0.0, metric.length - 2.0);
          final extractPath = metric.extractPath(distance, nextDistance);
          canvas.drawPath(extractPath, centerDashPaint);
          distance += dashLength + dashGap;
        }
      }
    } else {
      // Dashed path line for locked segments
      final dashPaint = Paint()
        ..color = dashedColor
        ..strokeWidth = strokeWidth * 0.75
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (final metric in path.computeMetrics()) {
        double distance = 0.0;
        while (distance < metric.length) {
          final double nextDistance =
              (distance + dashLength).clamp(0.0, metric.length);
          final extractPath = metric.extractPath(distance, nextDistance);
          canvas.drawPath(extractPath, dashPaint);
          distance += dashLength + dashGap;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathCurvePainter oldDelegate) {
    return oldDelegate.isUnlocked != isUnlocked ||
        oldDelegate.solidColor != solidColor ||
        oldDelegate.dashedColor != dashedColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.dashGap != dashGap ||
        oldDelegate.fromAlignment != fromAlignment ||
        oldDelegate.toAlignment != toAlignment ||
        oldDelegate.nodeCenterOffset != nodeCenterOffset;
  }
}
