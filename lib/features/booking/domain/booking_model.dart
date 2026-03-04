/// Domain model for a booking/contact request.
library;

/// Represents a booking in the `bookings` table.
class BookingModel {
  const BookingModel({
    required this.id,
    required this.clientId,
    required this.photographerId,
    required this.serviceType,
    required this.date,
    required this.location,
    this.message,
    required this.status,
    required this.contactCost,
    required this.createdAt,
  });

  final String id;
  final String clientId;
  final String photographerId;
  final String serviceType;
  final DateTime date;
  final String location;
  final String? message;
  final String status;
  final double contactCost;
  final DateTime createdAt;

  /// Parses a [BookingModel] from a JSON map.
  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: json['id'] as String,
        clientId: json['client_id'] as String,
        photographerId: json['photographer_id'] as String,
        serviceType: json['service_type'] as String,
        date: DateTime.parse(json['date'] as String),
        location: json['location'] as String,
        message: json['message'] as String?,
        status: json['status'] as String,
        contactCost: (json['contact_cost'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'photographer_id': photographerId,
        'service_type': serviceType,
        'date': date.toIso8601String(),
        'location': location,
        'message': message,
        'status': status,
        'contact_cost': contactCost,
        'created_at': createdAt.toIso8601String(),
      };

  /// Returns a human-readable French label for the status.
  String get statusLabel {
    switch (status) {
      case 'en_attente':
        return 'En attente';
      case 'accepte':
        return 'Accepté';
      case 'refuse':
        return 'Refusé';
      case 'termine':
        return 'Terminé';
      case 'annule':
        return 'Annulé';
      default:
        return status;
    }
  }
}
