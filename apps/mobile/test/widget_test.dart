/// Tests unitaires — Photographes.ci Mobile
///
/// Couverts :
///  - BookingModel (sérialisation JSON, labels de statut)
///  - PaymentModel (sérialisation JSON)
///  - ServiceModel (sérialisation JSON)
///  - FilterModel (sérialisation JSON)
///  - PhotographerModel (sérialisation JSON)
///  - AppConstants (valeurs de configuration)
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:photographes_mobile/core/constants/app_constants.dart';
import 'package:photographes_mobile/features/booking/domain/booking_model.dart';
import 'package:photographes_mobile/features/payment/domain/payment_model.dart';
import 'package:photographes_mobile/features/photographer_services/domain/service_model.dart';
import 'package:photographes_mobile/features/feed/domain/filter_model.dart';
import 'package:photographes_mobile/features/feed/domain/photographer_model.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // AppConstants
  // ─────────────────────────────────────────────────────────────────────────
  group('AppConstants', () {
    test('appName is correct', () {
      expect(AppConstants.appName, 'Photographes.ci');
    });

    test('defaultContactCost is positive', () {
      expect(AppConstants.defaultContactCost, greaterThan(0));
    });

    test('communes list is not empty', () {
      expect(AppConstants.communes, isNotEmpty);
    });

    test('specialties list is not empty', () {
      expect(AppConstants.specialties, isNotEmpty);
    });

    test('mobileOperators contains Orange Money', () {
      expect(AppConstants.mobileOperators, contains('Orange Money'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // BookingModel
  // ─────────────────────────────────────────────────────────────────────────
  group('BookingModel', () {
    final Map<String, dynamic> json = {
      'id': 'booking-1',
      'client_id': 'client-1',
      'photographer_id': 'photo-1',
      'service_type': 'Mariage',
      'date': '2026-06-15T10:00:00.000Z',
      'location': 'Abidjan - Cocody',
      'message': 'Mariage de 200 personnes',
      'status': 'en_attente',
      'contact_cost': 500.0,
      'created_at': '2026-03-01T08:00:00.000Z',
    };

    test('fromJson parses all fields', () {
      final model = BookingModel.fromJson(json);

      expect(model.id, 'booking-1');
      expect(model.clientId, 'client-1');
      expect(model.photographerId, 'photo-1');
      expect(model.serviceType, 'Mariage');
      expect(model.location, 'Abidjan - Cocody');
      expect(model.message, 'Mariage de 200 personnes');
      expect(model.status, 'en_attente');
      expect(model.contactCost, 500.0);
    });

    test('toJson round-trips correctly', () {
      final model = BookingModel.fromJson(json);
      final output = model.toJson();

      expect(output['id'], json['id']);
      expect(output['client_id'], json['client_id']);
      expect(output['status'], json['status']);
      expect(output['contact_cost'], json['contact_cost']);
    });

    test('statusLabel returns French label for en_attente', () {
      final model = BookingModel.fromJson(json);
      expect(model.statusLabel, 'En attente');
    });

    test('statusLabel returns French label for accepte', () {
      final model = BookingModel.fromJson({...json, 'status': 'accepte'});
      expect(model.statusLabel, 'Accepté');
    });

    test('statusLabel returns French label for refuse', () {
      final model = BookingModel.fromJson({...json, 'status': 'refuse'});
      expect(model.statusLabel, 'Refusé');
    });

    test('statusLabel returns French label for termine', () {
      final model = BookingModel.fromJson({...json, 'status': 'termine'});
      expect(model.statusLabel, 'Terminé');
    });

    test('statusLabel returns French label for annule', () {
      final model = BookingModel.fromJson({...json, 'status': 'annule'});
      expect(model.statusLabel, 'Annulé');
    });

    test('date is parsed as DateTime', () {
      final model = BookingModel.fromJson(json);
      expect(model.date, isA<DateTime>());
      expect(model.date.year, 2026);
      expect(model.date.month, 6);
    });

    test('optional message can be null', () {
      final noMessage = Map<String, dynamic>.from(json)..remove('message');
      final model = BookingModel.fromJson(noMessage);
      expect(model.message, isNull);
    });

    test('contact_cost defaults to 0 when absent', () {
      final noContact = Map<String, dynamic>.from(json)..remove('contact_cost');
      final model = BookingModel.fromJson(noContact);
      expect(model.contactCost, 0.0);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PaymentModel
  // ─────────────────────────────────────────────────────────────────────────
  group('PaymentModel', () {
    final Map<String, dynamic> json = {
      'id': 'pay-1',
      'booking_id': 'booking-1',
      'amount': 75000.0,
      'operator': 'orange_money',
      'phone_number': '+22507123456',
      'status': 'pending',
      'transaction_id': null,
      'created_at': '2026-03-01T09:00:00.000Z',
    };

    test('fromJson parses all fields', () {
      final model = PaymentModel.fromJson(json);

      expect(model.id, 'pay-1');
      expect(model.bookingId, 'booking-1');
      expect(model.amount, 75000.0);
      expect(model.operator, 'orange_money');
      expect(model.phoneNumber, '+22507123456');
      expect(model.status, 'pending');
      expect(model.transactionId, isNull);
    });

    test('toJson round-trips correctly', () {
      final model = PaymentModel.fromJson(json);
      final output = model.toJson();

      expect(output['id'], json['id']);
      expect(output['amount'], json['amount']);
      expect(output['operator'], json['operator']);
    });

    test('amount is parsed as double', () {
      final model = PaymentModel.fromJson({...json, 'amount': 75000});
      expect(model.amount, isA<double>());
      expect(model.amount, 75000.0);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ServiceModel
  // ─────────────────────────────────────────────────────────────────────────
  group('ServiceModel', () {
    final Map<String, dynamic> json = {
      'id': 'svc-1',
      'photographer_id': 'photo-1',
      'name': 'Pack Mariage Premium',
      'description': 'Couverture complète de votre mariage (8h)',
      'price': 250000.0,
      'duration_hours': 8.0,
      'is_active': true,
    };

    test('fromJson parses all fields', () {
      final model = ServiceModel.fromJson(json);

      expect(model.id, 'svc-1');
      expect(model.photographerId, 'photo-1');
      expect(model.name, 'Pack Mariage Premium');
      expect(model.price, 250000.0);
      expect(model.durationHours, 8.0);
      expect(model.isActive, isTrue);
    });

    test('toJson round-trips correctly', () {
      final model = ServiceModel.fromJson(json);
      final output = model.toJson();

      expect(output['name'], json['name']);
      expect(output['price'], json['price']);
    });

    test('isActive defaults to true when absent', () {
      final noActive = Map<String, dynamic>.from(json)..remove('is_active');
      final model = ServiceModel.fromJson(noActive);
      expect(model.isActive, isTrue);
    });

    test('description and durationHours are optional', () {
      final minimal = <String, dynamic>{
        'id': 'svc-2',
        'photographer_id': 'photo-1',
        'name': 'Portrait',
        'price': 50000.0,
      };
      final model = ServiceModel.fromJson(minimal);
      expect(model.description, isNull);
      expect(model.durationHours, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FilterModel
  // ─────────────────────────────────────────────────────────────────────────
  group('FilterModel', () {
    test('default filter has no constraints', () {
      const filter = FilterModel();
      expect(filter.city, isNull);
      expect(filter.specialty, isNull);
      expect(filter.minPrice, isNull);
      expect(filter.maxPrice, isNull);
      expect(filter.onlyAvailable, isFalse);
      expect(filter.minRating, isNull);
    });

    test('fromJson parses all fields', () {
      final json = <String, dynamic>{
        'city': 'Abidjan - Cocody',
        'specialty': 'Mariage',
        'min_price': 10000.0,
        'max_price': 100000.0,
        'only_available': true,
        'min_rating': 4.0,
      };
      final filter = FilterModel.fromJson(json);

      expect(filter.city, 'Abidjan - Cocody');
      expect(filter.specialty, 'Mariage');
      expect(filter.minPrice, 10000.0);
      expect(filter.maxPrice, 100000.0);
      expect(filter.onlyAvailable, isTrue);
      expect(filter.minRating, 4.0);
    });

    test('toJson round-trips correctly', () {
      const filter = FilterModel(
        city: 'Bouaké',
        specialty: 'Portrait',
        onlyAvailable: true,
      );
      final json = filter.toJson();

      expect(json['city'], 'Bouaké');
      expect(json['specialty'], 'Portrait');
      expect(json['only_available'], isTrue);
    });

    test('copyWith updates only specified fields', () {
      const original = FilterModel(city: 'Abidjan - Plateau', minPrice: 5000);
      final updated = original.copyWith(city: 'Yamoussoukro');

      expect(updated.city, 'Yamoussoukro');
      expect(updated.minPrice, 5000); // unchanged
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PhotographerModel
  // ─────────────────────────────────────────────────────────────────────────
  group('PhotographerModel', () {
    final Map<String, dynamic> json = {
      'id': 'photo-1',
      'profile_id': 'profile-1',
      'full_name': 'Kouamé Ulrich',
      'avatar_url': 'https://example.com/avatar.jpg',
      'bio': 'Photographe professionnel basé à Abidjan.',
      'city': 'Abidjan - Cocody',
      'specialties': ['Mariage', 'Portrait'],
      'price_per_hour': 25000.0,
      'is_available': true,
      'average_rating': 4.8,
      'review_count': 23,
      'portfolio_count': 42,
      'created_at': '2025-01-10T08:00:00.000Z',
    };

    test('fromJson parses all fields', () {
      final model = PhotographerModel.fromJson(json);

      expect(model.id, 'photo-1');
      expect(model.fullName, 'Kouamé Ulrich');
      expect(model.city, 'Abidjan - Cocody');
      expect(model.specialties, contains('Mariage'));
      expect(model.pricePerHour, 25000.0);
      expect(model.isAvailable, isTrue);
      expect(model.averageRating, 4.8);
      expect(model.reviewCount, 23);
      expect(model.portfolioCount, 42);
    });

    test('toJson round-trips correctly', () {
      final model = PhotographerModel.fromJson(json);
      final output = model.toJson();

      expect(output['id'], json['id']);
      expect(output['full_name'], json['full_name']);
      expect(output['city'], json['city']);
    });

    test('optional fields are nullable', () {
      final minimal = <String, dynamic>{
        'id': 'photo-2',
        'profile_id': 'profile-2',
        'is_available': false,
        'average_rating': 0.0,
        'review_count': 0,
        'portfolio_count': 0,
        'created_at': '2026-01-01T00:00:00.000Z',
      };
      final model = PhotographerModel.fromJson(minimal);

      expect(model.fullName, isNull);
      expect(model.city, isNull);
      expect(model.bio, isNull);
      expect(model.pricePerHour, isNull);
      expect(model.specialties, isEmpty);
    });

    test('averageRating clamps to [0, 5]', () {
      final over5 = {...json, 'average_rating': 5.0};
      final model = PhotographerModel.fromJson(over5);
      expect(model.averageRating, lessThanOrEqualTo(5.0));
    });
  });
}
