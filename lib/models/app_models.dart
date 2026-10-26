import 'package:flutter/material.dart';

enum ExpenseType { need, want }

class Expense {
  final int? id;
  final double amount;
  final int categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final DateTime dateTime;
  final String title; // Can be in Bengali or English
  final String? vendor; // e.g. Foodpanda, Pathao, Daraz
  final ExpenseType type; // need or want
  final bool isRecurring;

  Expense({
    this.id,
    required this.amount,
    required this.categoryId,
    this.categoryName,
    this.categoryIcon,
    required this.dateTime,
    required this.title,
    this.vendor,
    this.type = ExpenseType.need,
    this.isRecurring = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category_id': categoryId,
      'date_time': dateTime.toIso8601String(),
      'title': title,
      'vendor': vendor,
      'type': type == ExpenseType.need ? 'need' : 'want',
      'is_recurring': isRecurring ? 1 : 0,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as int,
      categoryName: map['category_name'] as String?,
      categoryIcon: map['category_icon'] as String?,
      dateTime: DateTime.parse(map['date_time'] as String),
      title: map['title'] as String,
      vendor: map['vendor'] as String?,
      type: map['type'] == 'want' ? ExpenseType.want : ExpenseType.need,
      isRecurring: (map['is_recurring'] as int?) == 1,
    );
  }
}

class CategoryModel {
  final int? id;
  final String name;
  final String iconName; // e.g., 'fastfood', 'directions_bus'
  final int colorHex;
  final double? budget; // optional category monthly budget

  CategoryModel({
    this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    this.budget,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'color_hex': colorHex,
      'budget': budget,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconName: map['icon_name'] as String,
      colorHex: map['color_hex'] as int,
      budget: map['budget'] != null ? (map['budget'] as num).toDouble() : null,
    );
  }
}

class BudgetModel {
  final int? id;
  final String monthKey; // e.g., '2026-03'
  final double monthlyLimit;

  BudgetModel({
    this.id,
    required this.monthKey,
    required this.monthlyLimit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month_key': monthKey,
      'monthly_limit': monthlyLimit,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as int?,
      monthKey: map['month_key'] as String,
      monthlyLimit: (map['monthly_limit'] as num).toDouble(),
    );
  }
}

class RecurringBill {
  final int? id;
  final String title;
  final double amount;
  final int categoryId;
  final String? categoryName;
  final String frequency; // 'Monthly', 'Yearly'
  final int dayOfMonth; // e.g., 5th of every month
  final bool isActive;

  RecurringBill({
    this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    this.categoryName,
    this.frequency = 'Monthly',
    required this.dayOfMonth,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category_id': categoryId,
      'frequency': frequency,
      'day_of_month': dayOfMonth,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory RecurringBill.fromMap(Map<String, dynamic> map) {
    return RecurringBill(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as int,
      categoryName: map['category_name'] as String?,
      frequency: map['frequency'] as String? ?? 'Monthly',
      dayOfMonth: map['day_of_month'] as int? ?? 1,
      isActive: (map['is_active'] as int?) == 1,
    );
  }
}
