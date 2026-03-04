/// Domain model for search/filter parameters.
library;

/// Encapsulates all filtering options for the photographer search.
class FilterModel {
  const FilterModel({
    this.category,
    this.commune,
    this.maxBudget,
    this.minRating,
    this.availableDate,
  });

  final String? category;
  final String? commune;
  final double? maxBudget;
  final double? minRating;
  final DateTime? availableDate;

  /// Returns `true` if any filter is active.
  bool get hasActiveFilter =>
      (category != null && category!.isNotEmpty) ||
      (commune != null && commune!.isNotEmpty) ||
      maxBudget != null ||
      minRating != null ||
      availableDate != null;

  /// Returns a copy with changed fields.
  FilterModel copyWith({
    String? category,
    String? commune,
    double? maxBudget,
    double? minRating,
    DateTime? availableDate,
    bool clearCategory = false,
    bool clearCommune = false,
    bool clearBudget = false,
    bool clearRating = false,
    bool clearDate = false,
  }) {
    return FilterModel(
      category: clearCategory ? null : (category ?? this.category),
      commune: clearCommune ? null : (commune ?? this.commune),
      maxBudget: clearBudget ? null : (maxBudget ?? this.maxBudget),
      minRating: clearRating ? null : (minRating ?? this.minRating),
      availableDate: clearDate ? null : (availableDate ?? this.availableDate),
    );
  }
}
