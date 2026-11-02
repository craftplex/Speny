import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/app_models.dart';
import '../services/reports_engine.dart';
import '../theme/neo_glass_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_components.dart';

class HomeScreen extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onAddExpense;
  final VoidCallback onOpenInsights;
  final VoidCallback onSeeAll;
  final ValueChanged<Expense> onEditExpense;

  const HomeScreen({
    super.key,
    required this.scrollController,
    required this.onAddExpense,
    required this.onOpenInsights,
    required this.onSeeAll,
    required this.onEditExpense,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Expense> _expenses = [];
  List<CategoryModel> _categories = [];
  double _monthlyBudget = 50000.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final expenses = await DatabaseHelper.instance.getAllExpenses();
    final categories = await DatabaseHelper.instance.getAllCategories();
    final budget = await DatabaseHelper.instance
        .getMonthlyBudget(Formatters.getMonthKey(DateTime.now()));

    if (!mounted) return;
    setState(() {
      _expenses = expenses;
      _categories = categories;
      _monthlyBudget = budget;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthExpenses = _expenses
        .where((expense) =>
            expense.dateTime.year == now.year &&
            expense.dateTime.month == now.month)
        .toList();
    final totalSpent =
        monthExpenses.fold(0.0, (total, expense) => total + expense.amount);
    final remaining =
        (_monthlyBudget - totalSpent).clamp(0.0, _monthlyBudget).toDouble();
    final budgetProgress = _monthlyBudget > 0
        ? (totalSpent / _monthlyBudget).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final health = ReportsEngine.calculateFinancialHealthScoreAndInsights(
      monthlyBudget: _monthlyBudget,
      monthExpenses: monthExpenses,
      categories: _categories,
    );
    final greeting = switch (now.hour) {
      < 12 => 'Good morning,',
      < 17 => 'Good afternoon,',
      _ => 'Good evening,',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primaryPurple,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  controller: widget.scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 124),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageHeading(
                        title: greeting,
                        subtitle: DateFormatLabel.monthDay(now),
                        trailing: Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.accentLightPurple,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            'S',
                            style: TextStyle(
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ),
                      _MonthlyOverview(
                        totalSpent: totalSpent,
                        budget: _monthlyBudget,
                        remaining: remaining,
                        progress: budgetProgress,
                      ),
                      const SizedBox(height: 22),
                      _InsightPreview(
                        score: health['score'] as int,
                        rating: health['rating'] as String,
                        onTap: widget.onOpenInsights,
                      ),
                      const SizedBox(height: 25),
                      SectionHeading(
                        title: 'Recent activity',
                        actionLabel: 'See all',
                        onAction: widget.onSeeAll,
                      ),
                      NeoContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: _expenses.isEmpty
                            ? const EmptyState(
                                icon: Icons.receipt_long_rounded,
                                title: 'Start with your first expense',
                                message:
                                    'A quick note is all it takes to see where your money goes.',
                              )
                            : Column(
                                children: [
                                  for (final expense in _expenses.take(5))
                                    TransactionTile(
                                      expense: expense,
                                      onTap: () =>
                                          widget.onEditExpense(expense),
                                    ),
                                ],
                              ),
                      ),
                      if (_expenses.isEmpty) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: widget.onAddExpense,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add your first expense'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _MonthlyOverview extends StatelessWidget {
  final double totalSpent;
  final double budget;
  final double remaining;
  final double progress;

  const _MonthlyOverview({
    required this.totalSpent,
    required this.budget,
    required this.remaining,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'TOTAL SPENT THIS MONTH',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormatLabel.currentMonth(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            Formatters.formatMoney(totalSpent),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF8DE6B7)),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _OverviewAmount(
                  label: 'MONTHLY BUDGET',
                  value: Formatters.formatMoney(budget, short: true),
                ),
              ),
              Expanded(
                child: _OverviewAmount(
                  label: 'LEFT TO SPEND',
                  value: Formatters.formatMoney(remaining, short: true),
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewAmount extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _OverviewAmount({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InsightPreview extends StatelessWidget {
  final int score;
  final String rating;
  final VoidCallback onTap;

  const _InsightPreview({
    required this.score,
    required this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeoContainer(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.accentLightPurple,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primaryPurple,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your money check-in',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$rating · see your insights',
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$score',
            style: const TextStyle(
              color: AppColors.primaryPurple,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.chevron_right_rounded, color: AppColors.subText),
        ],
      ),
    );
  }
}

class DateFormatLabel {
  static String monthDay(DateTime date) =>
      '${_monthNames[date.month - 1]} ${date.day}';

  static String currentMonth(DateTime date) => _monthNames[date.month - 1];

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
}
