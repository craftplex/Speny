import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/app_models.dart';
import '../theme/neo_glass_theme.dart';
import '../utils/formatters.dart';
import 'add_edit_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  final ScrollController scrollController;

  const HomeScreen({super.key, required this.scrollController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Expense> _expenses = [];
  double _monthlyBudget = 50000.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final expenses = await DatabaseHelper.instance.getAllExpenses();
    final monthKey = Formatters.getMonthKey(DateTime.now());
    final budget = await DatabaseHelper.instance.getMonthlyBudget(monthKey);

    setState(() {
      _expenses = expenses;
      _monthlyBudget = budget;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentMonthExpenses = _expenses.where((e) {
      return e.dateTime.year == DateTime.now().year && e.dateTime.month == DateTime.now().month;
    }).toList();

    double totalSpentThisMonth = currentMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);
    double remainingBudget = (_monthlyBudget - totalSpentThisMonth) > 0 ? (_monthlyBudget - totalSpentThisMonth) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Profile Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome Back', style: TextStyle(color: AppColors.subText, fontSize: 13)),
                        SizedBox(height: 2),
                        Text('Speny Tracker', style: TextStyle(color: AppColors.darkText, fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      children: [
                        _buildHeaderIcon(Icons.notifications_none_rounded),
                        const SizedBox(width: 10),
                        _buildHeaderIcon(Icons.settings_outlined),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Hero Balance & Budget Glassmorphic Card (matching UI Design provided)
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Balance / Spent',
                            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('BDT v', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Formatters.formatMoney(totalSpentThisMonth),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildGlassPill('Budget: ${Formatters.formatMoney(_monthlyBudget, short: true)}'),
                          _buildGlassPill('Remaining: ${Formatters.formatMoney(remainingBudget, short: true)}'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Refreshed Live | ${Formatters.formatDateBD(DateTime.now())}',
                        style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Action Add Expense Floating Neo Button
                NeoContainer(
                  borderRadius: 20,
                  onTap: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddEditExpenseScreen()),
                    );
                    if (res == true) _loadData();
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryPurple, size: 26),
                      SizedBox(width: 10),
                      Text(
                        'Add New Expense',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Recent Transactions Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Transactions', style: TextStyle(color: AppColors.darkText, fontSize: 18, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () {},
                      child: const Text('See All', style: TextStyle(color: AppColors.subText, fontSize: 13, fontWeight: FontWeight.w600)),
                    )
                  ],
                ),

                const SizedBox(height: 16),

                // Recent Expenses List
                _expenses.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: Text('No expenses recorded yet.', style: TextStyle(color: AppColors.subText))),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _expenses.length > 8 ? 8 : _expenses.length,
                        itemBuilder: (context, index) {
                          final item = _expenses[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.shadowDark,
                                  offset: Offset(3, 3),
                                  blurRadius: 8,
                                ),
                                BoxShadow(
                                  color: AppColors.shadowLight,
                                  offset: Offset(-3, -3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentLightPurple,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryPurple, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkText),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        Formatters.formatDateTimeBD(item.dateTime),
                                        style: const TextStyle(fontSize: 11, color: AppColors.subText),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  Formatters.formatMoney(item.amount, short: true),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.darkText,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                const SizedBox(height: 80), // Extra space for floating nav bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: AppColors.shadowDark, offset: Offset(3, 3), blurRadius: 6),
          BoxShadow(color: AppColors.shadowLight, offset: Offset(-3, -3), blurRadius: 6),
        ],
      ),
      child: Icon(icon, color: AppColors.darkText, size: 20),
    );
  }

  Widget _buildGlassPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
