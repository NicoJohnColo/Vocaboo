import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/app_avatars.dart';
import '../core/motion/motion.dart';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';
import '../widgets/app_avatar.dart';
import '../widgets/mascot_bubble.dart';

class AvatarSelectionScreen extends StatefulWidget {
  const AvatarSelectionScreen({super.key});

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  late String _selectedAvatar;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _selectedAvatar = AppAvatars.normalize(
      auth.learner?.avatar,
      seed: auth.learner?.displayName,
    );
  }

  Future<void> _saveAndProceed() async {
    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.updateAvatar(_selectedAvatar);
    if (!mounted) return;
    setState(() => _isSaving = false);
    context.go('/success');
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final learner = auth.learner;
    final pref = learner?.languagePreference;
    final displayName = learner?.displayName ?? 'Learner';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                onPressed: () => context.pop(),
              )
            : const SizedBox(width: 48),
        title: const App3DProgressBar(value: 0.80, height: 18.0),
        actions: const [SizedBox(width: 48)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // Mascot Bubble
              MascotBubble(
                mascotName: 'starry',
                speechText:
                    "Awesome, $displayName! Now choose your favorite character for your profile picture!",
                isCelebrating: true,
                avatarSize: 84,
              ),
              const SizedBox(height: 16),

              // Large Selected Avatar Hero Preview
              Center(
                child: Column(
                  children: [
                    AppAvatar(
                      avatar: _selectedAvatar,
                      size: 80,
                      borderColor: const Color(0xFF0EA5E9),
                      borderWidth: 3.5,
                      showShadow: true,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: Text(
                        AppAvatars.getLabel(_selectedAvatar),
                        style: AppTypography.baloo2(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Text(
                LocalizationService.translate(pref, 'choose_avatar'),
                style: AppTypography.baloo2(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),

              // Avatars Grid
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: AppAvatars.allAvatars.length,
                  itemBuilder: (context, index) {
                    final avatarPath = AppAvatars.allAvatars[index];
                    final isSelected = _selectedAvatar == avatarPath;
                    final label = AppAvatars.getLabel(avatarPath);

                    return AppPressable(
                      onTap: () => setState(() => _selectedAvatar = avatarPath),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0EA5E9)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 2.5 : 1.2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF0EA5E9,
                                    ).withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.topRight,
                              children: [
                                AppAvatar(
                                  avatar: avatarPath,
                                  size: 52,
                                  showShadow: false,
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF0EA5E9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: AppTypography.nunito(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF0284C7)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Continue Button
              App3DButton(
                text: 'CONTINUE',
                variant: App3DButtonVariant.primary,
                height: 54,
                isLoading: _isSaving,
                onPressed: _saveAndProceed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
