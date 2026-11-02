import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import '../models/app_models.dart';
import '../services/reports_engine.dart';
import '../theme/neo_glass_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_components.dart';

class ReportsScreen extends StatefulWidget {
  final VoidCallback? onRefreshNeeded;

  const ReportsScreen({super.key, this.onRefreshNeeded});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Expense> _expenses = [];
  List<CategoryModel> _categories = [];
  double _monthlyBudget = 50000.0;
  bool _isLoading = true;

  String _filterPeriod = 'Monthly'; // Daily, Weekly, Monthly, Yearly

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

    if (mounted) {
      setState(() {
        _expenses = expenses;
        _categories = categories;
        _monthlyBudget = budget;
        _isLoading = false;
      });
    }
  }

  List<Expense> _expensesForSelectedPeriod() {
    final now = DateTime.now();
    late final DateTime start;
    late final DateTime end;
    switch (_filterPeriod) {
      case 'Daily':
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(days: 1));
        break;
      case 'Weekly':
        start = Formatters.getStartOfWeek(now);
        end = start.add(const Duration(days: 7));
        break;
      case 'Yearly':
        start = DateTime(now.year);
        end = DateTime(now.year + 1);
        break;
      default:
        start = DateTime(now.year, now.month);
        end = DateTime(now.year, now.month + 1);
    }

    return _expenses
        .where((expense) =>
            !expense.dateTime.isBefore(start) && expense.dateTime.isBefore(end))
        .toList();
  }

  // PDF Export
  Future<void> _exportPDF() async {
    final expenses = _expensesForSelectedPeriod();
    final pdf = pw.Document();
    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('Speny Expense Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Generated on: ${Formatters.formatDateTimeBD(DateTime.now())}'),
              pw.Text('Total Spent: ${Formatters.formatMoney(totalSpent)}'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Title', 'Category', 'Amount', 'Date', 'Type'],
                data: expenses.map((e) => [
                  e.title,
                  e.categoryName ?? '',
                  Formatters.formatMoney(e.amount, short: true),
                  Formatters.formatDateBD(e.dateTime),
                  e.type == ExpenseType.need ? 'Need' : 'Want',
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Speny_Report.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'Speny Financial Expense Report (PDF)');
  }

  // CSV Export
  Future<void> _exportCSV() async {
    final expenses = _expensesForSelectedPeriod();
    List<List<dynamic>> rows = [];
    rows.add(['ID', 'Title', 'Category', 'Amount (TK)', 'Date Time', 'Type', 'Vendor']);

    for (var e in expenses) {
      rows.add([
        e.id,
        e.title,
        e.categoryName ?? '',
        e.amount,
        Formatters.formatDateTimeBD(e.dateTime),
        e.type == ExpenseType.need ? 'Need' : 'Want',
        e.vendor ?? '',
      ]);
    }

    String csvData = csv.encode(rows);
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Speny_Report.csv');
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(file.path)], text: 'Speny Financial Expense Report (CSV)');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final now = DateTime.now();
    final periodExpenses = _expensesForSelectedPeriod();
    final categoryBreakdown =
        ReportsEngine.getCategoryBreakdown(periodExpenses, _categories);
    final recentExpenses = _expenses.where((expense) {
      final today = DateTime(now.year, now.month, now.day);
      return !expense.dateTime.isBefore(today.subtract(const Duration(days: 29))) &&
          expense.dateTime.isBefore(today.add(const Duration(days: 1)));
    }).toList();
    final dailyTrend =
        ReportsEngine.getDailyAverageAndTrend(recentExpenses, days: 30);
    final dailyMap = dailyTrend['dailyTrendMap'] as Map<DateTime, double>;
    final dailySpots = dailyMap.entries.toList().asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    final needsWants = ReportsEngine.getNeedsVsWantsBreakdown(periodExpenses);
    final currentMonthExpenses = _expenses.where((expense) {
      return expense.dateTime.year == now.year &&
          expense.dateTime.month == now.month;
    }).toList();
    final velocity =
        ReportsEngine.getSpendingVelocityReport(_monthlyBudget, currentMonthExpenses);
    final topOutliers =
        ReportsEngine.getTopOutlierExpenses(periodExpenses, limit: 5);
    final vendors = ReportsEngine.getVendorIntelligence(periodExpenses);
    final noSpend = ReportsEngine.getNoSpendDaysAndStreak(_expenses);
    final microSavings =
        ReportsEngine.getOpportunityCostAnalysis(currentMonthExpenses);
    final yearExpenses =
        _expenses.where((e) => e.dateTime.year == now.year).toList();
    final heatmapData = ReportsEngine.getYearlyHeatmapData(yearExpenses);
    final categoryBudgets =
        ReportsEngine.getCategoryBudgetvsActual(currentMonthExpenses, _categories);
    final totalSpentSelectedPeriod =
        periodExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalSpentThisMonth =
        currentMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primaryPurple),
            onPressed: _exportPDF,
            tooltip: 'Export PDF',
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_rounded, color: AppColors.primaryPurple),
            onPressed: _exportCSV,
            tooltip: 'Export CSV',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 124),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeading(
                title: 'Spending insights',
                subtitle: 'A clearer picture of where your money goes.',
              ),
              NeoContainer(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: ['Daily', 'Weekly', 'Monthly', 'Yearly'].map((period) {
                    final selected = _filterPeriod == period;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ChoiceChip(
                          label: Text(period),
                          selected: selected,
                          showCheckmark: false,
                          onSelected: (_) =>
                              setState(() => _filterPeriod = period),
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.subText,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          selectedColor: AppColors.primaryPurple,
                          backgroundColor: Colors.transparent,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 17),
              NeoContainer(
                backgroundColor: AppColors.paleGreen,
                child: Row(
                  children: [
                    const Icon(Icons.insights_rounded,
                        color: AppColors.primaryPurple, size: 23),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Formatters.formatMoney(totalSpentSelectedPeriod),
                            style: const TextStyle(
                              color: AppColors.darkText,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Total spending · $_filterPeriod',
                            style: const TextStyle(
                                color: AppColors.subText, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${periodExpenses.length} ${periodExpenses.length == 1 ? 'expense' : 'expenses'}',
                      style: const TextStyle(
                        color: AppColors.primaryPurple,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildReportCard(
                title: 'By category',
                child: Column(
                  children: [
                    SizedBox(
                      height: 180,
                      child: categoryBreakdown.isEmpty
                          ? const Center(child: Text('No expense data available'))
                          : PieChart(
                              PieChartData(
                                sections: categoryBreakdown.map((item) {
                                  return PieChartSectionData(
                                    value: item.totalAmount,
                                    title: '${item.percentage.toStringAsFixed(0)}%',
                                    color: categoryColorFor(item.categoryName),
                                    radius: 45,
                                    titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    ...categoryBreakdown.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item.categoryName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(Formatters.formatMoney(item.totalAmount, short: true), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Budget vs expense
              _buildReportCard(
                title: 'Monthly budget vs spent',
                child: Column(
                  children: [
                    SizedBox(
                      height: 140,
                      child: BarChart(
                        BarChartData(
                          borderData: FlBorderData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          barGroups: [
                            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: _monthlyBudget, color: AppColors.primaryPurple, width: 24)]),
                            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: totalSpentThisMonth, color: AppColors.orange, width: 24)]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Budget: ${Formatters.formatMoney(_monthlyBudget, short: true)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
                        Text('Spent: ${Formatters.formatMoney(totalSpentThisMonth, short: true)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.orange)),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Category Budget vs Actual
              _buildReportCard(
                title: 'This month’s category budgets',
                child: Column(
                  children: categoryBudgets.map((item) {
                    final catName = item['categoryName'] as String;
                    final spent = item['spent'] as double;
                    final budget = item['budget'] as double;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(catName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${Formatters.formatMoney(spent, short: true)} / ${Formatters.formatMoney(budget, short: true)}', style: const TextStyle(fontSize: 12, color: AppColors.subText)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: budget > 0
                                ? (spent / budget).clamp(0.0, 1.0).toDouble()
                                : 0.0,
                            color: spent > budget && budget > 0 ? Colors.red : AppColors.primaryPurple,
                            backgroundColor: AppColors.accentLightPurple,
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // 4. Daily Average & Spending Trend Line Graph
              _buildReportCard(
                title: '30-day spending trend',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '30-Day Daily Average: ${Formatters.formatMoney(dailyTrend['dailyAverage'] as double, short: true)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPurple, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 140,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: dailySpots.isEmpty ? [const FlSpot(0, 0)] : dailySpots,
                              isCurved: true,
                              color: AppColors.primaryPurple,
                              barWidth: 3,
                              isStrokeCapRound: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5. GitHub-style Heatmap Calendar
              _buildReportCard(
                title: 'Recent spending map',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Expense Intensity Map', style: TextStyle(color: AppColors.subText, fontSize: 12)),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 12,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: 84,
                      itemBuilder: (context, index) {
                          final date = DateTime(now.year, now.month, now.day)
                              .subtract(Duration(days: 83 - index));
                          final day = DateTime(date.year, date.month, date.day);
                          final level = heatmapData[day] ?? 0;
                          Color cellColor = AppColors.background;
                        if (level == 1) cellColor = AppColors.primaryPurple.withValues(alpha: 0.3);
                        if (level == 2) cellColor = AppColors.primaryPurple.withValues(alpha: 0.5);
                        if (level == 3) cellColor = AppColors.primaryPurple.withValues(alpha: 0.8);
                        if (level == 4) cellColor = AppColors.primaryPurple;

                        return Container(
                          decoration: BoxDecoration(
                            color: cellColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 6. Needs vs Wants Breakdown (50/30/20 Rule)
              _buildReportCard(
                title: 'Needs and wants',
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Needs (ضروری): ${(needsWants['needsPercentage'] as double).toStringAsFixed(0)}%'),
                        Text('Wants (ইচ্ছা): ${(needsWants['wantsPercentage'] as double).toStringAsFixed(0)}%'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (needsWants['total'] as double) > 0 ? (needsWants['needsTotal'] as double) / (needsWants['total'] as double) : 0.5,
                        minHeight: 12,
                        backgroundColor: Colors.pinkAccent.shade100,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 7. Spending Velocity / Burn Rate
              _buildReportCard(
                title: 'Monthly spending pace',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      velocity['isBurnTooHigh'] as bool
                          ? 'FLAG: Burn rate is high! Remaining days: ${velocity['estimatedDaysRemaining']}'
                          : 'Burn Rate is Normal. Estimated budget runtime: ${velocity['estimatedDaysRemaining']} days.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: velocity['isBurnTooHigh'] as bool ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 8. Top Outlier Expenses
              _buildReportCard(
                title: 'Largest expenses',
                child: Column(
                  children: topOutliers.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                          Text(Formatters.formatMoney(e.amount, short: true), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // 9. Top Vendors & Merchant Intelligence
              _buildReportCard(
                title: 'Top merchants',
                child: Column(
                  children: vendors.take(4).map((v) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(v.vendorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(Formatters.formatMoney(v.totalSpent, short: true), style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // 10. Streak & Savings
              _buildReportCard(
                title: 'No-spend and savings',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current No-Spend Streak: ${noSpend['currentStreak']} Days', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Potential Annual Savings if 10% micro-spend reduced: ${Formatters.formatMoney(microSavings['annualSavingsAt10Pct'] as double)}', style: const TextStyle(color: AppColors.subText, fontSize: 13)),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard({required String title, required Widget child}) {
    return NeoContainer(
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.darkText)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
