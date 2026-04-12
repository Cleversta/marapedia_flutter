import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CategoryTabs extends StatelessWidget {
  final String? selected;
  final void Function(String category) onTap;
  final ScrollController? scrollController;
  final Map<String, int> counts;

  const CategoryTabs({
    super.key,
    this.selected,
    required this.onTap,
    this.scrollController,
    this.counts = const {},
  });

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold(0, (a, b) => a + b);

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E7EB)),
          SizedBox(
            height: 52,
            child: ListView.separated(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              itemCount: AppConstants.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final cat       = AppConstants.categories[i];
                final value     = cat['value']!;
                final isAll     = i == 0;
                final count     = isAll
                    ? (total > 0 ? total : null)
                    : counts[value];
                final isSelected = (selected == null && isAll) ||
                    selected == value;

                return _CategoryPill(
                  icon: cat['icon']!,
                  label: cat['label']!,
                  count: count,
                  isSelected: isSelected,
                  onTap: () => onTap(value),
                );
              },
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E7EB)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CategoryPill extends StatelessWidget {
  final String icon;
  final String label;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.icon,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          left: 10,
          right: count != null ? 6 : 10,
          top: 0,
          bottom: 0,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF15803D), Color(0xFF166534)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? const Color(0xFF166534) : const Color(0xFF9CA3AF),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF14532D).withOpacity(0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),

            // ── Count badge ──────────────────────────────────────────────
            if (count != null) ...[
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  // Active: white pill with green text
                  // Inactive: green-tinted pill with green text
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(999),
                  border: isSelected
                      ? null
                      : Border.all(color: const Color(0xFFBBF7D0), width: 1),
                ),
                child: Text(
                  _formatCount(count!),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? const Color(0xFF15803D)
                        : const Color(0xFF15803D),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}