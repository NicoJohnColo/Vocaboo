import 'package:flutter/material.dart';

/// A widget that renders a sentence with the target/focus word cleanly highlighted and underlined.
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

  static List<String> extractCleanTargetWords(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    
    // Strip markdown bold/italic, quotes, brackets
    String cleaned = raw
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('`', '')
        .trim();

    // Remove leading POS annotations like (Noun), (v.), [Adj]
    cleaned = cleaned.replaceAll(RegExp(r'^\s*[\(\[][a-zA-Z\s\.\,\/]+[\)\]]\s*'), '');

    // Split on slash or comma for alternative forms (e.g. "kaon / mokaon" -> ["kaon", "mokaon"])
    final parts = cleaned.split(RegExp(r'[/,;]'));
    final results = <String>[];

    for (var part in parts) {
      part = part.replaceAll(RegExp(r'^\s*[\(\[][a-zA-Z\s\.\,\/]+[\)\]]\s*'), '').trim();
      if (part.isNotEmpty && part.length >= 2) {
        results.add(part);
      }
    }

    if (results.isEmpty && cleaned.isNotEmpty) {
      results.add(cleaned);
    }
    return results;
  }

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
          decorationThickness: 2.5,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF0369A1),
          decorationColor: const Color(0xFF0284C7),
        );

    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    // 1. If text explicitly contains markdown bold **target**, highlight those tokens directly
    if (text.contains('**')) {
      final parts = text.split('**');
      final spans = <InlineSpan>[];
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].isEmpty) continue;
        if (i % 2 == 1) {
          // Odd indices were inside **...**
          spans.add(TextSpan(text: parts[i], style: targetHighlightStyle));
        } else {
          spans.add(TextSpan(text: parts[i], style: baseStyle));
        }
      }
      return RichText(
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
        text: TextSpan(children: spans),
      );
    }

    // 2. Otherwise, extract target words from highlightWord
    final targetWords = extractCleanTargetWords(highlightWord);
    if (targetWords.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
      );
    }

    // Build regex pattern matching any of the target words with word boundaries
    final pattern = targetWords
        .map((w) => RegExp.escape(w))
        .join('|');
    final regex = RegExp(r'\b(' + pattern + r')\b', caseSensitive: false);

    final matches = regex.allMatches(text).toList();

    if (matches.isEmpty) {
      // Fallback: search substring match if word boundary failed (e.g., hyphenated or affixes like mo-kaon, nag-kaon)
      for (final target in targetWords) {
        final simpleIdx = text.toLowerCase().indexOf(target.toLowerCase());
        if (simpleIdx != -1) {
          final before = text.substring(0, simpleIdx);
          final matchedText = text.substring(simpleIdx, simpleIdx + target.length);
          final after = text.substring(simpleIdx + target.length);

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

      return Text(
        text,
        style: baseStyle,
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
      );
    }

    final spans = <InlineSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start), style: baseStyle));
      }
      spans.add(TextSpan(text: text.substring(match.start, match.end), style: targetHighlightStyle));
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex), style: baseStyle));
    }

    return RichText(
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      text: TextSpan(children: spans),
    );
  }
}
