import '../models/app_models.dart';
import '../utils/formatters.dart';

class CategoryBreakdownItem {
  final int categoryId;
  final String categoryName;
  final String iconName;
  final double totalAmount;
  final double percentage;

  CategoryBreakdownItem({
    required this.categoryId,
    required this.categoryName,
    required this.iconName,
    required this.totalAmount,
    required this.percentage,
  });
}

class VendorSpendingItem {
  final String vendorName;
  final double totalSpent;
  final int transactionCount;

  VendorSpendingItem({
    required this.vendorName,
    required this.totalSpent,
    required this.transactionCount,
  });
}

class SmartInsight {
  final String type; // 'warning', 'tip', 'encouragement', 'prediction'
  final String title;
  final String message;

  SmartInsight({
    required this.type,
    required this.title,
    required this.message,
  });
}

class ReportsEngine {
  /// 1. Category-wise Spending Breakdown
  static List<CategoryBreakdownItem> getCategoryBreakdown(
      List<Expense> expenses, List<CategoryModel> categories) {
    final Map<int, double> categorySums = {};
    double total = 0.0;

    for (var e in expenses) {
      categorySums[e.categoryId] = (categorySums[e.categoryId] ?? 0.0) + e.amount;
      total += e.amount;
    }

    if (total == 0) return [];

    final List<CategoryBreakdownItem> items = [];
    final categoryMap = {for (var c in categories) c.id: c};

    categorySums.forEach((catId, sum) {
      final cat = categoryMap[catId];
      final name = cat?.name ?? 'Uncategorized';
      final icon = cat?.iconName ?? 'category';
      final pct = (sum / total) * 100;
      items.add(CategoryBreakdownItem(
        categoryId: catId,
        categoryName: name,
        iconName: icon,
        totalAmount: sum,
        percentage: pct,
      ));
    });

    items.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return items;
  }

  /// 2. Income vs Expense Ratio (Budget vs Total Spent)
  static Map<String, double> getIncomeVsExpenseRatio(double budget, List<Expense> expenses) {
    double spent = expenses.fold(0.0, (sum, e) => sum + e.amount);
    double remaining = (budget - spent) > 0 ? (budget - spent) : 0.0;
    return {
      'budget': budget,
      'spent': spent,
      'remaining': remaining,
      'ratioPercentage': budget > 0 ? (spent / budget) * 100 : 0.0,
    };
  }

  /// 3. Daily Average & Spending Trend (for selected days count)
  static Map<String, dynamic> getDailyAverageAndTrend(List<Expense> expenses, {int days = 30}) {
    double totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
    double dailyAverage = days > 0 ? totalSpent / days : 0.0;

    // Daily breakdown map for trend chart
    final Map<DateTime, double> dailyMap = {};
    final now = DateTime.now();
    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      dailyMap[day] = 0.0;
    }

    for (var e in expenses) {
      final dayKey = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
      if (dailyMap.containsKey(dayKey)) {
        dailyMap[dayKey] = dailyMap[dayKey]! + e.amount;
      }
    }

