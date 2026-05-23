import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';

class ImageMatchingWidget extends StatelessWidget {
  final PracticeItemModel item;
  final List<String> options;
  final int selectedIndex;
  final void Function(int) onSelect;

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
              child: Image.asset(
                imagePath,
                width: 160,
                height: 160,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => SizedBox(
                  width: 160,
                  height: 160,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(child: Icon(Icons.broken_image, color: Color(0xFF94A3B8))),
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(child: Text('No image available', style: TextStyle(color: Color(0xFF94A3B8)))),
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
              onTap: () => onSelect(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? const Color(0xFF06A6FF) : const Color(0xFFE2E8F0), width: 1.5),
                ),
                child: Text(option, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          );
        })
      ],
    );
  }
}
