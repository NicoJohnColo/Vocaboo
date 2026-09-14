import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/motion/typography_tokens.dart';
import 'app_3d_button.dart';

/// A Duolingo-style speech bubble popover card that animates near a tapped lesson node.
/// Shows category name, dynamic word count, description, and a "Start" action button.
class LessonPopoverCard extends StatefulWidget {
  final String categoryName;
  final int totalWordCount;
  final String description;
  final String buttonText;
  final VoidCallback onStart;
  final VoidCallback? onDismiss;
  final String? className;
  final Color backgroundColor;
  final bool isTailOnLeft;
  final double width;
  final double? score;
  final int? masteredCount;

  const LessonPopoverCard({
    super.key,
    required this.categoryName,
    required this.totalWordCount,
    required this.description,
    this.buttonText = 'Start',
    required this.onStart,
    this.onDismiss,
    this.className,
    this.backgroundColor = const Color(0xFF0EA5E9), // Primary Sky Blue
    this.isTailOnLeft = true,
    this.width = 220.0,
    this.score,
    this.masteredCount,
  });

  @override
  State<LessonPopoverCard> createState() => _LessonPopoverCardState();
}

class _LessonPopoverCardState extends State<LessonPopoverCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void dismiss({VoidCallback? onComplete}) {
    _animController.reverse().then((_) {
      if (mounted) {
        onComplete?.call();
        widget.onDismiss?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const tailSize = 10.0;
    final paddingLeft = widget.isTailOnLeft ? tailSize + 14.0 : 14.0;
    final paddingRight = widget.isTailOnLeft ? 14.0 : tailSize + 14.0;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            alignment: widget.isTailOnLeft
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: child,
          ),
        );
      },
      child: CustomPaint(
        painter: _SpeechBubblePainter(
          color: widget.backgroundColor,
          radius: 18.0,
          tailSize: tailSize,
          isTailOnLeft: widget.isTailOnLeft,
          tailYPercent: 0.28,
        ),
        child: Container(
          width: widget.width,
          padding: EdgeInsets.fromLTRB(paddingLeft, 14.0, paddingRight, 14.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row: Category & Word count on left, notebook icon on right
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.categoryName}, ${widget.totalWordCount} ${widget.totalWordCount == 1 ? 'word' : 'words'}',
                          style: AppTypography.baloo2(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.score != null && widget.score! > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.analytics_rounded,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Accuracy: ${widget.score!.toStringAsFixed(0)}% • ${widget.masteredCount ?? 0}/${widget.totalWordCount} Mastered',
                                    style: AppTypography.nunito(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (widget.className != null &&
                            widget.className!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.school_rounded,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    widget.className!,
                                    style: AppTypography.nunito(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 5),
                        Text(
                          widget.description.isNotEmpty
                              ? widget.description
                              : '${widget.categoryName}-themed learning, strong, and full of energy.',
                          style: AppTypography.nunito(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Divider & Notebook Icon
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 1.0,
                        height: 38,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Start button (chunky 3D white button with bottom edge)
              App3DButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onStart();
                },
                text: widget.buttonText,
                customBaseColor: Colors.white,
                customDepthColor: Colors.white.withValues(alpha: 0.5),
                customTextColor: widget.backgroundColor,
                height: 42.0,
                depth: 3.5,
                borderRadius: 20,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeechBubblePainter extends CustomPainter {
  final Color color;
  final double radius;
  final double tailSize;
  final bool isTailOnLeft;
  final double tailYPercent;

  _SpeechBubblePainter({
    required this.color,
    required this.radius,
    required this.tailSize,
    required this.isTailOnLeft,
    required this.tailYPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final double left = isTailOnLeft ? tailSize : 0.0;
    final double right = isTailOnLeft ? size.width : size.width - tailSize;
    const double top = 0.0;
    final double bottom = size.height;
    final double r = radius;

    // Top-left
    path.moveTo(left + r, top);
    // Top line
    path.lineTo(right - r, top);
    // Top-right corner
    path.arcToPoint(Offset(right, top + r), radius: Radius.circular(r));

    if (!isTailOnLeft) {
      // Right tail
      final double tailCenterY = size.height * tailYPercent;
      path.lineTo(right, (tailCenterY - tailSize).clamp(top + r, bottom - r));
      path.lineTo(size.width, tailCenterY.clamp(top + r, bottom - r));
      path.lineTo(right, (tailCenterY + tailSize).clamp(top + r, bottom - r));
    }

    // Right line
    path.lineTo(right, bottom - r);
    // Bottom-right corner
    path.arcToPoint(Offset(right - r, bottom), radius: Radius.circular(r));

    // Bottom line
    path.lineTo(left + r, bottom);
    // Bottom-left corner
    path.arcToPoint(Offset(left, bottom - r), radius: Radius.circular(r));

    if (isTailOnLeft) {
      // Left tail
      final double tailCenterY = size.height * tailYPercent;
      path.lineTo(left, (tailCenterY + tailSize).clamp(top + r, bottom - r));
      path.lineTo(0, tailCenterY.clamp(top + r, bottom - r));
      path.lineTo(left, (tailCenterY - tailSize).clamp(top + r, bottom - r));
    }

    // Left line
    path.lineTo(left, top + r);
    // Top-left corner close
    path.arcToPoint(Offset(left + r, top), radius: Radius.circular(r));
    path.close();

    // Soft drop shadow
    canvas.drawShadow(path, color.withValues(alpha: 0.4), 12.0, false);

    // Fill bubble body
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.tailSize != tailSize ||
        oldDelegate.isTailOnLeft != isTailOnLeft ||
        oldDelegate.tailYPercent != tailYPercent;
  }
}
