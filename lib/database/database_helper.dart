import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/app_models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('speny.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType,
        icon_name $textType,
        color_hex $intType,
        budget REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id $idType,
        amount $realType,
        category_id $intType,
        date_time $textType,
        title $textType,
        vendor TEXT,
        type $textType,
        is_recurring $intType DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id $idType,
        month_key TEXT UNIQUE NOT NULL,
        monthly_limit $realType
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_bills (
        id $idType,
        title $textType,
        amount $realType,
        category_id $intType,
        frequency $textType,
        day_of_month $intType,
        is_active $intType DEFAULT 1,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Seed default categories
    await _seedDefaultCategories(db);
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final defaultCategories = [
      {'name': 'Food & Dining', 'icon_name': 'fastfood', 'color_hex': 0xFFFF5722},
      {'name': 'Transportation', 'icon_name': 'directions_bus', 'color_hex': 0xFF2196F3},
      {'name': 'Bills & Utilities', 'icon_name': 'receipt', 'color_hex': 0xFF9C27B0},
      {'name': 'Education & Books', 'icon_name': 'school', 'color_hex': 0xFF4CAF50},
      {'name': 'Entertainment', 'icon_name': 'movie', 'color_hex': 0xFFE91E63},
      {'name': 'Shopping', 'icon_name': 'shopping_bag', 'color_hex': 0xFFFF9800},
      {'name': 'Health & Fitness', 'icon_name': 'fitness_center', 'color_hex': 0xFF00BCD4},
    ];

    for (var cat in defaultCategories) {
      await db.insert('categories', cat);
    }

    // Default monthly budget: 50,000 TK
    final now = DateTime.now();
    final currentMonthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    await db.insert('budgets', {
      'month_key': currentMonthKey,
      'monthly_limit': 50000.0,
    });
  }

  // --- Category CRUD ---
  Future<int> insertCategory(CategoryModel category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'id ASC');
    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await instance.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // --- Expense CRUD ---
  Future<int> insertExpense(Expense expense) async {
    final db = await instance.database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT e.*, c.name as category_name, c.icon_name as category_icon
      FROM expenses e
      LEFT JOIN categories c ON e.category_id = c.id
      ORDER BY e.date_time DESC
    ''');
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await instance.database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Budget Methods ---
  Future<double> getMonthlyBudget(String monthKey) async {
    final db = await instance.database;
    final result = await db.query(
      'budgets',
      where: 'month_key = ?',
      whereArgs: [monthKey],
    );
    if (result.isNotEmpty) {
      return (result.first['monthly_limit'] as num).toDouble();
    }
    return 50000.0; // Default if not explicitly configured
  }

  Future<void> setMonthlyBudget(String monthKey, double limit) async {
    final db = await instance.database;
    await db.insert(
      'budgets',
      {'month_key': monthKey, 'monthly_limit': limit},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Recurring Bills CRUD ---
  Future<int> insertRecurringBill(RecurringBill bill) async {
    final db = await instance.database;
    return await db.insert('recurring_bills', bill.toMap());
  }

  Future<List<RecurringBill>> getAllRecurringBills() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT r.*, c.name as category_name
      FROM recurring_bills r
      LEFT JOIN categories c ON r.category_id = c.id
      ORDER BY r.day_of_month ASC
    ''');
    return result.map((json) => RecurringBill.fromMap(json)).toList();
  }

  Future<int> deleteRecurringBill(int id) async {
    final db = await instance.database;
    return await db.delete(
      'recurring_bills',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
