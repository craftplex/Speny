import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/app_models.dart';
import '../theme/neo_glass_theme.dart';
import '../utils/formatters.dart';

class BudgetsScreen extends StatefulWidget {
  final ScrollController scrollController;

  const BudgetsScreen({super.key, required this.scrollController});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final _budgetController = TextEditingController();
  final _billTitleController = TextEditingController();
  final _billAmountController = TextEditingController();

  double _monthlyBudget = 50000.0;
  List<RecurringBill> _recurringBills = [];
  List<CategoryModel> _categories = [];
  int? _selectedBillCategoryId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final monthKey = Formatters.getMonthKey(DateTime.now());
    final budget = await DatabaseHelper.instance.getMonthlyBudget(monthKey);
    final bills = await DatabaseHelper.instance.getAllRecurringBills();
    final cats = await DatabaseHelper.instance.getAllCategories();

    setState(() {
      _monthlyBudget = budget;
      _budgetController.text = budget.toInt().toString();
      _recurringBills = bills;
      _categories = cats;
      if (_categories.isNotEmpty) _selectedBillCategoryId = _categories.first.id;
      _isLoading = false;
    });
  }

  Future<void> _updateBudget() async {
    final newLimit = double.tryParse(_budgetController.text.trim());
    if (newLimit == null || newLimit <= 0) return;

    final monthKey = Formatters.getMonthKey(DateTime.now());
    await DatabaseHelper.instance.setMonthlyBudget(monthKey, newLimit);
    _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monthly budget updated successfully!')),
      );
    }
  }

  Future<void> _addRecurringBill() async {
    final title = _billTitleController.text.trim();
    final amount = double.tryParse(_billAmountController.text.trim());

    if (title.isEmpty || amount == null || _selectedBillCategoryId == null) return;

    final bill = RecurringBill(
      title: title,
      amount: amount,
      categoryId: _selectedBillCategoryId!,
      dayOfMonth: 1,
    );

    await DatabaseHelper.instance.insertRecurringBill(bill);
    _billTitleController.clear();
    _billAmountController.clear();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Budgets & Recurring Bills', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly Overall Budget Card
            NeoContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Monthly Total Budget', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            suffixText: 'TK',
                            labelText: 'Budget Limit',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        onPressed: _updateBudget,
                        child: const Text('Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recurring Subscriptions & Bills
            NeoContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Recurring Bill / Subscription', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _billTitleController,
                    decoration: const InputDecoration(labelText: 'Bill Name (e.g. WiFi, Tuition)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _billAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount (TK)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                      onPressed: _addRecurringBill,
                      child: const Text('Add Recurring Bill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text('Active Subscriptions & Fixed Bills', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
            const SizedBox(height: 12),

            _recurringBills.isEmpty
                ? const Text('No recurring bills added yet.', style: TextStyle(color: AppColors.subText))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recurringBills.length,
                    itemBuilder: (context, index) {
                      final bill = _recurringBills[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(bill.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(Formatters.formatMoney(bill.amount, short: true), style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
