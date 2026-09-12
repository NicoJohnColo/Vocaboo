import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_3d_bottom_nav_bar.dart';

class MainAppScaffold extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const MainAppScaffold({
    super.key,
    required this.child,
    required this.currentPath,
  });

  void _onTabSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        if (currentPath != '/home') {
          context.go('/home');
        }
        break;
      case 1:
        if (currentPath != '/leaderboard') {
          context.go('/leaderboard');
        }
        break;
      case 2:
        if (currentPath != '/dashboard') {
          context.go('/dashboard');
        }
        break;
      case 3:
        if (currentPath != '/settings') {
          context.go('/settings');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: child,
      bottomNavigationBar: App3DBottomNavBar(
        currentPath: currentPath,
        onTabSelected: (index) => _onTabSelected(context, index),
      ),
    );
  }
}
