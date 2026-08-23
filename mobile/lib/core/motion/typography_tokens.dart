import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'motion_tokens.dart';

/// Centralized Typography Design Tokens for Vocaboo
/// Designed specifically for children aged 9-12:
/// - Display / Headers / Celebrations: [Fredoka] (friendly, rounded, expressive, engaging).
/// - Body / Instructions / Content: [Nunito] (rounded, high legibility, distinct glyphs for l/1/I and 0/O).
class AppTypography {
  AppTypography._();

  // ──────────────────────────────────────────────────────────────────────────
  // Font Family Names
  // ──────────────────────────────────────────────────────────────────────────
  static const String displayFontFamily = 'Fredoka';
  static const String bodyFontFamily = 'Nunito';

  static bool get _isTesting {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding');
    } catch (_) {
      return false;
    }
  }

  static TextStyle _font(String family, TextStyle style) {
    if (_isTesting) {
      return style.copyWith(fontFamily: family);
    }
    try {
      if (family == displayFontFamily) {
        return GoogleFonts.fredoka(textStyle: style);
      }
      return GoogleFonts.nunito(textStyle: style);
    } catch (_) {
      return style.copyWith(fontFamily: family);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Display / Heading Styles (Fredoka)
  // ──────────────────────────────────────────────────────────────────────────
  static TextStyle get displayLarge => _font(
        displayFontFamily,
        const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
          letterSpacing: -0.5,
        ),
      );

  static TextStyle get displayMedium => _font(
        displayFontFamily,
        const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
          letterSpacing: -0.3,
        ),
      );

  static TextStyle get titleLarge => _font(
        displayFontFamily,
        const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
      );

  static TextStyle get titleMedium => _font(
        displayFontFamily,
        const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
      );

  // ──────────────────────────────────────────────────────────────────────────
  // Celebratory / Reward Styles (Fredoka)
  // ──────────────────────────────────────────────────────────────────────────
  static TextStyle get celebratory => _font(
        displayFontFamily,
        const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFF16A34A),
          letterSpacing: 0.2,
        ),
      );

  static TextStyle get badgeLabel => _font(
        displayFontFamily,
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );

  // ──────────────────────────────────────────────────────────────────────────
  // Body / Instruction Styles (Nunito - High Legibility for 9-12 Learners)
  // ──────────────────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => _font(
        bodyFontFamily,
        const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
          height: 1.45,
        ),
      );

  static TextStyle get bodyMedium => _font(
        bodyFontFamily,
        const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF475569),
          height: 1.4,
        ),
      );

  static TextStyle get bodyBold => _font(
        bodyFontFamily,
        const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      );

  static TextStyle get caption => _font(
        bodyFontFamily,
        const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      );

  static TextStyle get button => _font(
        displayFontFamily,
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );

  // ──────────────────────────────────────────────────────────────────────────
  // App Theme Builder
  // ──────────────────────────────────────────────────────────────────────────
  static TextTheme createTextTheme([Color textColor = const Color(0xFF0F172A)]) {
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: textColor),
      displayMedium: displayMedium.copyWith(color: textColor),
      headlineMedium: titleLarge.copyWith(color: textColor),
      titleLarge: titleLarge.copyWith(color: textColor),
      titleMedium: titleMedium.copyWith(color: textColor),
      bodyLarge: bodyLarge.copyWith(color: textColor),
      bodyMedium: bodyMedium.copyWith(color: textColor),
      bodySmall: caption.copyWith(color: textColor),
      labelLarge: button,
    );
  }
}

/// An animated number counter that smoothly transitions from an old value
/// to a new value with an easing curve (ideal for points, XP, streaks, accuracy).
class AppAnimatedCounter extends StatefulWidget {
  final num value;
  final TextStyle? style;
  final Duration? duration;
  final Curve? curve;
  final String prefix;
  final String suffix;
  final int fractionDigits;

  const AppAnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration,
    this.curve,
    this.prefix = '',
    this.suffix = '',
    this.fractionDigits = 0,
  });

  @override
  State<AppAnimatedCounter> createState() => _AppAnimatedCounterState();
}

class _AppAnimatedCounterState extends State<AppAnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldValue = 0;

  @override
  void initState() {
    super.initState();
    _oldValue = widget.value.toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? AppDurations.emphasized,
    );
    _animation = Tween<double>(begin: _oldValue, end: _oldValue).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve ?? AppCurves.emphasizedDecelerate,
      ),
    );
  }

  @override
  void didUpdateWidget(AppAnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (AppMotion.isReducedMotion(context)) {
        _oldValue = widget.value.toDouble();
        return;
      }
      _oldValue = _animation.value;
      _controller.duration = widget.duration ?? AppDurations.emphasized;
      _animation = Tween<double>(
        begin: _oldValue,
        end: widget.value.toDouble(),
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: widget.curve ?? AppCurves.emphasizedDecelerate,
        ),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.isReducedMotion(context)) {
      final formatted = widget.fractionDigits > 0
          ? widget.value.toStringAsFixed(widget.fractionDigits)
          : widget.value.round().toString();
      return Text(
        '${widget.prefix}$formatted${widget.suffix}',
        style: widget.style ?? AppTypography.displayMedium,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final formatted = widget.fractionDigits > 0
            ? _animation.value.toStringAsFixed(widget.fractionDigits)
            : _animation.value.round().toString();
        return Text(
          '${widget.prefix}$formatted${widget.suffix}',
          style: widget.style ?? AppTypography.displayMedium,
        );
      },
    );
  }
}
