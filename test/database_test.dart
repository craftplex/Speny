import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:speny/database/database_helper.dart';
import 'package:speny/models/app_models.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Database CRUD operations for expenses and categories', () async {
    final db = DatabaseHelper.instance;

    final categories = await db.getAllCategories();
    expect(categories.length, greaterThan(0));

    final initialExpenses = await db.getAllExpenses();
    final initialLength = initialExpenses.length;

    final testExpense = Expense(
      amount: 1500.0,
      categoryId: categories.first.id!,
      dateTime: DateTime.now(),
      title: 'খাবার রিকশ ভাড়া (Lunch & Rickshaw)',
      vendor: 'Foodpanda',
      type: ExpenseType.need,
    );

    final id = await db.insertExpense(testExpense);
    expect(id, greaterThan(0));

    final expenses = await db.getAllExpenses();
    expect(expenses.length, equals(initialLength + 1));
    expect(expenses.first.title, 'খাবার রিকশ ভাড়া (Lunch & Rickshaw)');
    expect(expenses.first.vendor, 'Foodpanda');
  });
}
