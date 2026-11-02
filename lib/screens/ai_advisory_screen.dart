import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/app_models.dart';
import '../services/reports_engine.dart';
import '../theme/neo_glass_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_components.dart';

class AiAdvisoryScreen extends StatefulWidget {
  final ScrollController scrollController;

  const AiAdvisoryScreen({super.key, required this.scrollController});

  @override
  State<AiAdvisoryScreen> createState() => _AiAdvisoryScreenState();
}

class _AiAdvisoryScreenState extends State<AiAdvisoryScreen> {
  final _simAmountController = TextEditingController();

  List<Expense> _expenses = [];
  List<CategoryModel> _categories = [];
  double _monthlyBudget = 50000;
  bool _isLoading = true;
  Map<String, dynamic>? _simulationResult;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _simAmountController.dispose();
    super.dispose();
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
      _simulationResult = null;
    });
  }

  void _runSimulation() {
    final cost = double.tryParse(_simAmountController.text.trim());
    if (cost == null || cost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a purchase amount greater than zero.')),
      );
      return;
    }

    final now = DateTime.now();
    final monthExpenses = _expenses
        .where((expense) =>
            expense.dateTime.year == now.year &&
            expense.dateTime.month == now.month)
        .toList();
    setState(() {
      _simulationResult = ReportsEngine.simulatePurchase(
        itemCost: cost,
        currentBudget: _monthlyBudget,
        monthExpenses: monthExpenses,
        categories: _categories,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final now = DateTime.now();
    final monthExpenses = _expenses
        .where((expense) =>
            expense.dateTime.year == now.year &&
            expense.dateTime.month == now.month)
        .toList();
    final healthData = ReportsEngine.calculateFinancialHealthScoreAndInsights(
      monthlyBudget: _monthlyBudget,
      monthExpenses: monthExpenses,
      categories: _categories,
    );
    final score = healthData['score'] as int;
    final rating = healthData['rating'] as String;
    final insights = healthData['insights'] as List<SmartInsight>;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primaryPurple,
          child: SingleChildScrollView(
            controller: widget.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 124),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHeading(
                  title: 'Money check-in',
                  subtitle: 'Simple signals to help you stay on track.',
                ),
                GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$score',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FINANCIAL HEALTH',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.9,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rating,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Based on this month’s activity',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                const SectionHeading(title: 'Spending insights'),
                if (insights.isEmpty)
                  const NeoContainer(
                    child: EmptyState(
                      icon: Icons.lightbulb_outline_rounded,
                      title: 'No insights just yet',
                      message:
                          'Add a few expenses to see patterns and helpful reminders.',
                    ),
                  )
                else
                  for (final insight in insights)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NeoContainer(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: insight.type == 'warning'
                                    ? const Color(0xFFFFF1DF)
                                    : AppColors.accentLightPurple,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                insight.type == 'warning'
                                    ? Icons.info_outline_rounded
                                    : Icons.lightbulb_outline_rounded,
                                color: insight.type == 'warning'
                                    ? AppColors.orange
                                    : AppColors.primaryPurple,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    insight.title,
                                    style: const TextStyle(
                                      color: AppColors.darkText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    insight.message,
                                    style: const TextStyle(
                                      color: AppColors.subText,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 18),
                const SectionHeading(title: 'Before you buy'),
                NeoContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Try a purchase amount',
                        style: TextStyle(
                          color: AppColors.darkText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'See how it could affect your remaining monthly budget.',
                        style: TextStyle(
                          color: AppColors.subText,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _simAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Purchase amount',
                          prefixText: 'TK ',
                        ),
                        onSubmitted: (_) => _runSimulation(),
                      ),
                      const SizedBox(height: 11),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _runSimulation,
                          icon: const Icon(Icons.calculate_outlined),
                          label: const Text('Estimate impact'),
                        ),
                      ),
                      if (_simulationResult != null) ...[
                        const SizedBox(height: 15),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.accentLightPurple,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (_simulationResult!['willExceedBudget'] as bool)
                                    ? 'This may exceed your monthly budget.'
                                    : 'This appears to fit within your budget.',
                                style: const TextStyle(
                                  color: AppColors.darkText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Estimated remaining: ${Formatters.formatMoney(_simulationResult!['remainingBudgetAfterPurchase'] as double)}',
                                style: const TextStyle(
                                  color: AppColors.subText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
