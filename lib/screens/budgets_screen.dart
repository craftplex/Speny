import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/app_models.dart';
import '../theme/neo_glass_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_components.dart';

class BudgetsScreen extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onDataChanged;

  const BudgetsScreen({
    super.key,
    required this.scrollController,
    required this.onDataChanged,
  });

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final _budgetController = TextEditingController();
  final _billTitleController = TextEditingController();
  final _billAmountController = TextEditingController();

  double _monthlyBudget = 50000;
  List<Expense> _expenses = [];
  List<RecurringBill> _recurringBills = [];
  List<CategoryModel> _categories = [];
  int? _selectedBillCategoryId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _billTitleController.dispose();
    _billAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final monthKey = Formatters.getMonthKey(DateTime.now());
    final results = await Future.wait([
      DatabaseHelper.instance.getMonthlyBudget(monthKey),
      DatabaseHelper.instance.getAllExpenses(),
      DatabaseHelper.instance.getAllRecurringBills(),
      DatabaseHelper.instance.getAllCategories(),
    ]);

    if (!mounted) return;
    final expenses = results[1] as List<Expense>;
    setState(() {
      _monthlyBudget = results[0] as double;
      _budgetController.text = _monthlyBudget.toStringAsFixed(0);
      _expenses = expenses;
      _recurringBills = results[2] as List<RecurringBill>;
      _categories = results[3] as List<CategoryModel>;
      _selectedBillCategoryId ??=
          _categories.isEmpty ? null : _categories.first.id;
      _isLoading = false;
    });
  }

  Future<void> _saveBudget() async {
    final amount = double.tryParse(_budgetController.text.trim());
    if (amount == null || amount <= 0) {
      _showMessage('Enter a budget amount greater than zero.');
      return;
    }

    await DatabaseHelper.instance.setMonthlyBudget(
      Formatters.getMonthKey(DateTime.now()),
      amount,
    );
    if (!mounted) return;
    widget.onDataChanged();
    _showMessage('Monthly budget updated.');
  }

  Future<void> _addRecurringBill() async {
    final title = _billTitleController.text.trim();
    final amount = double.tryParse(_billAmountController.text.trim());
    if (title.isEmpty || amount == null || amount <= 0) {
      _showMessage('Add a bill name and a valid amount.');
      return;
    }
    if (_selectedBillCategoryId == null) {
      _showMessage('Add a category before creating a recurring bill.');
      return;
    }

    await DatabaseHelper.instance.insertRecurringBill(
      RecurringBill(
        title: title,
        amount: amount,
        categoryId: _selectedBillCategoryId!,
        dayOfMonth: 1,
      ),
    );
    if (!mounted) return;
    _billTitleController.clear();
    _billAmountController.clear();
    await _loadData();
    widget.onDataChanged();
  }

  Future<void> _deleteBill(RecurringBill bill) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove recurring bill?'),
        content: Text('Remove ${bill.title} from your recurring list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || bill.id == null) return;

    await DatabaseHelper.instance.deleteRecurringBill(bill.id!);
    if (!mounted) return;
    await _loadData();
    widget.onDataChanged();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final spent = _expenses
        .where((expense) =>
            expense.dateTime.year == now.year &&
            expense.dateTime.month == now.month)
        .fold(0.0, (total, expense) => total + expense.amount);
    final remaining =
        (_monthlyBudget - spent).clamp(0.0, _monthlyBudget).toDouble();
    final progress =
        _monthlyBudget > 0
            ? (spent / _monthlyBudget).clamp(0.0, 1.0).toDouble()
            : 0.0;
    final recurringTotal = _recurringBills.fold(
      0.0,
      (total, bill) =>
          total + (bill.frequency == 'Yearly' ? bill.amount / 12 : bill.amount),
    );

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
                      const PageHeading(
                        title: 'Your budget',
                        subtitle: 'A plan for the month, not a restriction.',
                      ),
                      _BudgetOverview(
                        spent: spent,
                        budget: _monthlyBudget,
                        remaining: remaining,
                        progress: progress,
                      ),
                      const SizedBox(height: 24),
                      const SectionHeading(title: 'Monthly spending limit'),
                      NeoContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Set a comfortable limit for this month.',
                              style: TextStyle(
                                color: AppColors.subText,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _budgetController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Monthly budget',
                                      suffixText: 'TK',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                FilledButton(
                                  onPressed: _saveBudget,
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SectionHeading(
                        title: 'Recurring bills',
                        actionLabel: '${_recurringBills.length} active',
                      ),
                      NeoContainer(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accentLightPurple,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.autorenew_rounded,
                                    color: AppColors.primaryPurple,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Expected each month',
                                    style: TextStyle(
                                      color: AppColors.darkText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  Formatters.formatMoney(recurringTotal,
                                      short: true),
                                  style: const TextStyle(
                                    color: AppColors.darkText,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Divider(height: 1),
                            ),
                            if (_recurringBills.isEmpty)
                              const EmptyState(
                                icon: Icons.event_repeat_rounded,
                                title: 'Nothing recurring yet',
                                message:
                                    'Add subscriptions or bills to keep them in view.',
                              )
                            else
                              for (final bill in _recurringBills)
                                _BillTile(
                                  bill: bill,
                                  onDelete: () => _deleteBill(bill),
                                ),
                            const SizedBox(height: 12),
                            _AddBillForm(
                              titleController: _billTitleController,
                              amountController: _billAmountController,
                              categories: _categories,
                              selectedCategoryId: _selectedBillCategoryId,
                              onCategoryChanged: (value) => setState(
                                  () => _selectedBillCategoryId = value),
                              onAdd: _addRecurringBill,
                            ),
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

class _BudgetOverview extends StatelessWidget {
  final double spent;
  final double budget;
  final double remaining;
  final double progress;

  const _BudgetOverview({
    required this.spent,
    required this.budget,
    required this.remaining,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final overBudget = spent > budget;
    return NeoContainer(
      padding: const EdgeInsets.all(20),
      backgroundColor: const Color(0xFFEAF6EF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'LEFT THIS MONTH',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
              Icon(
                overBudget ? Icons.warning_amber_rounded : Icons.spa_rounded,
                color: overBudget ? AppColors.red : AppColors.green,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            Formatters.formatMoney(remaining),
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white,
              color: overBudget ? AppColors.red : AppColors.green,
            ),
          ),
          const SizedBox(height: 11),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${Formatters.formatMoney(spent, short: true)} spent',
                style: const TextStyle(
                  color: AppColors.subText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'of ${Formatters.formatMoney(budget, short: true)}',
                style: const TextStyle(
                  color: AppColors.subText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddBillForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController amountController;
  final List<CategoryModel> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategoryChanged;
  final VoidCallback onAdd;

  const _AddBillForm({
    required this.titleController,
    required this.amountController,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Add a bill',
            style: TextStyle(
              color: AppColors.darkText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 11),
        TextField(
          controller: titleController,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Bill or subscription',
            prefixIcon: Icon(Icons.receipt_long_rounded),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'TK ',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(
                          category.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onCategoryChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add recurring bill'),
          ),
        ),
      ],
    );
  }
}

class _BillTile extends StatelessWidget {
  final RecurringBill bill;
  final VoidCallback onDelete;

  const _BillTile({required this.bill, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.subText,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.title,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  bill.categoryName ?? bill.frequency,
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.formatMoney(bill.amount, short: true),
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Remove bill',
            icon: const Icon(Icons.close_rounded, size: 19),
            color: AppColors.subText,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
