/// Domain model for a photographer service offering.
library;

/// Represents a custom service package offered by a photographer.
class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.photographerId,
    required this.name,
    this.description,
    required this.price,
    this.durationHours,
    this.isActive = true,
  });

  final String id;
  final String photographerId;
  final String name;
  final String? description;
  final double price;
  final double? durationHours;
  final bool isActive;

  /// Parses a [ServiceModel] from a JSON map.
  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        id: json['id'] as String,
        photographerId: json['photographer_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        price: (json['price'] as num).toDouble(),
        durationHours: (json['duration_hours'] as num?)?.toDouble(),
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'photographer_id': photographerId,
        'name': name,
        'description': description,
        'price': price,
        'duration_hours': durationHours,
        'is_active': isActive,
      };
}
