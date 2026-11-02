import 'package:flutter/material.dart';
import 'models/app_models.dart';
import 'screens/add_edit_expense_screen.dart';
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
  int _dataVersion = 0;
  final ScrollController _homeScrollController = ScrollController();
  final ScrollController _budgetsScrollController = ScrollController();
  final ScrollController _aiScrollController = ScrollController();
  final ScrollController _settingsScrollController = ScrollController();

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
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(
            key: ValueKey('home-$_dataVersion'),
            scrollController: _homeScrollController,
            onAddExpense: _addExpense,
            onOpenInsights: () => setState(() => _selectedIndex = 3),
            onSeeAll: () => setState(() => _selectedIndex = 1),
            onEditExpense: (expense) => _addExpense(expense),
          ),
          ReportsScreen(key: ValueKey('reports-$_dataVersion')),
          BudgetsScreen(
            key: ValueKey('budgets-$_dataVersion'),
            scrollController: _budgetsScrollController,
            onDataChanged: _refreshData,
          ),
          AiAdvisoryScreen(
            key: ValueKey('insights-$_dataVersion'),
            scrollController: _aiScrollController,
          ),
          SettingsScreen(
            key: ValueKey('settings-$_dataVersion'),
            scrollController: _settingsScrollController,
            onDataChanged: _refreshData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add expense'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: FloatingPillNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  void _refreshData() {
    if (mounted) setState(() => _dataVersion++);
  }

  Future<void> _addExpense([Expense? expense]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddEditExpenseScreen(expense: expense)),
    );
    if (saved == true) _refreshData();
  }
}
