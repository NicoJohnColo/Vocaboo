import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../motion_tokens.dart';

class AppNavBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const AppNavBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

/// An animated bottom navigation bar with sliding pill indicator and icon bounce.
class AppAnimatedNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppNavBarItem> items;
  final Color activeColor;
  final Color inactiveColor;
  final Color backgroundColor;

  const AppAnimatedNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.activeColor = const Color(0xFF0EA5E9),
    this.inactiveColor = const Color(0xFF94A3B8),
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              return _NavBarItemWidget(
                item: item,
                isSelected: isSelected,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () {
                  if (!isSelected) {
                    HapticFeedback.selectionClick();
                    onTap(index);
                  }
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarItemWidget extends StatelessWidget {
  final AppNavBarItem item;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavBarItemWidget({
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.standard,
        curve: AppCurves.emphasizedDecelerate,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: AppDurations.short,
              curve: AppCurves.springBack,
              child: Icon(
                isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: AppDurations.short,
                curve: Curves.easeIn,
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: activeColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
