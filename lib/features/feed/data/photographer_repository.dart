/// Supabase-backed repository for listing and filtering photographers.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/photographer_model.dart';
import '../domain/filter_model.dart';

/// Provides photographer listing with optional filtering.
class PhotographerRepository {
  PhotographerRepository(this._client);

  final SupabaseClient _client;

  /// Returns a list of photographers applying the provided [filter].
  Future<List<PhotographerModel>> getPhotographers({
    FilterModel? filter,
    int page = 0,
    int pageSize = 20,
  }) async {
    var query = _client
        .from('profiles')
        .select()
        .eq('role', 'PHOTOGRAPHE');

    if (filter?.category != null && filter!.category!.isNotEmpty) {
      query = query.contains('specialties', [filter.category]);
    }
    if (filter?.commune != null && filter!.commune!.isNotEmpty) {
      query = query.eq('city', filter.commune!);
    }
    if (filter?.maxBudget != null) {
      query = query.lte('price_per_hour', filter!.maxBudget!);
    }
    if (filter?.minRating != null) {
      query = query.gte('average_rating', filter!.minRating!);
    }

    final response = await query
        .order('average_rating', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);

    return (response as List)
        .map((e) => PhotographerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns a single photographer by [id].
  Future<PhotographerModel?> getPhotographerById(String id) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return PhotographerModel.fromJson(response);
  }
}
