/// Domain model for a photographer subscription plan.
library;

/// Represents the photographer's active or available subscription.
class SubscriptionModel {
  const SubscriptionModel({
    required this.id,
    required this.planName,
    required this.price,
    required this.portfolioQuota,
    required this.monthlyMissions,
    this.isActive = false,
    this.expiresAt,
  });

  final String id;
  final String planName;
  final double price;
  final int portfolioQuota;
  final int monthlyMissions;
  final bool isActive;
  final DateTime? expiresAt;

  /// Parses a [SubscriptionModel] from a JSON map.
  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      SubscriptionModel(
        id: json['id'] as String,
        planName: json['plan_name'] as String,
        price: (json['price'] as num).toDouble(),
        portfolioQuota: json['portfolio_quota'] as int? ?? 10,
        monthlyMissions: json['monthly_missions'] as int? ?? 5,
        isActive: json['is_active'] as bool? ?? false,
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'plan_name': planName,
        'price': price,
        'portfolio_quota': portfolioQuota,
        'monthly_missions': monthlyMissions,
        'is_active': isActive,
        'expires_at': expiresAt?.toIso8601String(),
      };
}
