import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/app_avatars.dart';
import '../core/motion/typography_tokens.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/localization_service.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_3d_bottom_nav_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _formatLanguagePreference(String? pref) {
    if (pref == 'CEBUANO_TO_ENGLISH') return 'Cebuano';
    if (pref == 'FULL_ENGLISH') return 'English';
    if (pref == 'CEBUANO_ENGLISH_MIXED') return 'Bislish (Mixed)';
    return pref ?? 'English';
  }

  String _formatGrade(String? grade) {
    if (grade == null || grade.isEmpty) return 'Grade 4';
    if (grade == 'GRADE_4') return 'Grade 4';
    if (grade == 'GRADE_5') return 'Grade 5';
    if (grade == 'GRADE_6') return 'Grade 6';
    return grade.replaceAll('_', ' ');
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider auth, String? pref) {
    final nameController = TextEditingController(text: auth.learner?.displayName ?? '');
    final ageController = TextEditingController(text: '${auth.learner?.age ?? 9}');
    String selectedGrade = auth.learner?.gradeLevel ?? 'GRADE_4';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            LocalizationService.translate(pref, 'edit_profile'),
            style: TextStyle(fontFamily: AppTypography.displayFontFamily, fontWeight: FontWeight.w800),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: LocalizationService.translate(pref, 'display_name'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return LocalizationService.translate(pref, 'name_empty');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: LocalizationService.translate(pref, 'age'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    final age = int.tryParse(v ?? '');
                    if (age == null || age < 9 || age > 12) {
                      return 'Age must be between 9 and 12';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedGrade,
                  decoration: InputDecoration(
                    labelText: 'Grade Level',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'GRADE_4', child: Text('Grade 4')),
                    DropdownMenuItem(value: 'GRADE_5', child: Text('Grade 5')),
                    DropdownMenuItem(value: 'GRADE_6', child: Text('Grade 6')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedGrade = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(LocalizationService.translate(pref, 'cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final age = int.parse(ageController.text.trim());
                final success = await auth.updateProfile(
                  nameController.text.trim(),
                  age,
                  gradeLevel: selectedGrade,
                );
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                if (success) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(LocalizationService.translate(pref, 'profile_updated'))),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(auth.error ?? 'Error')),
                  );
                }
              },
              child: Text(LocalizationService.translate(pref, 'save_changes')),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePinDialog(BuildContext context, AuthProvider auth, String? pref) {
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          LocalizationService.translate(pref, 'change_pin'),
          style: TextStyle(fontFamily: AppTypography.displayFontFamily, fontWeight: FontWeight.w800),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: LocalizationService.translate(pref, 'current_pin'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.length != 4) return LocalizationService.translate(pref, 'pin_wrong');
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: newPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: LocalizationService.translate(pref, 'new_pin'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.length != 4) return LocalizationService.translate(pref, 'pin_wrong');
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: confirmPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: LocalizationService.translate(pref, 'confirm_new_pin'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v != newPinController.text) {
                    return LocalizationService.translate(pref, 'pin_mismatch');
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(LocalizationService.translate(pref, 'cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final success = await auth.changePin(
                currentPinController.text.trim(),
                newPinController.text.trim(),
              );
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(LocalizationService.translate(pref, 'pin_changed'))),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(auth.error ?? 'Error')),
                );
              }
            },
            child: Text(LocalizationService.translate(pref, 'save_changes')),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmDialog(BuildContext context, AuthProvider auth, String? pref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          LocalizationService.translate(pref, 'confirm_reset_title'),
          style: TextStyle(fontFamily: AppTypography.displayFontFamily, fontWeight: FontWeight.w800, color: const Color(0xFFEF4444)),
        ),
        content: Text(LocalizationService.translate(pref, 'confirm_reset_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(LocalizationService.translate(pref, 'cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Provider.of<LessonProvider>(context, listen: false).resetProgress();
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              messenger.showSnackBar(
                SnackBar(content: Text(LocalizationService.translate(pref, 'progress_reset'))),
              );
            },
            child: Text(LocalizationService.translate(pref, 'confirm')),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppTypography.bodyFontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF94A3B8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0F172A), size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontFamily: AppTypography.displayFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: const Color(0xFF0F172A),
            ),
          ),
          subtitle: subtitle != null
              ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))
              : null,
          trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)) : null),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final learner = auth.learner;
    final pref = learner?.languagePreference;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          LocalizationService.translate(pref, 'settings'),
          style: TextStyle(
            fontFamily: AppTypography.displayFontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: const Color(0xFF06A6FF),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () {
            try {
              GoRouter.of(context).pop();
            } catch (e) {
              context.go('/home');
            }
          },
        ),
        actions: const [SizedBox(width: 12)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile header
              Center(
                child: AppAvatar(
                  avatar: learner?.avatar,
                  name: learner?.displayName,
                  size: 110,
                  borderWidth: 3.5,
                  borderColor: const Color(0xFF0EA5E9),
                  showEditBadge: true,
                  onTap: () async {
                    final chosen = await AvatarPickerSheet.show(context);
                    if (chosen != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(LocalizationService.translate(pref, 'avatar_updated')),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                learner?.displayName ?? 'Learner',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_formatGrade(learner?.gradeLevel)} • Age ${learner?.age ?? '-'} • ${_formatLanguagePreference(learner?.languagePreference)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),

              // ACCOUNT section
              _sectionHeader(LocalizationService.translate(pref, 'account_section')),
              _settingsTile(
                icon: Icons.face_rounded,
                title: LocalizationService.translate(pref, 'change_avatar'),
                subtitle: AppAvatars.getLabel(learner?.avatar),
                onTap: () async {
                  final chosen = await AvatarPickerSheet.show(context);
                  if (chosen != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(LocalizationService.translate(pref, 'avatar_updated')),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              _settingsTile(
                icon: Icons.person_outline,
                title: LocalizationService.translate(pref, 'edit_profile'),
                subtitle: '${learner?.displayName ?? ''}, ${_formatGrade(learner?.gradeLevel)}, ${LocalizationService.translate(pref, 'age')} ${learner?.age ?? ''}',
                onTap: () => _showEditProfileDialog(context, auth, pref),
              ),
              _settingsTile(
                icon: Icons.lock_outline,
                title: LocalizationService.translate(pref, 'change_pin'),
                onTap: () => _showChangePinDialog(context, auth, pref),
              ),

              // LEARNING section
              _sectionHeader(LocalizationService.translate(pref, 'learning_section')),
              _settingsTile(
                icon: Icons.language,
                title: LocalizationService.translate(pref, 'language_preference'),
                subtitle: pref != null ? LocalizationService.translate(pref, pref.toLowerCase()) : 'N/A',
                onTap: () => GoRouter.of(context).push('/language-preference'),
              ),
              _settingsTile(
                icon: Icons.bar_chart_rounded,
                title: LocalizationService.translate(pref, 'progress_summary'),
                subtitle: LocalizationService.translate(pref, 'progress_summary_desc'),
                onTap: () => GoRouter.of(context).push('/dashboard'),
              ),
              _settingsTile(
                icon: Icons.science_outlined,
                title: LocalizationService.translate(pref, 'sandbox_mode'),
                subtitle: LocalizationService.translate(pref, 'sandbox_mode_desc'),
                onTap: () => GoRouter.of(context).push(
                  '/loading',
                  extra: {
                    'duration': 5000,
                    'redirectPath': '/sandbox',
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Reset progress
              ElevatedButton(
                onPressed: () => _showResetConfirmDialog(context, auth, pref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  LocalizationService.translate(pref, 'reset_progress'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const App3DBottomNavBar(
        currentPath: '/settings',
      ),
    );
  }
}
