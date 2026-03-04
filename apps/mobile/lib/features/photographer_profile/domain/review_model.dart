/// Domain model for a client review of a photographer.
library;

/// Represents a review left by a client after a booking.
class Review {
  const Review({
    required this.id,
    required this.clientName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  final String id;
  final String clientName;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  /// Parses a [Review] from a JSON map.
  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        clientName: json['client_name'] as String? ?? 'Anonyme',
        rating: (json['rating'] as num).toDouble(),
        comment: json['comment'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_name': clientName,
        'rating': rating,
        'comment': comment,
        'created_at': createdAt.toIso8601String(),
      };
}
