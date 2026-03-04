/// Domain model for a single portfolio photo.
library;

/// Represents one photo in a photographer's portfolio.
class PortfolioPhoto {
  const PortfolioPhoto({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    this.isFeatured = false,
    this.title,
    this.sortOrder = 0,
    this.photographerId,
  });

  final String id;
  final String url;
  final String? thumbnailUrl;
  final bool isFeatured;
  final String? title;
  final int sortOrder;
  final String? photographerId;

  /// Parses a [PortfolioPhoto] from a JSON map.
  factory PortfolioPhoto.fromJson(Map<String, dynamic> json) => PortfolioPhoto(
        id: json['id'] as String,
        url: json['url'] as String,
        thumbnailUrl: json['thumbnail_url'] as String?,
        isFeatured: json['is_featured'] as bool? ?? false,
        title: json['title'] as String?,
        sortOrder: json['sort_order'] as int? ?? 0,
        photographerId: json['photographer_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'thumbnail_url': thumbnailUrl,
        'is_featured': isFeatured,
        'title': title,
        'sort_order': sortOrder,
        'photographer_id': photographerId,
      };

  PortfolioPhoto copyWith({bool? isFeatured, int? sortOrder}) => PortfolioPhoto(
        id: id,
        url: url,
        thumbnailUrl: thumbnailUrl,
        isFeatured: isFeatured ?? this.isFeatured,
        title: title,
        sortOrder: sortOrder ?? this.sortOrder,
        photographerId: photographerId,
      );
}
