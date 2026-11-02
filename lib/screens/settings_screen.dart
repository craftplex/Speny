import 'package:flutter/material.dart';
import '../app_metadata.dart';
import '../database/database_helper.dart';
import '../models/app_models.dart';
import '../theme/neo_glass_theme.dart';
import '../widgets/app_components.dart';

class SettingsScreen extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onDataChanged;

  const SettingsScreen({
    super.key,
    required this.scrollController,
    required this.onDataChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _catNameController = TextEditingController();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _catNameController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await DatabaseHelper.instance.getAllCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  Future<void> _addCategory() async {
    final name = _catNameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Enter a category name first.');
      return;
    }

    if (_categories.any((category) =>
        category.name.toLowerCase() == name.toLowerCase())) {
      _showMessage('That category already exists.');
      return;
    }

    await DatabaseHelper.instance.insertCategory(
      CategoryModel(
        name: name,
        iconName: 'category',
        colorHex: AppColors.primaryPurple.toARGB32(),
      ),
    );
    if (!mounted) return;
    _catNameController.clear();
    await _loadCategories();
    widget.onDataChanged();
    _showMessage('Category added.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCategories,
          color: AppColors.primaryPurple,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  controller: widget.scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 124),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageHeading(
                        title: 'Your space',
                        subtitle: 'A few details that make Speny yours.',
                        trailing: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AppColors.accentLightPurple,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ),
                      NeoContainer(
                        padding: const EdgeInsets.all(20),
                        backgroundColor: AppColors.primaryPurple,
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.spa_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Speny',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Your money, made clearer.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'v${AppMetadata.version}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      const SectionHeading(title: 'Categories'),
                      NeoContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Make your spending easier to organize.',
                              style: TextStyle(
                                color: AppColors.subText,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _catNameController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. Pet care',
                                      prefixIcon: Icon(Icons.sell_outlined),
                                    ),
                                    onSubmitted: (_) => _addCategory(),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                IconButton.filled(
                                  onPressed: _addCategory,
                                  tooltip: 'Add category',
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.primaryPurple,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(52, 52),
                                  ),
                                  icon: const Icon(Icons.add_rounded),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 13),
                              child: Divider(height: 1),
                            ),
                            if (_categories.isEmpty)
                              const EmptyState(
                                icon: Icons.category_outlined,
                                title: 'No categories yet',
                                message: 'Your categories will appear here.',
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _categories.map((category) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: AppColors.line),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.sell_outlined,
                                          size: 15,
                                          color: AppColors.primaryPurple,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          category.name,
                                          style: const TextStyle(
                                            color: AppColors.darkText,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      NeoContainer(
                        padding: const EdgeInsets.all(17),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.primaryPurple,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Private by design',
                                    style: TextStyle(
                                      color: AppColors.darkText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Your expense records are stored locally on this device.',
                                    style: TextStyle(
                                      color: AppColors.subText,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          'Speny · build ${AppMetadata.buildNumber}',
                          style: const TextStyle(
                            color: AppColors.subText,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
