/// App-wide constants: colors, Supabase keys, API endpoints, and branding.
library;

import 'package:flutter/material.dart';

/// Brand color palette
class AppColors {
  AppColors._();

  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE8CC6A);
  static const Color goldDark = Color(0xFFB8941E);
  static const Color black = Color(0xFF0A0A0A);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2A2A2A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightBackground = Color(0xFFF8F8F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
}

/// Application metadata
class AppConstants {
  AppConstants._();

  static const String appName = 'Photographes.ci';
  static const String appVersion = '1.0.0';

  /// Supabase configuration – replace with real values
  static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';

  /// Edge function names
  static const String syncSettingsFunction = 'photographes_sync-settings';

  /// Default country code for Côte d'Ivoire
  static const String defaultCountryCode = '+225';
  static const String defaultCountry = 'CI';

  /// Booking status labels
  static const String statusPending = 'en_attente';
  static const String statusAccepted = 'accepte';
  static const String statusRefused = 'refuse';
  static const String statusCompleted = 'termine';
  static const String statusCancelled = 'annule';

  /// Photographer specialties
  static const List<String> specialties = [
    'Portrait',
    'Mariage',
    'Événement',
    'Corporate',
    'Mode',
    'Famille',
    'Nature',
    'Sport',
  ];

  /// Ivorian communes / cities
  static const List<String> communes = [
    'Abidjan - Cocody',
    'Abidjan - Plateau',
    'Abidjan - Marcory',
    'Abidjan - Yopougon',
    'Abidjan - Treichville',
    'Abidjan - Adjamé',
    'Abidjan - Abobo',
    'Abidjan - Koumassi',
    'Abidjan - Port-Bouët',
    'Abidjan - Bingerville',
    'Bouaké',
    'Yamoussoukro',
    'Daloa',
    'San-Pédro',
    'Man',
    'Korhogo',
  ];

  /// Mobile money operators
  static const List<String> mobileOperators = [
    'Orange Money',
    'Wave',
    'MTN MoMo',
  ];

  /// Subscription plans
  static const String planFree = 'Gratuit';
  static const String planPro = 'Pro';
  static const String planPremium = 'Premium';

  /// Default contact cost when settings not loaded
  static const double defaultContactCost = 500;

  /// Pending booking countdown hours
  static const int bookingResponseHours = 48;

  /// Portfolio limits
  static const int portfolioMinPhotos = 3;
  static const int portfolioMaxPhotosDefault = 50;

  static const Duration splashDuration = Duration(seconds: 2);
}
