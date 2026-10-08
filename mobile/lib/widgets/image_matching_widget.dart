import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../services/tts_service.dart';
import 'custom_image_viewer.dart';

class ImageMatchingWidget extends StatelessWidget {
  final PracticeItemModel item;
  final List<String> options;
  final int selectedIndex;
  final void Function(int)? onSelect;

  const ImageMatchingWidget({
    super.key,
    required this.item,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = item.imageAssetPath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Match the image to the correct word:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        if (imagePath != null && imagePath.isNotEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: CustomImageViewer(
                imagePath: imagePath,
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => const SizedBox.shrink(),
              ),
            ),
          ),
        const SizedBox(height: 18),
        const Text('Choose the correct English word:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        ...List.generate(options.length, (index) {
          final option = options[index];
          final isSelected = selectedIndex == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GestureDetector(
              onTap: onSelect != null ? () => onSelect!(index) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? const Color(0xFF06A6FF) : const Color(0xFFE2E8F0), width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 16,
                          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                          decoration: isSelected ? TextDecoration.underline : TextDecoration.none,
                          decorationColor: const Color(0xFF0284C7),
                          decorationThickness: 2.0,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => TTSService.speakEnglish(option),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.volume_up_rounded,
                            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        })
      ],
    );
  }
}
