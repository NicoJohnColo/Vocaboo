import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_avatars.dart';
import '../core/motion/motion.dart';
import '../providers/auth_provider.dart';
import '../services/localization_service.dart';

class AppAvatar extends StatelessWidget {
  final String? avatar;
  final String? name;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final Color? backgroundColor;
  final bool showEditBadge;
  final bool showShadow;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    this.avatar,
    this.name,
    this.size = 48,
    this.borderColor,
    this.borderWidth = 0,
    this.backgroundColor,
    this.showEditBadge = false,
    this.showShadow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name ?? '';
    final avatarPath = AppAvatars.getAssetPath(avatar, seed: displayName);
    final initials = AppAvatars.getInitials(displayName);
    final fallbackColor = AppAvatars.getColor(displayName);

    Widget avatarWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Colors.white,
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ?? const Color(0xFFE2E8F0),
                width: borderWidth,
              )
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: (borderColor ?? Colors.black).withValues(alpha: 0.12),
                  blurRadius: size * 0.12,
                  offset: Offset(0, size * 0.04),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Image.asset(
          avatarPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: fallbackColor,
              alignment: Alignment.center,
              child: Text(
                initials,
                style: AppTypography.baloo2(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),
    );

    if (showEditBadge) {
      final badgeSize = (size * 0.30).clamp(24.0, 36.0);
      avatarWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarWidget,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0EA5E9),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: badgeSize * 0.55,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return AppPressable(
        onTap: onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }
}

class AvatarPickerSheet extends StatefulWidget {
  final String initialAvatar;
  final ValueChanged<String>? onSelected;
  final bool autoSaveToAuth;

  const AvatarPickerSheet({
    super.key,
    required this.initialAvatar,
    this.onSelected,
    this.autoSaveToAuth = false,
  });

  /// Shows the bottom sheet modal. Returns chosen avatar String if confirmed, or null if dismissed.
  static Future<String?> show(
    BuildContext context, {
    String? currentAvatar,
    ValueChanged<String>? onSelected,
    bool autoSaveToAuth = true,
  }) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final initial = currentAvatar ?? auth.learner?.avatar ?? AppAvatars.defaultAvatar;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AvatarPickerSheet(
        initialAvatar: initial,
        onSelected: onSelected,
        autoSaveToAuth: autoSaveToAuth,
      ),
    );
  }

  @override
  State<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<AvatarPickerSheet> {
  late String _selectedAvatar;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedAvatar = AppAvatars.normalize(widget.initialAvatar);
  }

  void _randomize() {
    setState(() {
      _selectedAvatar = AppAvatars.getRandomAvatar();
    });
  }

  Future<void> _confirmSelection() async {
    widget.onSelected?.call(_selectedAvatar);

    if (widget.autoSaveToAuth) {
      setState(() => _isSaving = true);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated) {
        await auth.updateAvatar(_selectedAvatar);
      }
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }

    if (mounted) {
      Navigator.of(context).pop(_selectedAvatar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pref = auth.learner?.languagePreference;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocalizationService.translate(pref, 'choose_avatar'),
                          style: AppTypography.baloo2(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          LocalizationService.translate(pref, 'choose_avatar_desc'),
                          style: AppTypography.nunito(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppPressable(
                    onTap: _randomize,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🎲', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            LocalizationService.translate(pref, 'randomize'),
                            style: AppTypography.baloo2(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Active Avatar Preview Card
            Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  AppAvatar(
                    avatar: _selectedAvatar,
                    size: 64,
                    borderColor: const Color(0xFF0EA5E9),
                    borderWidth: 2.5,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SELECTED AVATAR',
                          style: AppTypography.baloo2(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppAvatars.getLabel(_selectedAvatar),
                          style: AppTypography.baloo2(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF0EA5E9),
                    size: 28,
                  ),
                ],
              ),
            ),

            // Avatars Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.82,
                ),
                itemCount: AppAvatars.allAvatars.length,
                itemBuilder: (context, index) {
                  final avatarPath = AppAvatars.allAvatars[index];
                  final label = AppAvatars.getLabel(avatarPath);
                  final isSelected = _selectedAvatar == avatarPath;

                  return AppPressable(
                    onTap: () => setState(() => _selectedAvatar = avatarPath),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0),
                          width: isSelected ? 2.5 : 1.0,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              AppAvatar(
                                avatar: avatarPath,
                                size: 48,
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
                                      size: 12,
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
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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

            // Confirm Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: App3DButton(
                text: LocalizationService.translate(pref, 'save_avatar'),
                variant: App3DButtonVariant.primary,
                height: 52,
                isLoading: _isSaving,
                onPressed: _confirmSelection,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
