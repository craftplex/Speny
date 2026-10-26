import 'package:flutter_test/flutter_test.dart';
import 'package:speny/models/app_models.dart';
import 'package:speny/services/reports_engine.dart';
import 'package:speny/utils/formatters.dart';

void main() {
  final sampleCategories = [
    CategoryModel(id: 1, name: 'Food & Dining', iconName: 'fastfood', colorHex: 0xFFFF5722, budget: 15000),
    CategoryModel(id: 2, name: 'Transportation', iconName: 'directions_bus', colorHex: 0xFF2196F3, budget: 5000),
  ];

  final sampleExpenses = [
    Expense(id: 1, amount: 2000, categoryId: 1, dateTime: DateTime.now(), title: 'Dinner', vendor: 'Foodpanda', type: ExpenseType.want),
    Expense(id: 2, amount: 500, categoryId: 2, dateTime: DateTime.now(), title: 'Uber Ride', vendor: 'Uber', type: ExpenseType.need),
    Expense(id: 3, amount: 1000, categoryId: 1, dateTime: DateTime.now().subtract(const Duration(days: 1)), title: 'Groceries', vendor: 'Shwapno', type: ExpenseType.need),
  ];

  test('Formatters test english money and BD 12H dates', () {
    expect(Formatters.formatMoney(50000), '50,000 Taka');
    expect(Formatters.formatMoney(50000, short: true), '50,000 TK');

    final testDt = DateTime(2026, 5, 12, 9, 41);
    expect(Formatters.formatDateTimeBD(testDt), '12 May 2026, 09:41 AM');
  });

  test('ReportsEngine Category Breakdown & Needs vs Wants', () {
    final breakdown = ReportsEngine.getCategoryBreakdown(sampleExpenses, sampleCategories);
    expect(breakdown.length, 2);
    expect(breakdown.first.categoryName, 'Food & Dining');
    expect(breakdown.first.totalAmount, 3000);

    final needsWants = ReportsEngine.getNeedsVsWantsBreakdown(sampleExpenses);
    expect(needsWants['needsTotal'], 1500);
    expect(needsWants['wantsTotal'], 2000);
  });

  test('Financial Health Score calculation', () {
    final health = ReportsEngine.calculateFinancialHealthScoreAndInsights(
      monthlyBudget: 50000,
      monthExpenses: sampleExpenses,
      categories: sampleCategories,
    );
    expect(health['score'], greaterThan(50));
  });
}
