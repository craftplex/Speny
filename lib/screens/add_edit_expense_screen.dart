import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/app_models.dart';
import '../utils/formatters.dart';

class AddEditExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddEditExpenseScreen({super.key, this.expense});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  late TextEditingController _titleController;
  late TextEditingController _vendorController;

  int? _selectedCategoryId;
  DateTime _selectedDateTime = DateTime.now();
  ExpenseType _expenseType = ExpenseType.need;
  bool _isRecurring = false;

  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.expense != null ? widget.expense!.amount.toInt().toString() : '',
    );
    _titleController = TextEditingController(text: widget.expense?.title ?? '');
    _vendorController = TextEditingController(text: widget.expense?.vendor ?? '');

    if (widget.expense != null) {
      _selectedCategoryId = widget.expense!.categoryId;
      _selectedDateTime = widget.expense!.dateTime;
      _expenseType = widget.expense!.type;
      _isRecurring = widget.expense!.isRecurring;
    }

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await DatabaseHelper.instance.getAllCategories();
    setState(() {
      _categories = cats;
      if (_selectedCategoryId == null && _categories.isNotEmpty) {
        _selectedCategoryId = _categories.first.id;
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _vendorController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) return;

    final amount = double.parse(_amountController.text.trim());
    final title = _titleController.text.trim();
    final vendor = _vendorController.text.trim().isEmpty ? null : _vendorController.text.trim();

    final expense = Expense(
      id: widget.expense?.id,
      amount: amount,
      categoryId: _selectedCategoryId!,
      dateTime: _selectedDateTime,
      title: title,
      vendor: vendor,
      type: _expenseType,
      isRecurring: _isRecurring,
    );

    if (widget.expense == null) {
      await DatabaseHelper.instance.insertExpense(expense);
    } else {
      await DatabaseHelper.instance.updateExpense(expense);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.expense == null ? 'Add Expense' : 'Edit Expense',
          style: const TextStyle(color: Color(0xFF1D1E2C), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1D1E2C)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Field
                    const Text('Amount (Taka)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7A7E9A))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Color(0xFFD3D8E5), blurRadius: 10, offset: Offset(3, 3)),
                          BoxShadow(color: Colors.white, blurRadius: 10, offset: Offset(-3, -3)),
                        ],
                      ),
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF8A62F6)),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'e.g. 500',
                          suffixText: 'TK',
                          suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8A62F6)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty || double.tryParse(value) == null) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Title Field (Bengali or English)
                    const Text('Description / Title (Bengali/English allowed)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7A7E9A))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Color(0xFFD3D8E5), blurRadius: 10, offset: Offset(3, 3)),
                          BoxShadow(color: Colors.white, blurRadius: 10, offset: Offset(-3, -3)),
                        ],
                      ),
                      child: TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'e.g. দুপুরের খাবার / Lunch with friends',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Category Selector
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7A7E9A))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Color(0xFFD3D8E5), blurRadius: 10, offset: Offset(3, 3)),
                          BoxShadow(color: Colors.white, blurRadius: 10, offset: Offset(-3, -3)),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedCategoryId,
                          isExpanded: true,
                          items: _categories.map((cat) {
                            return DropdownMenuItem<int>(
                              value: cat.id,
                              child: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategoryId = val);
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Need vs Want Selector (50/30/20 Rule)
                    const Text('Expense Type (Need vs Want)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7A7E9A))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _expenseType = ExpenseType.need),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _expenseType == ExpenseType.need ? const Color(0xFF8A62F6) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(color: Color(0xFFD3D8E5), blurRadius: 8, offset: Offset(3, 3)),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'Need (ضروری)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _expenseType == ExpenseType.need ? Colors.white : const Color(0xFF1D1E2C),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _expenseType = ExpenseType.want),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _expenseType == ExpenseType.want ? const Color(0xFF8A62F6) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(color: Color(0xFFD3D8E5), blurRadius: 8, offset: Offset(3, 3)),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'Want (ইচ্ছা)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _expenseType == ExpenseType.want ? Colors.white : const Color(0xFF1D1E2C),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Merchant / Vendor Input
                    const Text('Merchant / Vendor (Optional)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7A7E9A))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Color(0xFFD3D8E5), blurRadius: 10, offset: Offset(3, 3)),
                        ],
                      ),
                      child: TextFormField(
                        controller: _vendorController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'e.g. Foodpanda, Pathao, Shwapno',
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Date & Time Picker Button (BD 12H Format)
                    GestureDetector(
                      onTap: _pickDateTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Color(0xFFD3D8E5), blurRadius: 10, offset: Offset(3, 3)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, color: Color(0xFF8A62F6)),
                                SizedBox(width: 12),
                                Text('Date & Time (BD 12H)', style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Text(
                              Formatters.formatDateTimeBD(_selectedDateTime),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8A62F6)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8A62F6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 6,
                        ),
                        onPressed: _saveExpense,
                        child: const Text(
                          'Save Expense',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
