import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/motion/motion.dart';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';
import '../widgets/mascot_bubble.dart';

class LanguagePreferenceScreen extends StatefulWidget {
  final Map<String, dynamic>? learnerData;

  const LanguagePreferenceScreen({super.key, this.learnerData});

  @override
  State<LanguagePreferenceScreen> createState() =>
      _LanguagePreferenceScreenState();
}

class _LanguagePreferenceScreenState extends State<LanguagePreferenceScreen> {
  String _selectedOption = 'CEBUANO_TO_ENGLISH';

  bool get _isSettingsMode => widget.learnerData == null;

  @override
  void initState() {
    super.initState();
    if (_isSettingsMode) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      _selectedOption =
          auth.learner?.languagePreference ?? 'CEBUANO_TO_ENGLISH';
    }
  }

  Future<void> _submit() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (_isSettingsMode) {
      final success = await auth.updateLanguagePreference(_selectedOption);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService.translate(
                auth.learner?.languagePreference,
                'profile_updated',
              ),
            ),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(auth.error ?? 'Error')));
      }
    } else {
      final success = await auth.register(
        widget.learnerData!['displayName'],
        widget.learnerData!['age'],
        widget.learnerData!['pin'],
        _selectedOption,
        gradeLevel: widget.learnerData!['gradeLevel'],
      );
      if (success && mounted) {
        context.go('/avatar-selection');
      }
    }
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedOption == value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: AppGameCard(
        status: isSelected ? AppCardStatus.selected : AppCardStatus.normal,
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: () => setState(() => _selectedOption = value),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.nunito(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
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
    final auth = Provider.of<AuthProvider>(context);
    final pref = _isSettingsMode ? auth.learner?.languagePreference : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: _isSettingsMode
            ? Text(
                LocalizationService.translate(pref, 'language_preference'),
                style: AppTypography.baloo2(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: const Color(0xFF06A6FF),
                ),
              )
            : const App3DProgressBar(value: 0.80, height: 18.0),
        actions: const [SizedBox(width: 48)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isSettingsMode) ...[
                const SizedBox(height: 8),
                const MascotBubble(
                  mascotName: 'sippy',
                  speechText:
                      "Hi! I'm Sippy! Which language do you prefer for buttons and menus?",
                ),
                const SizedBox(height: 28),
              ] else ...[
                const SizedBox(height: 8),
              ],

              if (auth.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF4444)),
                  ),
                  child: Text(
                    auth.error!,
                    style: AppTypography.nunito(
                      color: const Color(0xFFB91C1C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildOptionCard(
                      title: LocalizationService.translate(
                        pref,
                        'cebuano_to_english',
                      ),
                      subtitle: LocalizationService.translate(
                        pref,
                        'cebuano_to_english_subtitle',
                      ),
                      value: 'CEBUANO_TO_ENGLISH',
                      icon: Icons.language_rounded,
                    ),
                    _buildOptionCard(
                      title: LocalizationService.translate(
                        pref,
                        'full_english',
                      ),
                      subtitle: LocalizationService.translate(
                        pref,
                        'full_english_subtitle',
                      ),
                      value: 'FULL_ENGLISH',
                      icon: Icons.abc_rounded,
                    ),
                    _buildOptionCard(
                      title: LocalizationService.translate(
                        pref,
                        'cebuano_english_mixed',
                      ),
                      subtitle: LocalizationService.translate(
                        pref,
                        'cebuano_english_mixed_subtitle',
                      ),
                      value: 'CEBUANO_ENGLISH_MIXED',
                      icon: Icons.translate_rounded,
                    ),
                  ],
                ),
              ),

              App3DButton(
                text: _isSettingsMode
                    ? LocalizationService.translate(pref, 'save_changes')
                    : 'NEXT',
                variant: App3DButtonVariant.primary,
                height: 54,
                isLoading: auth.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
