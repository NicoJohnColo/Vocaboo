import 'package:flutter/material.dart';

/// A widget that renders a Cebuano sentence with the target/focus word underlined and bolded.
class CebuanoTextHighlighter extends StatelessWidget {
  final String text;
  final String? highlightWord;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final TextAlign textAlign;
  final TextOverflow overflow;
  final int? maxLines;
  final bool enableUnderline;

  const CebuanoTextHighlighter({
    super.key,
    required this.text,
    this.highlightWord,
    this.style,
    this.highlightStyle,
    this.textAlign = TextAlign.start,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    this.enableUnderline = true,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ??
        const TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
          height: 1.4,
        );

    final targetHighlightStyle = highlightStyle ??
        baseStyle.copyWith(
          decoration: enableUnderline ? TextDecoration.underline : TextDecoration.none,
          decorationThickness: 2,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
          decorationColor: const Color(0xFF06A6FF),
        );

    final cleanHighlight = highlightWord?.trim().toLowerCase();
    if (cleanHighlight == null || cleanHighlight.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
      );
    }

    // Try finding the highlight word as a whole word or substring
    final regex = RegExp(r'\b' + RegExp.escape(cleanHighlight) + r'\b', caseSensitive: false);
    final match = regex.firstMatch(text);

    if (match == null) {
      // Fallback: search without word boundary if not found
      final simpleIdx = text.toLowerCase().indexOf(cleanHighlight);
      if (simpleIdx == -1) {
        return Text(
          text,
          style: baseStyle,
          textAlign: textAlign,
          overflow: overflow,
          maxLines: maxLines,
        );
      }
      final before = text.substring(0, simpleIdx);
      final matchedText = text.substring(simpleIdx, simpleIdx + cleanHighlight.length);
      final after = text.substring(simpleIdx + cleanHighlight.length);

      return RichText(
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
        text: TextSpan(
          children: [
            if (before.isNotEmpty) TextSpan(text: before, style: baseStyle),
            TextSpan(text: matchedText, style: targetHighlightStyle),
            if (after.isNotEmpty) TextSpan(text: after, style: baseStyle),
          ],
        ),
      );
    }

    final before = text.substring(0, match.start);
    final matchedText = text.substring(match.start, match.end);
    final after = text.substring(match.end);

    return RichText(
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      text: TextSpan(
        children: [
          if (before.isNotEmpty) TextSpan(text: before, style: baseStyle),
          TextSpan(text: matchedText, style: targetHighlightStyle),
          if (after.isNotEmpty) TextSpan(text: after, style: baseStyle),
        ],
      ),
    );
  }
}
