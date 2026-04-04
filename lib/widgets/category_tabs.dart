import 'package:flutter/material.dart';
import '../utils/constants.dart';

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
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        itemCount: AppConstants.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final cat = AppConstants.categories[i];
          final isSelected = selected == cat['value'];
          return GestureDetector(
            onTap: () => onTap(cat['value']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF15803D) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF166534) : const Color(0xFF9CA3AF),
                  width: isSelected ? 2 : 1.5,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: const Color(0xFF14532D).withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat['icon']!, style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                  Text(
                    cat['label']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
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