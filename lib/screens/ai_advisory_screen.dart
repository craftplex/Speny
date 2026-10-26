import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/app_models.dart';
import '../services/reports_engine.dart';
import '../theme/neo_glass_theme.dart';
import '../utils/formatters.dart';

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
  double _monthlyBudget = 50000.0;
  bool _isLoading = true;

  Map<String, dynamic>? _simulationResult;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final expenses = await DatabaseHelper.instance.getAllExpenses();
    final categories = await DatabaseHelper.instance.getAllCategories();
    final monthKey = Formatters.getMonthKey(DateTime.now());
    final budget = await DatabaseHelper.instance.getMonthlyBudget(monthKey);

    setState(() {
      _expenses = expenses;
      _categories = categories;
      _monthlyBudget = budget;
      _isLoading = false;
    });
  }

  void _runSimulation() {
    final cost = double.tryParse(_simAmountController.text.trim());
    if (cost == null || cost <= 0) return;

    final result = ReportsEngine.simulatePurchase(
      itemCost: cost,
      currentBudget: _monthlyBudget,
      monthExpenses: _expenses,
      categories: _categories,
    );

    setState(() {
      _simulationResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final healthData = ReportsEngine.calculateFinancialHealthScoreAndInsights(
      monthlyBudget: _monthlyBudget,
      monthExpenses: _expenses,
      categories: _categories,
    );

    final score = healthData['score'] as int;
    final rating = healthData['rating'] as String;
    final List<SmartInsight> insights = healthData['insights'] as List<SmartInsight>;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('AI Insights & What-If Simulator', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Banner Glassmorphic Card
            GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$score',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Financial Health Score', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(
                        rating,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const Text('Updated live in-device AI', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text('Smart Insights & AI Advisory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
            const SizedBox(height: 12),

            ...insights.map((insight) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: AppColors.shadowDark, blurRadius: 6, offset: Offset(2, 2))],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      insight.type == 'warning' ? Icons.warning_amber_rounded : Icons.lightbulb_rounded,
                      color: insight.type == 'warning' ? Colors.orange : AppColors.primaryPurple,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(insight.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(insight.message, style: const TextStyle(color: AppColors.subText, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // What-If Simulator Box
            NeoContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("What-If Simulator", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
                  const SizedBox(height: 8),
                  const Text("Simulate a purchase (e.g. 10,000 TK gadget) before buying to predict score drops or budget shortages.", style: TextStyle(color: AppColors.subText, fontSize: 12)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _simAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Simulate Item Price (TK)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                      onPressed: _runSimulation,
                      child: const Text('Simulate Impact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (_simulationResult != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentLightPurple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Simulated Score: ${_simulationResult!['simulatedScore']} (Drop: -${_simulationResult!['scoreDrop']} pts)', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Will Exceed Budget: ${_simulationResult!['willExceedBudget'] ? "YES ⚠️" : "NO ✅"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Remaining Budget After: ${Formatters.formatMoney(_simulationResult!['remainingBudgetAfterPurchase'] as double)}'),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
