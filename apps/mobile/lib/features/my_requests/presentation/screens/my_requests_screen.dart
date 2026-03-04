/// Client bookings list with status badges and pagination.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../booking/data/booking_repository.dart';
import '../../../booking/domain/booking_model.dart';

final _clientBookingsRepoProvider = Provider<BookingRepository>(
    (ref) => BookingRepository(Supabase.instance.client));

final _clientBookingsProvider =
    FutureProvider.autoDispose<List<BookingModel>>((ref) async {
  return ref.read(_clientBookingsRepoProvider).getClientBookings();
});

/// Lists all booking requests made by the current client.
class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'accepte':
        return AppColors.success;
      case 'refuse':
        return AppColors.error;
      case 'termine':
        return AppColors.grey;
      case 'annule':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(_clientBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes demandes')),
      body: bookingsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 64, color: AppColors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Aucune demande pour le moment',
                    style: TextStyle(color: AppColors.grey),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.gold,
            onRefresh: () async => ref.refresh(_clientBookingsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                booking.serviceType,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(booking.status)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                booking.statusLabel,
                                style: TextStyle(
                                  color: _statusColor(booking.status),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 14, color: AppColors.grey),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd/MM/yyyy').format(booking.date),
                              style: const TextStyle(color: AppColors.grey),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: AppColors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                booking.location,
                                style: const TextStyle(color: AppColors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${booking.contactCost.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (booking.status == 'accepte') ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => context.push(
                              '/chat/${booking.id}',
                              extra: {
                                'otherUserName': 'Photographe',
                                'otherUserId': booking.photographerId,
                              },
                            ),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Chat'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
