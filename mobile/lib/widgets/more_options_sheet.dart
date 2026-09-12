import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/motion/typography_tokens.dart';
import '../providers/auth_provider.dart';
import '../providers/lesson_provider.dart';
import '../services/local_storage_service.dart';
import '../services/localization_service.dart';
import '../screens/phonics_vowels_screen.dart';
import 'app_3d_button.dart';

class MoreOptionsSheet extends StatelessWidget {
  const MoreOptionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.65,
      ),
      builder: (ctx) => const MoreOptionsSheet(),
    );
  }

  void _showChangePinModal(BuildContext context, AuthProvider auth, String? pref) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _ChangePinDialog(auth: auth, pref: pref),
    );
  }

  void _showResetConfirmDialog(BuildContext context, AuthProvider auth, String? pref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          LocalizationService.translate(pref, 'confirm_reset_title'),
          style: AppTypography.baloo2(fontWeight: FontWeight.w800, color: const Color(0xFFEF4444)),
        ),
        content: Text(
          LocalizationService.translate(pref, 'confirm_reset_body'),
          style: AppTypography.nunito(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              LocalizationService.translate(pref, 'cancel'),
              style: AppTypography.baloo2(fontWeight: FontWeight.w700),
            ),
          ),
          App3DButton(
            text: LocalizationService.translate(pref, 'confirm'),
            variant: App3DButtonVariant.danger,
            height: 42.0,
            depth: 3.5,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            borderRadius: 12,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();
              try {
                await Provider.of<LessonProvider>(context, listen: false).resetProgress();
                await LocalStorageService.clearAllLessonData();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(LocalizationService.translate(pref, 'progress_reset')),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Failed to reset progress. Please try again.'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth, String? pref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          LocalizationService.translate(pref, 'logout_title'),
          style: AppTypography.baloo2(fontWeight: FontWeight.w800, color: const Color(0xFFEF4444)),
        ),
        content: Text(
          LocalizationService.translate(pref, 'logout_confirm_body'),
          style: AppTypography.nunito(fontSize: 14, color: const Color(0xFF64748B)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: App3DButton(
                  text: LocalizationService.translate(pref, 'cancel'),
                  variant: App3DButtonVariant.secondary,
                  height: 44.0,
                  depth: 3.5,
                  borderRadius: 14,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: App3DButton(
                  text: LocalizationService.translate(pref, 'logout'),
                  variant: App3DButtonVariant.danger,
                  height: 44.0,
                  depth: 3.5,
                  borderRadius: 14,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    auth.logout();
                    context.go('/welcome');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pref = auth.learner?.languagePreference;
    final langName = pref == 'CEBUANO_TO_ENGLISH' ? 'Bisaya' : 'English';
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.65;

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxSheetHeight,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x260F172A),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LocalizationService.translate(pref, 'more_options'),
                    style: AppTypography.baloo2(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF06A6FF),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Scrollable options list
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 1. LEARNING & PROGRESS ──────────────────────────
                    _sectionHeader('LEARNING & PROGRESS'),
                    _optionCard(
                      context: context,
                      icon: Icons.volume_up_rounded,
                      iconColor: const Color(0xFF0284C7),
                      iconBg: const Color(0xFFE0F2FE),
                      title: LocalizationService.translate(pref, 'sound_title'),
                      subtitle: LocalizationService.translate(pref, 'sound_sub_desc'),
                      onTap: () {
                        final nav = Navigator.of(context);
                        nav.pop();
                        nav.push(
                          MaterialPageRoute(
                            builder: (_) => const PhonicsVowelsScreen(),
                          ),
                        );
                      },
                    ),
                    _optionCard(
                      context: context,
                      icon: Icons.analytics_rounded,
                      iconColor: const Color(0xFF0284C7),
                      iconBg: const Color(0xFFE0F2FE),
                      title: LocalizationService.translate(pref, 'full_progress_title'),
                      subtitle: LocalizationService.translate(pref, 'full_progress_sub_desc'),
                      onTap: () {
                        Navigator.of(context).pop();
                        GoRouter.of(context).push('/progress');
                      },
                    ),
                    _optionCard(
                      context: context,
                      icon: Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFF2563EB),
                      iconBg: const Color(0xFFEFF6FF),
                      title: LocalizationService.translate(pref, 'word_practice_title'),
                      subtitle: LocalizationService.translate(pref, 'word_practice_sub_desc'),
                      onTap: () {
                        Navigator.of(context).pop();
                        GoRouter.of(context).push('/wrong-answers');
                      },
                    ),

                    const SizedBox(height: 10),

                    // ── 2. PREFERENCES & SETTINGS ────────────────────────
                    _sectionHeader('PREFERENCES & SETTINGS'),
                    _optionCard(
                      context: context,
                      icon: Icons.language_rounded,
                      iconColor: const Color(0xFF16A34A),
                      iconBg: const Color(0xFFDCFCE7),
                      title: LocalizationService.translate(pref, 'language_preference'),
                      subtitle: 'Choose your app language',
                      trailingPill: langName,
                      trailingPillColor: const Color(0xFFDCFCE7),
                      trailingPillTextColor: const Color(0xFF16A34A),
                      onTap: () {
                        Navigator.of(context).pop();
                        GoRouter.of(context).push('/language-preference');
                      },
                    ),
                    _optionCard(
                      context: context,
                      icon: Icons.lock_outline_rounded,
                      iconColor: const Color(0xFFEA580C),
                      iconBg: const Color(0xFFFFEDD5),
                      title: LocalizationService.translate(pref, 'change_pin'),
                      subtitle: 'Update your 4-digit security PIN',
                      onTap: () => _showChangePinModal(context, auth, pref),
                    ),

                    const SizedBox(height: 10),

                    // ── 3. RESET PROGRESS ────────────────────────────────
                    _sectionHeader('RESET PROGRESS'),
                    _optionCard(
                      context: context,
                      icon: Icons.restart_alt_rounded,
                      iconColor: const Color(0xFFEF4444),
                      iconBg: const Color(0xFFFEE2E2),
                      title: LocalizationService.translate(pref, 'reset_progress'),
                      subtitle: 'Clear all lesson completion and reset scores',
                      onTap: () => _showResetConfirmDialog(context, auth, pref),
                    ),

                    const SizedBox(height: 16),

                    // ── Prominent Red Logout Button ───────────────────────
                    ElevatedButton.icon(
                      onPressed: () => _showLogoutDialog(context, auth, pref),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(
                        LocalizationService.translate(pref, 'logout'),
                        style: AppTypography.baloo2(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6, left: 4),
      child: Text(
        title,
        style: AppTypography.baloo2(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF64748B),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _optionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    String? trailingPill,
    Color? trailingPillColor,
    Color? trailingPillTextColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.baloo2(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTypography.nunito(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailingPill != null) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: trailingPillColor ?? const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      trailingPill,
                      style: AppTypography.baloo2(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: trailingPillTextColor ?? const Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ],
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── SCREEN 7: CHANGE PIN MODAL OVERLAY ───────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────

class _ChangePinDialog extends StatefulWidget {
  final AuthProvider auth;
  final String? pref;

  const _ChangePinDialog({
    required this.auth,
    required this.pref,
  });

  @override
  State<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<_ChangePinDialog> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await widget.auth.changePin(
      _currentPinController.text.trim(),
      _newPinController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocalizationService.translate(widget.pref, 'pin_changed')),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.auth.error ?? 'Error changing PIN'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      LocalizationService.translate(widget.pref, 'change_pin'),
                      style: AppTypography.baloo2(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Update your 4-digit security PIN',
                      style: AppTypography.nunito(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 1. Current PIN Field
                    _buildPinInput(
                      label: 'Current PIN',
                      controller: _currentPinController,
                      obscureText: _obscureCurrent,
                      onToggleVisibility: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    const SizedBox(height: 12),

                    // 2. New PIN Field
                    _buildPinInput(
                      label: 'New PIN',
                      controller: _newPinController,
                      obscureText: _obscureNew,
                      onToggleVisibility: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                    const SizedBox(height: 12),

                    // 3. Confirm New PIN Field
                    _buildPinInput(
                      label: 'Confirm New PIN',
                      controller: _confirmPinController,
                      obscureText: _obscureConfirm,
                      onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (v) {
                        if (v == null || v.length != 4) return 'Enter 4 digits';
                        if (v != _newPinController.text) return 'PINs do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Helper Info Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Make sure it's something you'll remember!",
                              style: AppTypography.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Action Buttons (Cancel / Save Changes)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Cancel',
                              style: AppTypography.baloo2(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _isLoading ? null : _handleSave,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'Save Changes',
                                    style: AppTypography.baloo2(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top Floating Blue Lock Icon Badge
          Positioned(
            top: -24,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.lock_rounded, color: Color(0xFF2563EB), size: 24),
            ),
          ),

          // Close 'X' Button Top Right
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinInput({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.baloo2(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: TextInputType.number,
            maxLength: 4,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: const Color(0xFF94A3B8),
                ),
                onPressed: onToggleVisibility,
              ),
              counterText: '${controller.text.length}/4',
              counterStyle: AppTypography.nunito(fontSize: 10.5, color: const Color(0xFF94A3B8)),
              border: InputBorder.none,
            ),
            validator: validator ??
                (v) {
                  if (v == null || v.length != 4) return 'Enter 4 digits';
                  return null;
                },
          ),
        ),
      ],
    );
  }
}
