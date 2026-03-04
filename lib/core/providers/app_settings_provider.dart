/// Riverpod provider that fetches and caches app settings from the
/// Supabase edge function [photographes_sync-settings].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

/// Model representing remote app settings.
class AppSettings {
  /// Constructs [AppSettings] from a raw JSON map.
  const AppSettings({
    required this.contactCost,
    required this.paymentApiUrl,
    required this.wasenderApiUrl,
    required this.wasenderToken,
    required this.maintenanceMode,
  });

  final double contactCost;
  final String paymentApiUrl;
  final String wasenderApiUrl;
  final String wasenderToken;
  final bool maintenanceMode;

  /// Returns default values used before settings are loaded.
  factory AppSettings.defaults() => const AppSettings(
        contactCost: AppConstants.defaultContactCost,
        paymentApiUrl: '',
        wasenderApiUrl: '',
        wasenderToken: '',
        maintenanceMode: false,
      );

  /// Parses a [AppSettings] from a JSON map.
  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        contactCost: (json['contact_cost'] as num?)?.toDouble() ??
            AppConstants.defaultContactCost,
        paymentApiUrl: json['payment_api_url'] as String? ?? '',
        wasenderApiUrl: json['wasender_api_url'] as String? ?? '',
        wasenderToken: json['wasender_token'] as String? ?? '',
        maintenanceMode: json['maintenance_mode'] as bool? ?? false,
      );
}

/// Fetches [AppSettings] from the Supabase edge function.
/// Falls back to defaults on any error.
final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  try {
    final response = await Supabase.instance.client.functions.invoke(
      AppConstants.syncSettingsFunction,
      method: HttpMethod.get,
    );
    if (response.data != null && response.data is Map<String, dynamic>) {
      return AppSettings.fromJson(response.data as Map<String, dynamic>);
    }
    return AppSettings.defaults();
  } catch (_) {
    return AppSettings.defaults();
  }
});
