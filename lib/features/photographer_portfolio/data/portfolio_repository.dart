/// Portfolio management repository: upload, reorder, featured toggle, delete.
library;

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../photographer_profile/domain/portfolio_photo_model.dart';

/// Handles all portfolio photo operations for the authenticated photographer.
class PortfolioManagementRepository {
  PortfolioManagementRepository(this._client);

  final SupabaseClient _client;

  String get _userId => _client.auth.currentUser?.id ?? '';

  /// Returns the photographer's portfolio photos ordered by sort_order.
  Future<List<PortfolioPhoto>> getMyPhotos() async {
    final data = await _client
        .from('portfolio_photos')
        .select()
        .eq('photographer_id', _userId)
        .order('sort_order');
    return (data as List)
        .map((e) => PortfolioPhoto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Uploads [file] to Supabase Storage and inserts a record in the DB.
  Future<PortfolioPhoto> uploadPhoto(File file) async {
    final filename = '${_userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage
        .from('portfolio')
        .upload(filename, file, fileOptions: const FileOptions(upsert: true));

    final url = _client.storage.from('portfolio').getPublicUrl(filename);

    // Determine the next sort_order by reading the current maximum.
    final existing = await _client
        .from('portfolio_photos')
        .select('sort_order')
        .eq('photographer_id', _userId)
        .order('sort_order', ascending: false)
        .limit(1);
    final maxOrder =
        (existing as List).isNotEmpty ? ((existing.first['sort_order'] as int?) ?? 0) : 0;

    final record = await _client
        .from('portfolio_photos')
        .insert({
          'photographer_id': _userId,
          'url': url,
          'thumbnail_url': url,
          'is_featured': false,
          'sort_order': maxOrder + 1,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return PortfolioPhoto.fromJson(record);
  }

  /// Deletes a photo by [photoId] from storage and DB.
  Future<void> deletePhoto(String photoId, String url) async {
    await _client.from('portfolio_photos').delete().eq('id', photoId);
    // Attempt to delete from storage (non-critical)
    try {
      final path = Uri.parse(url).path.split('/portfolio/').last;
      await _client.storage.from('portfolio').remove([path]);
    } catch (_) {}
  }

  /// Toggles the featured status of a photo.
  Future<void> setFeatured(String photoId, {required bool isFeatured}) async {
    await _client
        .from('portfolio_photos')
        .update({'is_featured': isFeatured})
        .eq('id', photoId);
  }

  /// Updates the sort order for a batch of photos.
  Future<void> reorder(List<PortfolioPhoto> photos) async {
    for (var i = 0; i < photos.length; i++) {
      await _client
          .from('portfolio_photos')
          .update({'sort_order': i})
          .eq('id', photos[i].id);
    }
  }
}
