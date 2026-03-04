/// Domain model for a mobile money payment transaction.
library;

/// Represents a payment record in the `payments` table.
class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.operator,
    required this.phoneNumber,
    required this.status,
    this.transactionId,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final double amount;
  final String operator;
  final String phoneNumber;
  final String status;
  final String? transactionId;
  final DateTime createdAt;

  /// Parses a [PaymentModel] from a JSON map.
  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: json['id'] as String,
        bookingId: json['booking_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        operator: json['operator'] as String,
        phoneNumber: json['phone_number'] as String,
        status: json['status'] as String,
        transactionId: json['transaction_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'booking_id': bookingId,
        'amount': amount,
        'operator': operator,
        'phone_number': phoneNumber,
        'status': status,
        'transaction_id': transactionId,
        'created_at': createdAt.toIso8601String(),
      };
}
