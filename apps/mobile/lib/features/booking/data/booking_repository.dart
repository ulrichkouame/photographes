/// Repository for booking CRUD operations on Supabase.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/booking_model.dart';

/// Manages booking request creation, status updates, and cancellation.
class BookingRepository {
  BookingRepository(this._client);

  final SupabaseClient _client;

  /// Creates a new booking request in the `bookings` table.
  Future<BookingModel> createBooking({
    required String photographerId,
    required String serviceType,
    required DateTime date,
    required String location,
    required String message,
    required double contactCost,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Non authentifié');

    final data = await _client
        .from('bookings')
        .insert({
          'client_id': userId,
          'photographer_id': photographerId,
          'service_type': serviceType,
          'date': date.toIso8601String(),
          'location': location,
          'message': message,
          'status': 'en_attente',
          'contact_cost': contactCost,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return BookingModel.fromJson(data);
  }

  /// Returns a single booking by [id].
  Future<BookingModel?> getBooking(String id) async {
    final data = await _client
        .from('bookings')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return BookingModel.fromJson(data);
  }

  /// Returns all bookings for the current client, newest first.
  Future<List<BookingModel>> getClientBookings({
    int page = 0,
    int pageSize = 20,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from('bookings')
        .select()
        .eq('client_id', userId)
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return (data as List)
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns all bookings for a photographer.
  Future<List<BookingModel>> getPhotographerBookings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from('bookings')
        .select()
        .eq('photographer_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Updates the booking [id] status to [newStatus].
  Future<void> updateStatus(String id, String newStatus) async {
    await _client
        .from('bookings')
        .update({'status': newStatus})
        .eq('id', id);
  }

  /// Cancels a booking.
  Future<void> cancelBooking(String id) => updateStatus(id, 'annule');
}
