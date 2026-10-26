import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/app_models.dart';
import '../theme/neo_glass_theme.dart';

class SettingsScreen extends StatefulWidget {
  final ScrollController scrollController;

  const SettingsScreen({super.key, required this.scrollController});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<CategoryModel> _categories = [];
  final _catNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await DatabaseHelper.instance.getAllCategories();
    setState(() {
      _categories = cats;
    });
  }

  Future<void> _addCategory() async {
    final name = _catNameController.text.trim();
    if (name.isEmpty) return;

    final cat = CategoryModel(
      name: name,
      iconName: 'category',
      colorHex: 0xFF8A62F6,
    );

    await DatabaseHelper.instance.insertCategory(cat);
    _catNameController.clear();
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Categories & Settings', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Info Box
            NeoContainer(
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Speny Expense Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Package: com.craftplex.speny', style: TextStyle(color: AppColors.subText, fontSize: 12)),
                  Text('Version: 0.0.1 (1)', style: TextStyle(color: AppColors.subText, fontSize: 12)),
                  SizedBox(height: 8),
                  Text('Time Format: BD 12H (Start: Sun, Off: Fri-Sat)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryPurple, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Add Category Section
            NeoContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Custom Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _catNameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                      onPressed: _addCategory,
                      child: const Text('Add Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text('Categories List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.category_outlined, color: AppColors.primaryPurple),
                      const SizedBox(width: 12),
                      Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
