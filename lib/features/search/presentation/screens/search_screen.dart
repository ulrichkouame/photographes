/// Search screen with sticky search bar and advanced filter bottom sheet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../feed/domain/filter_model.dart';
import '../../../feed/presentation/providers/feed_provider.dart';
import '../../../feed/presentation/widgets/photographer_card.dart';

/// Full-featured search screen with text + multi-filter capabilities.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(photographerFeedProvider);
    final filter = ref.watch(filterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche'),
        actions: [
          if (filter.hasActiveFilter)
            TextButton(
              onPressed: () =>
                  ref.read(filterProvider.notifier).resetAll(),
              child: const Text('Réinitialiser'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Sticky search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Chercher un photographe…',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _openFilterSheet,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.black,
                  ),
                  icon: Stack(
                    children: [
                      const Icon(Icons.tune),
                      if (filter.hasActiveFilter)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: feedAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (photographers) {
                final query = _searchController.text.toLowerCase();
                final filtered = query.isEmpty
                    ? photographers
                    : photographers
                        .where((p) =>
                            p.name.toLowerCase().contains(query) ||
                            (p.city?.toLowerCase().contains(query) ?? false))
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun résultat',
                      style: TextStyle(color: AppColors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => PhotographerCard(
                    photographer: filtered[index],
                    onTap: () =>
                        context.push('/photographer/${filtered[index].id}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter bottom sheet
// ---------------------------------------------------------------------------

class _FilterBottomSheet extends ConsumerStatefulWidget {
  const _FilterBottomSheet();

  @override
  ConsumerState<_FilterBottomSheet> createState() =>
      _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<_FilterBottomSheet> {
  late FilterModel _localFilter;

  @override
  void initState() {
    super.initState();
    _localFilter = ref.read(filterProvider);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _localFilter.availableDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: AppColors.gold),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() =>
          _localFilter = _localFilter.copyWith(availableDate: picked));
    }
  }

  void _applyFilter() {
    final notifier = ref.read(filterProvider.notifier);
    notifier.updateCategory(_localFilter.category);
    notifier.updateCommune(_localFilter.commune);
    notifier.updateBudget(_localFilter.maxBudget);
    notifier.updateRating(_localFilter.minRating);
    notifier.updateDate(_localFilter.availableDate);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (ctx, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Text('Filtres',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                )),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(
                          () => _localFilter = const FilterModel()),
                      child: const Text('Réinitialiser'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // Category
                    Text('Catégorie',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.specialties.map((s) {
                        final selected = _localFilter.category == s;
                        return FilterChip(
                          label: Text(s),
                          selected: selected,
                          onSelected: (_) => setState(() {
                            _localFilter = _localFilter.copyWith(
                              category: selected ? null : s,
                              clearCategory: selected,
                            );
                          }),
                          selectedColor: AppColors.gold,
                          checkmarkColor: AppColors.black,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // Commune
                    Text('Commune',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _localFilter.commune,
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Toutes')),
                        ...AppConstants.communes.map(
                          (c) => DropdownMenuItem(value: c, child: Text(c)),
                        ),
                      ],
                      decoration: const InputDecoration(
                          labelText: 'Sélectionner une commune'),
                      onChanged: (v) => setState(
                          () => _localFilter = _localFilter.copyWith(
                                commune: v,
                                clearCommune: v == null,
                              )),
                    ),
                    const SizedBox(height: 20),
                    // Budget slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Budget max',
                            style: Theme.of(context).textTheme.titleSmall),
                        Text(
                          _localFilter.maxBudget != null
                              ? '${_localFilter.maxBudget!.toStringAsFixed(0)} FCFA'
                              : 'Illimité',
                          style: const TextStyle(color: AppColors.gold),
                        ),
                      ],
                    ),
                    Slider(
                      value: _localFilter.maxBudget ?? 500000,
                      min: 5000,
                      max: 500000,
                      divisions: 100,
                      activeColor: AppColors.gold,
                      onChanged: (v) => setState(
                          () => _localFilter = _localFilter.copyWith(
                                maxBudget: v < 500000 ? v : null,
                                clearBudget: v >= 500000,
                              )),
                    ),
                    const SizedBox(height: 16),
                    // Min rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Note minimale',
                            style: Theme.of(context).textTheme.titleSmall),
                        Text(
                          _localFilter.minRating != null
                              ? '${_localFilter.minRating!.toStringAsFixed(1)} ★'
                              : 'Toutes',
                          style: const TextStyle(color: AppColors.gold),
                        ),
                      ],
                    ),
                    Slider(
                      value: _localFilter.minRating ?? 0,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      activeColor: AppColors.gold,
                      onChanged: (v) => setState(
                          () => _localFilter = _localFilter.copyWith(
                                minRating: v > 0 ? v : null,
                                clearRating: v == 0,
                              )),
                    ),
                    const SizedBox(height: 16),
                    // Date picker
                    Text('Disponible le',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        _localFilter.availableDate != null
                            ? DateFormat('dd/MM/yyyy')
                                .format(_localFilter.availableDate!)
                            : 'Choisir une date',
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: ElevatedButton(
                  onPressed: _applyFilter,
                  child: const Text('Appliquer les filtres'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