    return {
      'totalSpent': totalSpent,
      'dailyAverage': dailyAverage,
      'dailyTrendMap': dailyMap,
    };
  }

  /// 4. Budget vs Actual Spent Per Category
  static List<Map<String, dynamic>> getCategoryBudgetvsActual(
      List<Expense> expenses, List<CategoryModel> categories) {
    final categoryBreakdown = getCategoryBreakdown(expenses, categories);
    final categoryMap = {for (var c in categories) c.id: c};

    return categoryBreakdown.map((item) {
      final cat = categoryMap[item.categoryId];
      final catBudget = cat?.budget ?? 0.0;
      final percentage = catBudget > 0 ? (item.totalAmount / catBudget) * 100 : 0.0;
      return {
        'categoryName': item.categoryName,
        'spent': item.totalAmount,
        'budget': catBudget,
        'percentage': percentage,
        'isOverBudget': catBudget > 0 && item.totalAmount > catBudget,
      };
    }).toList();
  }

  /// 5. Recurring Bills & Subscriptions Report
  static Map<String, dynamic> getRecurringBillsReport(List<RecurringBill> bills) {
    final activeBills = bills.where((b) => b.isActive).toList();
    final double totalMonthlyRecurring = activeBills.fold(0.0, (sum, b) {
      return sum + (b.frequency == 'Yearly' ? b.amount / 12 : b.amount);
    });

    return {
      'activeBills': activeBills,
      'totalMonthlyRecurring': totalMonthlyRecurring,
      'count': activeBills.length,
    };
  }

  /// 6. Top Expenses / Outlier Report (Top 5 largest transactions)
  static List<Expense> getTopOutlierExpenses(List<Expense> expenses, {int limit = 5}) {
    final sortedList = List<Expense>.from(expenses);
    sortedList.sort((a, b) => b.amount.compareTo(a.amount));
    return sortedList.take(limit).toList();
  }

  /// 7. Period-over-Period Comparison (e.g. Current Month vs Previous Month)
  static Map<String, dynamic> getPeriodOverPeriodComparison(
      List<Expense> currentPeriodExpenses, List<Expense> previousPeriodExpenses) {
    double currentTotal = currentPeriodExpenses.fold(0.0, (sum, e) => sum + e.amount);
    double previousTotal = previousPeriodExpenses.fold(0.0, (sum, e) => sum + e.amount);

    double difference = currentTotal - previousTotal;
    double percentageChange = 0.0;
    if (previousTotal > 0) {
      percentageChange = ((currentTotal - previousTotal) / previousTotal) * 100;
    }

    return {
      'currentTotal': currentTotal,
      'previousTotal': previousTotal,
      'difference': difference,
      'percentageChange': percentageChange,
      'isIncreased': difference > 0,
    };
  }

  /// 8. Yearly Heatmap Data (Map of Date to Expense level 0-4)
  static Map<DateTime, int> getYearlyHeatmapData(List<Expense> yearExpenses) {
    final Map<DateTime, double> dailyTotals = {};
    for (var e in yearExpenses) {
      final dateOnly = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
      dailyTotals[dateOnly] = (dailyTotals[dateOnly] ?? 0.0) + e.amount;
    }

    final Map<DateTime, int> heatmap = {};
    dailyTotals.forEach((date, amount) {
      if (amount == 0) {
        heatmap[date] = 0;
      } else if (amount <= 500) {
        heatmap[date] = 1;
      } else if (amount <= 2000) {
        heatmap[date] = 2;
      } else if (amount <= 5000) {
        heatmap[date] = 3;
      } else {
        heatmap[date] = 4;
      }
    });

    return heatmap;
  }

  /// 9. Needs vs Wants Breakdown
  static Map<String, dynamic> getNeedsVsWantsBreakdown(List<Expense> expenses) {
    double needsTotal = 0.0;
    double wantsTotal = 0.0;

    for (var e in expenses) {
      if (e.type == ExpenseType.need) {
        needsTotal += e.amount;
      } else {
        wantsTotal += e.amount;
      }
    }

    double total = needsTotal + wantsTotal;
    double needsPercentage = total > 0 ? (needsTotal / total) * 100 : 0.0;
    double wantsPercentage = total > 0 ? (wantsTotal / total) * 100 : 0.0;

    return {
      'needsTotal': needsTotal,
      'wantsTotal': wantsTotal,
      'needsPercentage': needsPercentage,
      'wantsPercentage': wantsPercentage,
      'total': total,
    };
  }

  /// 10. Year-over-Year Category Inflation
  static List<Map<String, dynamic>> getYoYCategoryInflation(
      List<Expense> currentMonthExpenses, List<Expense> lastYearSameMonthExpenses, List<CategoryModel> categories) {
    final currentBreakdown = {for (var item in getCategoryBreakdown(currentMonthExpenses, categories)) item.categoryId: item.totalAmount};
    final lastYearBreakdown = {for (var item in getCategoryBreakdown(lastYearSameMonthExpenses, categories)) item.categoryId: item.totalAmount};

    return categories.map((cat) {
      double current = currentBreakdown[cat.id] ?? 0.0;
      double lastYear = lastYearBreakdown[cat.id] ?? 0.0;
      double diff = current - lastYear;
      double pct = lastYear > 0 ? ((current - lastYear) / lastYear) * 100 : 0.0;

      return {
        'categoryName': cat.name,
        'currentAmount': current,
        'lastYearAmount': lastYear,
        'difference': diff,
        'percentageChange': pct,
      };
    }).where((item) => (item['currentAmount'] as double) > 0 || (item['lastYearAmount'] as double) > 0).toList();
  }

  /// 11. Spending Velocity / Burn Rate Report
  static Map<String, dynamic> getSpendingVelocityReport(double monthlyBudget, List<Expense> currentMonthExpenses) {
    final now = DateTime.now();
    final dayOfMonth = now.day;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    double spentSoFar = currentMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);
    double burnRatePercentage = monthlyBudget > 0 ? (spentSoFar / monthlyBudget) * 100 : 0.0;
    double dailySpendRate = dayOfMonth > 0 ? spentSoFar / dayOfMonth : 0.0;

    double projectedMonthEnd = dailySpendRate * daysInMonth;
    int estimatedDaysRemaining = 0;

    if (dailySpendRate > 0) {
      double remainingBudget = monthlyBudget - spentSoFar;
      if (remainingBudget > 0) {
        estimatedDaysRemaining = (remainingBudget / dailySpendRate).floor();
      }
    } else {
      estimatedDaysRemaining = daysInMonth - dayOfMonth;
    }

    bool isBurnTooHigh = (spentSoFar > (monthlyBudget * (dayOfMonth / daysInMonth) * 1.25));

    return {
      'spentSoFar': spentSoFar,
      'monthlyBudget': monthlyBudget,
      'burnRatePercentage': burnRatePercentage,
      'dailySpendRate': dailySpendRate,
      'projectedMonthEnd': projectedMonthEnd,
      'estimatedDaysRemaining': estimatedDaysRemaining,
      'isBurnTooHigh': isBurnTooHigh,
    };
  }

  /// 12. Vendor & Merchant Intelligence
  static List<VendorSpendingItem> getVendorIntelligence(List<Expense> expenses) {
    final Map<String, Map<String, dynamic>> vendorMap = {};

    for (var e in expenses) {
      final vendorName = (e.vendor != null && e.vendor!.trim().isNotEmpty)
          ? e.vendor!.trim()
          : 'General / Local';

      if (!vendorMap.containsKey(vendorName)) {
        vendorMap[vendorName] = {'total': 0.0, 'count': 0};
      }

      vendorMap[vendorName]!['total'] = (vendorMap[vendorName]!['total'] as double) + e.amount;
      vendorMap[vendorName]!['count'] = (vendorMap[vendorName]!['count'] as int) + 1;
    }

    final List<VendorSpendingItem> list = [];
    vendorMap.forEach((vendor, data) {
      list.add(VendorSpendingItem(
        vendorName: vendor,
        totalSpent: data['total'] as double,
        transactionCount: data['count'] as int,
      ));
    });

    list.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    return list;
  }

  /// 13. No-Spend Days & Streak Tracker
  static Map<String, dynamic> getNoSpendDaysAndStreak(List<Expense> expenses) {
    final now = DateTime.now();
    final Map<DateTime, double> dailyMap = {};

    // Check last 30 days
    for (int i = 0; i < 30; i++) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      dailyMap[d] = 0.0;
    }

    for (var e in expenses) {
      final dKey = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
      if (dailyMap.containsKey(dKey)) {
        dailyMap[dKey] = dailyMap[dKey]! + e.amount;
      }
    }

    int noSpendCount = 0;
    dailyMap.forEach((date, spent) {
      if (spent == 0) noSpendCount++;
    });

    // Calculate current consecutive no-spend streak
    int streak = 0;
    for (int i = 0; i < 30; i++) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      if ((dailyMap[d] ?? 0.0) == 0.0) {
        streak++;
      } else {
        break;
      }
    }

    return {
      'noSpendDaysInLast30': noSpendCount,
      'currentStreak': streak,
    };
  }

  /// 14. Opportunity Cost & Micro-Savings Potential
  static Map<String, dynamic> getOpportunityCostAnalysis(List<Expense> currentMonthExpenses) {
    // Micro-spending: daily small expenses like tea/snacks/quick rides (< 200 TK)
    final microExpenses = currentMonthExpenses.where((e) => e.amount <= 200.0).toList();
    double totalMicroSpend = microExpenses.fold(0.0, (sum, e) => sum + e.amount);

    double potential10PctSavings = totalMicroSpend * 0.10 * 12; // Annual savings if reduced 10%
    double potential25PctSavings = totalMicroSpend * 0.25 * 12;

    return {
      'microSpendCount': microExpenses.length,
      'totalMicroSpendThisMonth': totalMicroSpend,
      'annualSavingsAt10Pct': potential10PctSavings,
      'annualSavingsAt25Pct': potential25PctSavings,
    };
  }

  /// 15. Financial Health Score & AI Smart Advisory Dashboard
  static Map<String, dynamic> calculateFinancialHealthScoreAndInsights({
    required double monthlyBudget,
    required List<Expense> monthExpenses,
    required List<CategoryModel> categories,
  }) {
    int score = 100;
    final List<SmartInsight> insights = [];

    final needsVsWants = getNeedsVsWantsBreakdown(monthExpenses);
    final velocity = getSpendingVelocityReport(monthlyBudget, monthExpenses);
    final noSpend = getNoSpendDaysAndStreak(monthExpenses);

    double spentSoFar = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);

    // 1. Budget Burn Penalty
    if (monthlyBudget > 0) {
      if (spentSoFar > monthlyBudget) {
        score -= 30;
        insights.add(SmartInsight(
          type: 'warning',
          title: 'Budget Overrun Alert',
          message: 'You have exceeded your monthly budget of ${Formatters.formatMoney(monthlyBudget, short: true)}!',
        ));
      } else if (velocity['isBurnTooHigh'] as bool) {
        score -= 15;
        insights.add(SmartInsight(
          type: 'warning',
          title: 'High Burn Rate',
          message: 'At your current spend velocity, your budget will run out in ${velocity['estimatedDaysRemaining']} days.',
        ));
      }
    }

    // 2. Wants Ratio Penalty (Ideal: Needs <= 50%, Wants <= 30%)
    double wantsPct = needsVsWants['wantsPercentage'] as double;
    if (wantsPct > 40) {
      score -= 15;
      insights.add(SmartInsight(
        type: 'warning',
        title: 'High Discretionary Spending',
        message: 'Wants account for ${wantsPct.toStringAsFixed(0)}% of your expenses. Try adhering to the 50/30/20 rule.',
      ));
    }

    // 3. Streak Encouragement
    int streak = noSpend['currentStreak'] as int;
    if (streak >= 3) {
      score += 5;
      insights.add(SmartInsight(
        type: 'encouragement',
        title: 'Great Discipline!',
        message: 'You are on a $streak-day No-Spend streak! Keep up the great financial discipline.',
      ));
    } else {
      insights.add(SmartInsight(
        type: 'tip',
        title: 'No-Spend Challenge',
        message: 'Try taking a No-Spend day today to boost your financial health score by 5 points!',
      ));
    }

    // 4. Category Spikes
    final categoryBreakdown = getCategoryBreakdown(monthExpenses, categories);
    if (categoryBreakdown.isNotEmpty) {
      final topCat = categoryBreakdown.first;
      if (topCat.percentage > 45) {
        insights.add(SmartInsight(
          type: 'warning',
          title: 'Category Spike in ${topCat.categoryName}',
          message: '${topCat.categoryName} alone makes up ${topCat.percentage.toStringAsFixed(0)}% of your total spending this month.',
        ));
      }
    }

    score = score.clamp(0, 100);

    String rating = 'Good';
    if (score >= 85) rating = 'Excellent';
    else if (score >= 70) rating = 'Good';
    else if (score >= 50) rating = 'Fair';
    else rating = 'Needs Attention';

    return {
      'score': score,
      'rating': rating,
      'insights': insights,
    };
  }

  /// What-If Simulation Calculator
  static Map<String, dynamic> simulatePurchase({
    required double itemCost,
    required double currentBudget,
    required List<Expense> monthExpenses,
    required List<CategoryModel> categories,
  }) {
    double currentSpent = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);
    double newTotalSpent = currentSpent + itemCost;

    final currentHealth = calculateFinancialHealthScoreAndInsights(
      monthlyBudget: currentBudget,
      monthExpenses: monthExpenses,
      categories: categories,
    );

    // Create simulated mock list
    final simulatedExpenses = List<Expense>.from(monthExpenses)
      ..add(Expense(
        amount: itemCost,
        categoryId: 1,
        dateTime: DateTime.now(),
        title: 'Simulated Purchase',
        type: ExpenseType.want,
      ));

    final simulatedHealth = calculateFinancialHealthScoreAndInsights(
      monthlyBudget: currentBudget,
      monthExpenses: simulatedExpenses,
      categories: categories,
    );

    int scoreDiff = (currentHealth['score'] as int) - (simulatedHealth['score'] as int);
    bool willExceedBudget = newTotalSpent > currentBudget;

    return {
      'originalScore': currentHealth['score'],
      'simulatedScore': simulatedHealth['score'],
      'scoreDrop': scoreDiff,
      'willExceedBudget': willExceedBudget,
      'newTotalSpent': newTotalSpent,
      'remainingBudgetAfterPurchase': (currentBudget - newTotalSpent) > 0 ? (currentBudget - newTotalSpent) : 0.0,
    };
  }
}
