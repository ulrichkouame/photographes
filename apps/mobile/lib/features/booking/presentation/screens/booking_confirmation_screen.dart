/// Booking confirmation screen with 48h countdown and status tracking.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking_model.dart';

final _bookingConfirmRepoProvider = Provider<BookingRepository>(
    (ref) => BookingRepository(Supabase.instance.client));

final _bookingDetailProvider =
    FutureProvider.family<BookingModel?, String>((ref, id) async {
  return ref.read(_bookingConfirmRepoProvider).getBooking(id);
});

/// Shows booking confirmation with countdown to photographer's response deadline.
class BookingConfirmationScreen extends ConsumerStatefulWidget {
  const BookingConfirmationScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends ConsumerState<BookingConfirmationScreen> {
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    final deadline = DateTime.now()
        .add(const Duration(hours: AppConstants.bookingResponseHours));
    _updateRemaining(deadline);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemaining(deadline);
    });
  }

  void _updateRemaining(DateTime deadline) {
    final diff = deadline.difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  String _formatCountdown() {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(_bookingDetailProvider(widget.bookingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Demande envoyée')),
      body: bookingAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (booking) {
          if (booking == null) {
            return const Center(child: Text('Réservation introuvable'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  'Demande envoyée !',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Le photographe dispose de 48h pour répondre à votre demande.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.grey),
                ),
                const SizedBox(height: 32),
                // Countdown
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Temps restant',
                        style: TextStyle(color: AppColors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatCountdown(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Booking summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _SummaryRow(label: 'Service', value: booking.serviceType),
                        _SummaryRow(
                          label: 'Date',
                          value: DateFormat('dd/MM/yyyy').format(booking.date),
                        ),
                        _SummaryRow(label: 'Lieu', value: booking.location),
                        _SummaryRow(
                          label: 'Statut',
                          value: booking.statusLabel,
                          valueColor: AppColors.warning,
                        ),
                        _SummaryRow(
                          label: 'Montant payé',
                          value: '${booking.contactCost.toStringAsFixed(0)} FCFA',
                          valueColor: AppColors.gold,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.myRequests),
                  icon: const Icon(Icons.list_alt_outlined),
                  label: const Text('Voir mes demandes'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.home),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Retour à l\'accueil'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
