/// Repository for fetching photographer profile, portfolio, and reviews.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/portfolio_photo_model.dart';
import '../domain/review_model.dart';
import '../../../feed/domain/photographer_model.dart';

/// Handles all data access for a photographer's full public profile.
class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  /// Fetches a photographer's full profile by [id].
  Future<PhotographerModel?> getProfile(String id) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return PhotographerModel.fromJson(data);
  }

  /// Returns portfolio photos for the photographer [photographerId].
  Future<List<PortfolioPhoto>> getPortfolioPhotos(String photographerId) async {
    final data = await _client
        .from('portfolio_photos')
        .select()
        .eq('photographer_id', photographerId)
        .order('sort_order');
    return (data as List)
        .map((e) => PortfolioPhoto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns reviews for the photographer [photographerId].
  Future<List<Review>> getReviews(String photographerId) async {
    final data = await _client
        .from('reviews')
        .select()
        .eq('photographer_id', photographerId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns dates when the photographer is available.
  Future<List<DateTime>> getAvailableDates(String photographerId) async {
    final data = await _client
        .from('availability')
        .select('date')
        .eq('photographer_id', photographerId)
        .eq('is_available', true);
    return (data as List)
        .map((e) => DateTime.parse(e['date'] as String))
        .toList();
  }
}
