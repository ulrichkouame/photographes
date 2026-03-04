/// Payment repository: mobile money operator selection and payment API calls.
library;

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/payment_model.dart';

/// Handles payment initiation and status queries.
class PaymentRepository {
  PaymentRepository(this._client, this._dio);

  final SupabaseClient _client;
  final Dio _dio;

  /// Initiates a mobile money payment for [bookingId].
  ///
  /// [paymentApiUrl] is fetched from app settings.
  Future<PaymentModel> initiatePayment({
    required String bookingId,
    required double amount,
    required String operator,
    required String phoneNumber,
    required String paymentApiUrl,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Non authentifié');

    // Call external payment API
    final response = await _dio.post(
      paymentApiUrl,
      data: {
        'booking_id': bookingId,
        'amount': amount,
        'operator': operator,
        'phone': phoneNumber,
        'user_id': userId,
      },
    );

    final transactionId =
        response.data['transaction_id'] as String? ?? '';

    // Record in Supabase
    final record = await _client
        .from('photographes_payments')
        .insert({
          'booking_id': bookingId,
          'amount': amount,
          'operator': operator,
          'phone_number': phoneNumber,
          'status': 'pending',
          'transaction_id': transactionId,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return PaymentModel.fromJson(record);
  }

  /// Returns the payment associated with [bookingId].
  Future<PaymentModel?> getPaymentForBooking(String bookingId) async {
    final data = await _client
        .from('photographes_payments')
        .select()
        .eq('booking_id', bookingId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (data == null) return null;
    return PaymentModel.fromJson(data);
  }
}
