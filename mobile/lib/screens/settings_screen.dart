import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/localization_service.dart';
import '../widgets/mascot_visual.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showEditProfileDialog(BuildContext context, AuthProvider auth, String? pref) {
    final nameController = TextEditingController(text: auth.learner?.displayName ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          LocalizationService.translate(pref, 'edit_profile'),
          style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w800),
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
              final success = await auth.updateProfile(
                nameController.text.trim(),
                auth.learner?.age ?? 9,
              );
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              if (success) {
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
          style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w800),
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
          style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w800, color: Color(0xFFEF4444)),
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

  void _showPosFocusDialog(BuildContext context, AuthProvider auth, String? pref) {
    String currentFocus = auth.learner?.posFocus ?? 'ALL';

    final options = [
      {'key': 'ALL', 'label': 'All Words', 'icon': Icons.apps_rounded, 'color': const Color(0xFF0EA5E9)},
      {'key': 'NOUN', 'label': 'Nouns Only', 'icon': Icons.label_outline_rounded, 'color': const Color(0xFF8B5CF6)},
      {'key': 'VERB', 'label': 'Verbs Only', 'icon': Icons.bolt_rounded, 'color': const Color(0xFFF59E0B)},
      {'key': 'ADJECTIVE', 'label': 'Adjectives Only', 'icon': Icons.palette_outlined, 'color': const Color(0xFF10B981)},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Part of Speech Focus',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final key = opt['key'] as String;
            final isSelected = currentFocus == key;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? (opt['color'] as Color).withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? (opt['color'] as Color) : const Color(0xFFE2E8F0),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: Icon(opt['icon'] as IconData, color: opt['color'] as Color),
                title: Text(
                  opt['label'] as String,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                trailing: isSelected ? Icon(Icons.check_circle, color: opt['color'] as Color) : null,
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final success = await auth.updatePosFocus(key);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Part of speech focus saved to profile' : (auth.error ?? 'Error saving focus preference')),
                      ),
                    );
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF94A3B8),
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
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF0F172A),
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
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => GoRouter.of(context).pop(),
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
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE0F2FE),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const MascotVisual(type: MascotType.bibo, size: 86),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  learner?.displayName ?? '',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),

              // ACCOUNT section
              _sectionHeader(LocalizationService.translate(pref, 'account_section')),
              _settingsTile(
                icon: Icons.person_outline,
                title: LocalizationService.translate(pref, 'edit_profile'),
                subtitle: '${learner?.displayName ?? ''}, ${LocalizationService.translate(pref, 'age')} ${learner?.age ?? ''}',
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
                icon: Icons.category_outlined,
                title: 'Part of Speech Focus',
                subtitle: learner?.posFocus == 'NOUN'
                    ? 'Nouns only'
                    : learner?.posFocus == 'VERB'
                        ? 'Verbs only'
                        : learner?.posFocus == 'ADJECTIVE'
                            ? 'Adjectives only'
                            : 'All Words',
                onTap: () => _showPosFocusDialog(context, auth, pref),
              ),
              _settingsTile(
                icon: Icons.toggle_on_outlined,
                title: LocalizationService.translate(pref, 'apply_immediately'),
                subtitle: LocalizationService.translate(pref, 'apply_immediately_desc'),
                trailing: Switch(
                  value: learner?.masteryApplyImmediately ?? true,
                  onChanged: (val) async {
                    final messenger = ScaffoldMessenger.of(context);
                    final success = await auth.updateMasteryApplyMode(val);
                    if (!success) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(auth.error ?? 'Error updating preference')),
                      );
                    }
                  },
                  activeThumbColor: const Color(0xFF0EA5E9),
                ),
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
                onTap: () => GoRouter.of(context).push('/sandbox'),
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
    );
  }
}
