/// Booking form screen: service, date, location, message, contact cost.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../data/booking_repository.dart';

final _bookingRepoProvider = Provider<BookingRepository>(
    (ref) => BookingRepository(Supabase.instance.client));

/// Contact tunnel allowing clients to submit a booking request.
class BookingFormScreen extends ConsumerStatefulWidget {
  const BookingFormScreen({super.key, required this.photographerId});

  final String photographerId;

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedService;
  DateTime? _selectedDate;
  bool _isLoading = false;

  static const List<String> _services = [
    'Portrait',
    'Mariage',
    'Événement',
    'Corporate',
    'Mode',
    'Famille',
    'Nature',
    'Sport',
    'Autre',
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx)
            .copyWith(colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.gold)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une date')),
      );
      return;
    }
    final settings = ref.read(appSettingsProvider).value ?? AppSettings.defaults();
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(_bookingRepoProvider);
      final booking = await repo.createBooking(
        photographerId: widget.photographerId,
        serviceType: _selectedService!,
        date: _selectedDate!,
        location: _locationController.text.trim(),
        message: _messageController.text.trim(),
        contactCost: settings.contactCost,
      );
      if (!mounted) return;
      context.go('/booking-confirmation/${booking.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final contactCost = settingsAsync.value?.contactCost ?? AppConstants.defaultContactCost;

    return Scaffold(
      appBar: AppBar(title: const Text('Contacter le photographe')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contact cost banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.gold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Frais de mise en contact : ${contactCost.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: _selectedService,
                  items: _services
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Type de service',
                    prefixIcon: Icon(Icons.camera_alt_outlined),
                  ),
                  onChanged: (v) => setState(() => _selectedService = v),
                  validator: (v) => v == null ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        hintText: _selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                            : 'Sélectionner une date',
                      ),
                      controller: TextEditingController(
                        text: _selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                            : '',
                      ),
                      validator: (_) =>
                          _selectedDate == null ? 'Champ requis' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Lieu',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText: 'Décrivez votre événement, vos attentes…',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.black),
                        )
                      : Text(
                          'Payer ${contactCost.toStringAsFixed(0)} FCFA et envoyer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
