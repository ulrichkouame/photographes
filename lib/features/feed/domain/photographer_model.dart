/// Domain model representing a photographer profile.
library;

/// Represents a photographer as returned from the Supabase `profiles` table.
class PhotographerModel {
  const PhotographerModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bio,
    this.rating = 0.0,
    this.pricePerHour = 0.0,
    this.specialties = const [],
    this.city,
    this.isAvailable = false,
    this.badgeVerified = false,
    this.portfolioUrls = const [],
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final double rating;
  final double pricePerHour;
  final List<String> specialties;
  final String? city;
  final bool isAvailable;
  final bool badgeVerified;
  final List<String> portfolioUrls;

  /// Constructs a [PhotographerModel] from a JSON map.
  factory PhotographerModel.fromJson(Map<String, dynamic> json) {
    return PhotographerModel(
      id: json['id'] as String,
      name: json['full_name'] as String? ?? 'Photographe',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      rating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      pricePerHour: (json['price_per_hour'] as num?)?.toDouble() ?? 0.0,
      specialties: List<String>.from(json['specialties'] as List? ?? []),
      city: json['city'] as String?,
      isAvailable: json['is_available'] as bool? ?? false,
      badgeVerified: json['badge_verified'] as bool? ?? false,
      portfolioUrls: List<String>.from(json['portfolio_urls'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': name,
        'avatar_url': avatarUrl,
        'bio': bio,
        'average_rating': rating,
        'price_per_hour': pricePerHour,
        'specialties': specialties,
        'city': city,
        'is_available': isAvailable,
        'badge_verified': badgeVerified,
        'portfolio_urls': portfolioUrls,
      };
}
