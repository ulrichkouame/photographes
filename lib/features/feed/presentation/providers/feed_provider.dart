/// Riverpod providers for the photographer feed and filter state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/photographer_repository.dart';
import '../../domain/filter_model.dart';
import '../../domain/photographer_model.dart';

/// Provides a singleton [PhotographerRepository].
final photographerRepositoryProvider = Provider<PhotographerRepository>((ref) {
  return PhotographerRepository(Supabase.instance.client);
});

/// Manages the current filter state.
class FilterNotifier extends StateNotifier<FilterModel> {
  FilterNotifier() : super(const FilterModel());

  void updateCategory(String? category) {
    state = state.copyWith(
      category: category,
      clearCategory: category == null,
    );
  }

  void updateCommune(String? commune) {
    state = state.copyWith(
      commune: commune,
      clearCommune: commune == null,
    );
  }

  void updateBudget(double? budget) {
    state = state.copyWith(
      maxBudget: budget,
      clearBudget: budget == null,
    );
  }

  void updateRating(double? rating) {
    state = state.copyWith(
      minRating: rating,
      clearRating: rating == null,
    );
  }

  void updateDate(DateTime? date) {
    state = state.copyWith(
      availableDate: date,
      clearDate: date == null,
    );
  }

  void resetAll() => state = const FilterModel();
}

/// StateNotifierProvider for the active filter.
final filterProvider = StateNotifierProvider<FilterNotifier, FilterModel>(
  (ref) => FilterNotifier(),
);

/// FutureProvider that fetches photographers with the current filter applied.
final photographerFeedProvider =
    FutureProvider.autoDispose<List<PhotographerModel>>((ref) async {
  final repo = ref.watch(photographerRepositoryProvider);
  final filter = ref.watch(filterProvider);
  return repo.getPhotographers(filter: filter);
});
