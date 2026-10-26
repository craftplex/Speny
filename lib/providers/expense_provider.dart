import 'package:flutter/material.dart';

class ExpenseProvider extends ChangeNotifier {
  // State management for Expenses, Categories, Budgets, and Active Navigation
  double _monthlyBudget = 50000.0;
  bool _isNavBarVisible = true;

  double get monthlyBudget => _monthlyBudget;
  bool get isNavBarVisible => _isNavBarVisible;

  void setNavBarVisibility(bool visible) {
    if (_isNavBarVisible != visible) {
      _isNavBarVisible = visible;
      notifyListeners();
    }
  }

  void updateMonthlyBudget(double newBudget) {
    _monthlyBudget = newBudget;
    notifyListeners();
  }
}
