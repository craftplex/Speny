import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/app_models.dart';
import '../theme/neo_glass_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_components.dart';

class AddEditExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddEditExpenseScreen({super.key, this.expense});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _titleController;
  late final TextEditingController _vendorController;

  int? _selectedCategoryId;
  DateTime _selectedDateTime = DateTime.now();
  ExpenseType _expenseType = ExpenseType.need;
  bool _isRecurring = false;
  bool _isSaving = false;
  bool _isLoading = true;
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _amountController = TextEditingController(
      text: expense?.amount.toString() ?? '',
    );
    _titleController = TextEditingController(text: expense?.title ?? '');
    _vendorController = TextEditingController(text: expense?.vendor ?? '');
    if (expense != null) {
      _selectedCategoryId = expense.categoryId;
      _selectedDateTime = expense.dateTime;
      _expenseType = expense.type;
      _isRecurring = expense.isRecurring;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await DatabaseHelper.instance.getAllCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _selectedCategoryId ??=
          categories.isEmpty ? null : categories.first.id;
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
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null || !mounted) return;

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
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a category before saving an expense.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final expense = Expense(
      id: widget.expense?.id,
      amount: double.parse(_amountController.text.trim()),
      categoryId: _selectedCategoryId!,
      dateTime: _selectedDateTime,
      title: _titleController.text.trim(),
      vendor: _vendorController.text.trim().isEmpty
          ? null
          : _vendorController.text.trim(),
      type: _expenseType,
      isRecurring: _isRecurring,
    );

    if (widget.expense == null) {
      await DatabaseHelper.instance.insertExpense(expense);
    } else {
      await DatabaseHelper.instance.updateExpense(expense);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
        ),
        title: Text(isEditing ? 'Edit expense' : 'Add expense'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  PageHeading(
                    title: isEditing ? 'Update your expense' : 'What did you spend?',
                    subtitle: 'A few details help make your spending clearer.',
                  ),
                  NeoContainer(
                    padding: const EdgeInsets.all(18),
                    backgroundColor: AppColors.paleGreen,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AMOUNT',
                          style: TextStyle(
                            color: AppColors.subText,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.9,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          autofocus: !isEditing,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(
                            color: AppColors.darkText,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0',
                            suffixText: 'TK',
                          ),
                          validator: (value) {
                            final amount =
                                double.tryParse(value?.trim() ?? '');
                            if (amount == null || amount <= 0) {
                              return 'Enter an amount greater than zero';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SectionHeading(title: 'Description'),
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Lunch with friends',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Add a short description'
                        : null,
                  ),
                  const SizedBox(height: 22),
                  const SectionHeading(title: 'Category'),
                  if (_categories.isEmpty)
                    const NeoContainer(
                      child: EmptyState(
                        icon: Icons.category_outlined,
                        title: 'No categories available',
                        message:
                            'Create a category in Your space before adding an expense.',
                      ),
                    )
                  else
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: _categories.map((category) {
                        final selected = category.id == _selectedCategoryId;
                        final color = categoryColorFor(category.name);
                        return ChoiceChip(
                          avatar: Icon(
                            iconForCategory(category.iconName, category.name),
                            size: 17,
                            color: selected ? Colors.white : color,
                          ),
                          label: Text(category.name),
                          selected: selected,
                          showCheckmark: false,
                          onSelected: (_) =>
                              setState(() => _selectedCategoryId = category.id),
                          backgroundColor: AppColors.cardBg,
                          selectedColor: AppColors.primaryPurple,
                          side: BorderSide(
                            color: selected ? AppColors.primaryPurple : AppColors.line,
                          ),
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.darkText,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 22),
                  const SectionHeading(title: 'Type'),
                  SegmentedButton<ExpenseType>(
                    segments: const [
                      ButtonSegment(
                        value: ExpenseType.need,
                        label: Text('Need'),
                        icon: Icon(Icons.check_circle_outline_rounded),
                      ),
                      ButtonSegment(
                        value: ExpenseType.want,
                        label: Text('Want'),
                        icon: Icon(Icons.favorite_border_rounded),
                      ),
                    ],
                    selected: {_expenseType},
                    onSelectionChanged: (selection) =>
                        setState(() => _expenseType = selection.first),
                  ),
                  const SizedBox(height: 22),
                  const SectionHeading(title: 'Details'),
                  TextFormField(
                    controller: _vendorController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Shop or merchant (optional)',
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                  ),
                  const SizedBox(height: 11),
                  NeoContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 3,
                    ),
                    onTap: _pickDateTime,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: AppColors.primaryPurple,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Date and time',
                            style: TextStyle(
                              color: AppColors.darkText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          Formatters.formatDateTimeBD(_selectedDateTime),
                          style: const TextStyle(
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.subText),
                      ],
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: const Text(
                      'Recurring expense',
                      style: TextStyle(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text('Mark this as a regular payment'),
                    value: _isRecurring,
                    onChanged: (value) => setState(() => _isRecurring = value),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _saveExpense,
                      child: _isSaving
                          ? const SizedBox(
                              width: 21,
                              height: 21,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEditing ? 'Save changes' : 'Save expense'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
