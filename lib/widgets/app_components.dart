import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../theme/neo_glass_theme.dart';
import '../utils/formatters.dart';

class PageHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const PageHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 26,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeading({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryPurple,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 36),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String label;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Tooltip(
            message: label,
            child: Icon(icon, size: 21, color: AppColors.darkText),
          ),
        ),
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.expense, this.onTap});

  @override
  Widget build(BuildContext context) {
    final categoryColor = categoryColorFor(expense.categoryName);
    final subtitle = [
      if (expense.categoryName != null && expense.categoryName!.isNotEmpty)
        expense.categoryName!,
      Formatters.formatTimeBD(expense.dateTime),
    ].join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  iconForCategory(expense.categoryIcon, expense.categoryName),
                  color: categoryColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '-${Formatters.formatMoney(expense.amount, short: true)}',
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppColors.paleGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryPurple, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

Color categoryColorFor(String? category) {
  final name = (category ?? '').toLowerCase();
  if (name.contains('food') || name.contains('dining')) {
    return const Color(0xFFE59B3F);
  }
  if (name.contains('transport') || name.contains('travel')) {
    return const Color(0xFF5286D8);
  }
  if (name.contains('shop')) return const Color(0xFF9A72D5);
  if (name.contains('bill') || name.contains('home')) {
    return const Color(0xFF348B77);
  }
  if (name.contains('health')) return const Color(0xFFE16D77);
  return AppColors.primaryPurple;
}

IconData iconForCategory(String? iconName, String? categoryName) {
  const icons = <String, IconData>{
    'fastfood': Icons.restaurant_rounded,
    'restaurant': Icons.restaurant_rounded,
    'directions_bus': Icons.directions_bus_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'home': Icons.home_rounded,
    'category': Icons.category_rounded,
    'medical_services': Icons.medical_services_rounded,
    'school': Icons.school_rounded,
    'receipt': Icons.receipt_long_rounded,
  };
  final byIcon = icons[iconName];
  if (byIcon != null) return byIcon;

  final name = (categoryName ?? '').toLowerCase();
  if (name.contains('food') || name.contains('dining')) {
    return Icons.restaurant_rounded;
  }
  if (name.contains('transport') || name.contains('travel')) {
    return Icons.directions_bus_rounded;
  }
  if (name.contains('shop')) return Icons.shopping_bag_rounded;
  if (name.contains('bill') || name.contains('home')) {
    return Icons.home_rounded;
  }
  if (name.contains('health')) return Icons.medical_services_rounded;
  return Icons.category_rounded;
}
