import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/motion/motion.dart';
import '../widgets/mascot_bubble.dart';

class GradeSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> learnerData;

  const GradeSelectionScreen({super.key, required this.learnerData});

  @override
  State<GradeSelectionScreen> createState() => _GradeSelectionScreenState();
}

class _GradeSelectionScreenState extends State<GradeSelectionScreen> {
  String _selectedGrade = 'GRADE_4';

  void _proceed() {
    context.push(
      '/pin-setup',
      extra: {
        'displayName': widget.learnerData['displayName'],
        'age': widget.learnerData['age'],
        'gradeLevel': _selectedGrade,
      },
    );
  }

  Widget _buildGradeCard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedGrade == value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: AppGameCard(
        status: isSelected ? AppCardStatus.selected : AppCardStatus.normal,
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        onTap: () => setState(() => _selectedGrade = value),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFBAE6FD)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected
                    ? const Color(0xFF0284C7)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.baloo2(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.nunito(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected
                  ? const Color(0xFF0EA5E9)
                  : const Color(0xFFCBD5E1),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
        title: const App3DProgressBar(value: 0.40, height: 18.0),
        actions: const [SizedBox(width: 48)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const MascotBubble(
                mascotName: 'bibo',
                speechText: "What grade are you in? Choose your grade level!",
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildGradeCard(
                      title: 'Grade 4',
                      subtitle: 'Elementary • Grade 4 Learner',
                      value: 'GRADE_4',
                      icon: Icons.looks_4_rounded,
                    ),
                    _buildGradeCard(
                      title: 'Grade 5',
                      subtitle: 'Elementary • Grade 5 Learner',
                      value: 'GRADE_5',
                      icon: Icons.looks_5_rounded,
                    ),
                    _buildGradeCard(
                      title: 'Grade 6',
                      subtitle: 'Elementary • Grade 6 Learner',
                      value: 'GRADE_6',
                      icon: Icons.looks_6_rounded,
                    ),
                  ],
                ),
              ),
              App3DButton(
                text: 'NEXT',
                variant: App3DButtonVariant.primary,
                height: 54,
                onPressed: _proceed,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
