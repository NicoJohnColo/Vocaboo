import 'package:flutter/material.dart';

/// Seamless directional question-to-question transition widget for Modules 1 - 4.
/// Animates the incoming question from the right (+0.20 -> 0.0) and outgoing to the left (0.0 -> -0.20)
/// with physics-based spring deceleration and zero flicker.
class AppQuestionTransition extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final StackFit fit;

  const AppQuestionTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 280),
    this.fit = StackFit.loose,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: const Cubic(0.16, 1.0, 0.3, 1.0),
      switchOutCurve: const Cubic(0.16, 1.0, 0.3, 1.0),
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          fit: fit,
          alignment: Alignment.topCenter,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (childWidget, animation) {
        final isEntering = childWidget.key == child.key;

        final inOffset = Tween<Offset>(
          begin: const Offset(0.25, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.16, 1.0, 0.3, 1.0),
        ));

        final outOffset = Tween<Offset>(
          begin: const Offset(-0.25, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.16, 1.0, 0.3, 1.0),
        ));

        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        );

        return SlideTransition(
          position: isEntering ? inOffset : outOffset,
          child: FadeTransition(
            opacity: fade,
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }
}
