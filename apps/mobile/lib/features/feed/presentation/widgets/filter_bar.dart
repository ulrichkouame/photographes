/// Horizontally scrollable filter chip bar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../providers/feed_provider.dart';

/// Shows a row of category filter chips.
class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);
    final categories = ['Tous', ...AppConstants.specialties];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isAll = category == 'Tous';
          final isSelected = isAll
              ? (filter.category == null || filter.category!.isEmpty)
              : filter.category == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) {
                ref.read(filterProvider.notifier).updateCategory(
                      isAll ? null : category,
                    );
              },
              selectedColor: AppColors.gold,
              checkmarkColor: AppColors.black,
            ),
          );
        },
      ),
    );
  }
}
