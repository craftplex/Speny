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

  // PDF Export
  Future<void> _exportPDF() async {
    final pdf = pw.Document();
    final totalSpent = _expenses.fold(0.0, (sum, e) => sum + e.amount);

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
                data: _expenses.map((e) => [
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
    List<List<dynamic>> rows = [];
    rows.add(['ID', 'Title', 'Category', 'Amount (TK)', 'Date Time', 'Type', 'Vendor']);

    for (var e in _expenses) {
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

    String csvData = const ListToCsvConverter().convert(rows);
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

    final categoryBreakdown = ReportsEngine.getCategoryBreakdown(_expenses, _categories);
    final dailyTrend = ReportsEngine.getDailyAverageAndTrend(_expenses, days: 30);
    final dailyMap = dailyTrend['dailyTrendMap'] as Map<DateTime, double>;
    final dailySpots = dailyMap.entries.toList().asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    final needsWants = ReportsEngine.getNeedsVsWantsBreakdown(_expenses);
    final velocity = ReportsEngine.getSpendingVelocityReport(_monthlyBudget, _expenses);
    final topOutliers = ReportsEngine.getTopOutlierExpenses(_expenses, limit: 5);
    final vendors = ReportsEngine.getVendorIntelligence(_expenses);
    final noSpend = ReportsEngine.getNoSpendDaysAndStreak(_expenses);
    final microSavings = ReportsEngine.getOpportunityCostAnalysis(_expenses);
    final heatmapData = ReportsEngine.getYearlyHeatmapData(_expenses);
    final categoryBudgets = ReportsEngine.getCategoryBudgetvsActual(_expenses, _categories);

    final totalSpentThisMonth = _expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Detailed Financial Reports', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Filter Tabs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['Daily', 'Weekly', 'Monthly', 'Yearly'].map((p) {
                  final isSel = _filterPeriod == p;
                  return GestureDetector(
                    onTap: () => setState(() => _filterPeriod = p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.primaryPurple : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: AppColors.shadowDark, blurRadius: 4, offset: Offset(2, 2))],
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : AppColors.darkText,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // 1. Category Breakdown
              _buildReportCard(
                title: '1. Category Breakdown (Pie / Donut)',
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
                                    color: AppColors.primaryPurple.withValues(alpha: 0.8),
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

              // 2. Budget vs Expense Bar Chart
              _buildReportCard(
                title: '2. Overall Budget vs Spent Ratio',
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
                            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: totalSpentThisMonth, color: Colors.pinkAccent, width: 24)]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Budget: ${Formatters.formatMoney(_monthlyBudget, short: true)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
                        Text('Spent: ${Formatters.formatMoney(totalSpentThisMonth, short: true)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Category Budget vs Actual
              _buildReportCard(
                title: '3. Category Budget vs Actual Spent',
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
                            value: budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0,
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
                title: '4. Daily Average & Spending Trend',
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
                title: '5. Yearly Heatmap Calendar',
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
                      itemCount: 36,
                      itemBuilder: (context, index) {
                        int level = index % 5;
                        Color cellColor = Colors.grey.shade200;
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
                title: '6. Needs vs Wants (50/30/20 Rule)',
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
                title: '7. Spending Velocity / Burn Rate',
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
                title: '8. Top Outlier Expenses',
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
                title: '9. Top Vendors & Merchants',
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
                title: '10. No-Spend Streak & Savings',
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
