import 'package:flutter/material.dart';
import '../motion_tokens.dart';

/// An animated input text field with smooth focus glow, label float,
/// and animated error message slide-reveal.
class AppAnimatedTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? errorText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  const AppAnimatedTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.focusNode,
  });

  @override
  State<AppAnimatedTextField> createState() => _AppAnimatedTextFieldState();
}

class _AppAnimatedTextFieldState extends State<AppAnimatedTextField> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final borderColor = hasError
        ? const Color(0xFFEF4444)
        : (_isFocused ? primaryColor : const Color(0xFFE2E8F0));

    final glowColor = hasError
        ? const Color(0xFFEF4444).withValues(alpha: 0.15)
        : (_isFocused ? primaryColor.withValues(alpha: 0.15) : Colors.transparent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label with color transition
        AnimatedDefaultTextStyle(
          duration: AppDurations.short,
          curve: AppCurves.emphasizedDecelerate,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hasError
                ? const Color(0xFFEF4444)
                : (_isFocused ? primaryColor : const Color(0xFF475569)),
          ),
          child: Text(widget.label),
        ),
        const SizedBox(height: 6),

        // Input Container with animated border & focus glow
        AnimatedContainer(
          duration: AppDurations.short,
          curve: AppCurves.emphasizedDecelerate,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: _isFocused || hasError ? 2.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor,
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: TextField(
            focusNode: _focusNode,
            controller: widget.controller,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: Color(0xFF94A3B8),
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
          ),
        ),

        // Error message reveal animation
        AnimatedSize(
          duration: AppDurations.short,
          curve: AppCurves.emphasizedDecelerate,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 6.0, left: 4.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 14,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.errorText!,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
