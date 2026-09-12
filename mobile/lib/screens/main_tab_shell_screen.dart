import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/class_provider.dart';
import '../widgets/app_3d_bottom_nav_bar.dart';
import '../widgets/more_options_sheet.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'learner_classes_screen.dart';
import 'user_dashboard_screen.dart';

class MainTabShellScreen extends StatefulWidget {
  final int initialTab;

  const MainTabShellScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<MainTabShellScreen> createState() => _MainTabShellScreenState();
}

class _MainTabShellScreenState extends State<MainTabShellScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final PageController _pageController;
  int _currentTab = 0;
  bool _isMoreOptionsOpen = false;
  PersistentBottomSheetController? _sheetController;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab.clamp(0, 3);
    _pageController = PageController(initialPage: _currentTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final classProvider = Provider.of<ClassProvider>(context, listen: false);
      if (auth.token != null) {
        classProvider.fetchInvitations(auth.token);
      }
    });
  }

  @override
  void didUpdateWidget(covariant MainTabShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab && widget.initialTab != _currentTab) {
      final target = widget.initialTab.clamp(0, 3);
      setState(() => _currentTab = target);
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          target,
          duration: const Duration(milliseconds: 320),
          curve: const Cubic(0.16, 1.0, 0.3, 1.0),
        );
      }
    }
  }

  @override
  void dispose() {
    _sheetController?.close();
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (index == 4) {
      if (_isMoreOptionsOpen) {
        _sheetController?.close();
        return;
      }
      setState(() => _isMoreOptionsOpen = true);
      _sheetController = _scaffoldKey.currentState?.showBottomSheet(
        backgroundColor: Colors.transparent,
        (ctx) => const MoreOptionsSheet(),
      );
      _sheetController?.closed.then((_) {
        if (mounted) {
          setState(() {
            _isMoreOptionsOpen = false;
            _sheetController = null;
          });
        }
      });
      return;
    }

    if (_isMoreOptionsOpen) {
      _sheetController?.close();
    }

    if (index == _currentTab) return;

    setState(() => _currentTab = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
    );
  }

  String _getCurrentPath() {
    switch (_currentTab) {
      case 0:
        return '/home';
      case 1:
        return '/leaderboard';
      case 2:
        return '/classes';
      case 3:
        return '/dashboard';
      default:
        return '/home';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (page) {
          if (_isMoreOptionsOpen) {
            _sheetController?.close();
          }
          setState(() => _currentTab = page);
        },
        children: const [
          HomeScreen(isInsideShell: true),
          LeaderboardScreen(isInsideShell: true),
          LearnerClassesScreen(),
          UserDashboardScreen(isInsideShell: true),
        ],
      ),
      bottomNavigationBar: App3DBottomNavBar(
        currentPath: _isMoreOptionsOpen ? '/settings' : _getCurrentPath(),
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
