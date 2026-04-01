import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/app_theme.dart';

class CategoryTabs extends StatelessWidget {
  final String? selected;
  final void Function(String category) onTap;
  final ScrollController? scrollController;

  const CategoryTabs({super.key, this.selected, required this.onTap, this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: AppConstants.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final cat = AppConstants.categories[i];
          final isSelected = selected == cat['value'];
          return GestureDetector(
            onTap: () => onTap(cat['value']!),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.greenPrimary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.greenPrimary : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat['icon']!, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    cat['label']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
