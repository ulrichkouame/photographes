/// Repository for photographer dashboard KPIs.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Aggregated KPI data for the photographer dashboard.
class DashboardStats {
  const DashboardStats({
    required this.totalMissions,
    required this.revenue,
    required this.averageRating,
    required this.activeBookings,
    required this.pendingBookings,
  });

  final int totalMissions;
  final double revenue;
  final double averageRating;
  final int activeBookings;
  final int pendingBookings;
}

/// Provides KPIs and recent activity for the photographer dashboard.
class DashboardRepository {
  DashboardRepository(this._client);

  final SupabaseClient _client;

  /// Computes dashboard statistics for the currently authenticated photographer.
  Future<DashboardStats> getStats() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Non authentifié');

    final bookings = await _client
        .from('bookings')
        .select()
        .eq('photographer_id', userId);

    final list = List<Map<String, dynamic>>.from(bookings as List);

    final completed = list
        .where((b) => b['status'] == 'termine')
        .toList();
    final active = list
        .where((b) => b['status'] == 'accepte')
        .length;
    final pending = list
        .where((b) => b['status'] == 'en_attente')
        .length;

    final revenue = completed.fold<double>(
      0,
      (sum, b) => sum + ((b['contact_cost'] as num?)?.toDouble() ?? 0),
    );

    // Fetch average rating from profile
    final profile = await _client
        .from('profiles')
        .select('average_rating')
        .eq('id', userId)
        .maybeSingle();

    final avgRating =
        (profile?['average_rating'] as num?)?.toDouble() ?? 0.0;

    return DashboardStats(
      totalMissions: completed.length,
      revenue: revenue,
      averageRating: avgRating,
      activeBookings: active,
      pendingBookings: pending,
    );
  }
}
