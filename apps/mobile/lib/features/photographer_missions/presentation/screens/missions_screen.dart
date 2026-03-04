/// Photographer missions screen: accept/refuse with countdown and chat.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../booking/data/booking_repository.dart';
import '../../../booking/domain/booking_model.dart';

final _missionRepoProvider = Provider<BookingRepository>(
    (ref) => BookingRepository(Supabase.instance.client));

final _photographerBookingsProvider =
    FutureProvider.autoDispose<List<BookingModel>>((ref) async {
  return ref.read(_missionRepoProvider).getPhotographerBookings();
});

/// Lists incoming bookings for the photographer with accept/refuse actions.
class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'accepte':
        return AppColors.success;
      case 'refuse':
        return AppColors.error;
      case 'termine':
        return AppColors.grey;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(_photographerBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Missions')),
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
                  Icon(Icons.work_outline_rounded,
                      size: 64, color: AppColors.grey),
                  SizedBox(height: 12),
                  Text('Aucune mission pour le moment',
                      style: TextStyle(color: AppColors.grey)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.gold,
            onRefresh: () async =>
                ref.refresh(_photographerBookingsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final isPending = booking.status == AppConstants.statusPending;

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
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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
                            const SizedBox(width: 12),
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
                        if (booking.message != null &&
                            booking.message!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            booking.message!,
                            style:
                                const TextStyle(color: AppColors.grey, fontSize: 13),
                          ),
                        ],
                        if (isPending) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await ref
                                        .read(_missionRepoProvider)
                                        .updateStatus(
                                            booking.id,
                                            AppConstants.statusAccepted);
                                    ref.invalidate(
                                        _photographerBookingsProvider);
                                  },
                                  icon: const Icon(Icons.check),
                                  label: const Text('Accepter'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await ref
                                        .read(_missionRepoProvider)
                                        .updateStatus(
                                            booking.id,
                                            AppConstants.statusRefused);
                                    ref.invalidate(
                                        _photographerBookingsProvider);
                                  },
                                  icon: const Icon(Icons.close),
                                  label: const Text('Refuser'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(
                                        color: AppColors.error),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (booking.status == AppConstants.statusAccepted) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => context.push(
                              '/chat/${booking.id}',
                              extra: {
                                'otherUserName': 'Client',
                                'otherUserId': booking.clientId,
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
