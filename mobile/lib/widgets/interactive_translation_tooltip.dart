import 'package:flutter/material.dart';
import '../core/motion/typography_tokens.dart';

class InteractiveTranslationTooltip extends StatelessWidget {
  final String wordText;
  final String? translation;
  final Widget? child;
  final TextStyle? textStyle;

  const InteractiveTranslationTooltip({
    super.key,
    required this.wordText,
    this.translation,
    this.child,
    this.textStyle,
  });

  void _showTranslationDialog(BuildContext context) {
    final cleanWord = wordText.replaceAll(RegExp(r"[^\p{L}\p{N}\s']", unicode: true), '').trim();
    if (cleanWord.isEmpty) return;

    final displayTranslation = (translation != null && translation!.isNotEmpty)
        ? translation!
        : _lookupQuickTranslation(cleanWord);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.translate_rounded, color: Color(0xFF38BDF8), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cleanWord,
                      style: AppTypography.nunito(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayTranslation,
                      style: AppTypography.baloo2(
                        color: const Color(0xFF38BDF8),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _lookupQuickTranslation(String word) {
    final lower = word.toLowerCase();
    final dict = {
      'pencil': 'Lapis',
      'notebook': 'Kuwaderno',
      'eraser': 'Pamhid',
      'bag': 'Bag',
      'ruler': 'Ruler / Magmamando',
      'mother': 'Inahan',
      'father': 'Amahan',
      'sister': 'Igsoon nga babaye',
      'brother': 'Igsoon nga lalaki',
      'grandmother': 'Lola',
      'dog': 'Iro',
      'cat': 'Iring',
      'bird': 'Langgam',
      'fish': 'Isda',
      'horse': 'Kabayo',
      'rice': 'Kan-on',
      'bread': 'Pan',
      'milk': 'Gatas',
      'apple': 'Mansanas',
      'carry': 'Dala / Dalaon',
      'school': 'Eskwelahan',
      'my': 'Akon / Akong',
      'i': 'Ako',
      'lapis': 'Pencil',
      'kuwaderno': 'Notebook',
      'pamhid': 'Eraser',
      'inahan': 'Mother',
      'amahan': 'Father',
      'iro': 'Dog',
      'iring': 'Cat',
      'langgam': 'Bird',
      'isda': 'Fish',
      'kabayo': 'Horse',
      'kan-on': 'Rice',
      'pan': 'Bread',
      'gatas': 'Milk',
      'mansanas': 'Apple',
      'sharp': 'Hait',
      'hait': 'Sharp',
      'read': 'Basa',
      'basa': 'Read',
      'write': 'Sulat',
      'sulat': 'Write',
    };
    return dict[lower] ?? word;
  }

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showTranslationDialog(context),
        child: child,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showTranslationDialog(context),
      child: Text(
        wordText,
        style: textStyle ?? AppTypography.nunito(),
      ),
    );
  }
}
