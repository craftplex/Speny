import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'screens/home_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/budgets_screen.dart';
import 'screens/ai_advisory_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/neo_glass_theme.dart';
import 'widgets/floating_pill_nav_bar.dart';

void main() {
  runApp(const SpenyApp());
}

class SpenyApp extends StatelessWidget {
  const SpenyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speny',
      debugShowCheckedModeBanner: false,
      theme: NeoGlassTheme.theme,
      home: const MainNavigationWrapper(),
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;
  bool _isNavBarVisible = true;

  final ScrollController _homeScrollController = ScrollController();
  final ScrollController _budgetsScrollController = ScrollController();
  final ScrollController _aiScrollController = ScrollController();
  final ScrollController _settingsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _homeScrollController.addListener(() => _handleScroll(_homeScrollController));
    _budgetsScrollController.addListener(() => _handleScroll(_budgetsScrollController));
    _aiScrollController.addListener(() => _handleScroll(_aiScrollController));
    _settingsScrollController.addListener(() => _handleScroll(_settingsScrollController));
  }

  void _handleScroll(ScrollController controller) {
    if (controller.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isNavBarVisible) {
        setState(() => _isNavBarVisible = false);
      }
    } else if (controller.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isNavBarVisible) {
        setState(() => _isNavBarVisible = true);
      }
    }
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    _budgetsScrollController.dispose();
    _aiScrollController.dispose();
    _settingsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(scrollController: _homeScrollController),
      NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse && _isNavBarVisible) {
            setState(() => _isNavBarVisible = false);
          } else if (notification.direction == ScrollDirection.forward && !_isNavBarVisible) {
            setState(() => _isNavBarVisible = true);
          }
          return true;
        },
        child: const ReportsScreen(),
      ),
      BudgetsScreen(scrollController: _budgetsScrollController),
      AiAdvisoryScreen(scrollController: _aiScrollController),
      SettingsScreen(scrollController: _settingsScrollController),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: screens,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingPillNavBar(
              selectedIndex: _selectedIndex,
              isVisible: _isNavBarVisible,
              onItemTapped: (index) {
                setState(() {
                  _selectedIndex = index;
                  _isNavBarVisible = true;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
