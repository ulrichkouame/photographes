/// Payment screen: operator selection, phone input, pay button.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../data/payment_repository.dart';

final _paymentRepoProvider = Provider<PaymentRepository>((ref) =>
    PaymentRepository(Supabase.instance.client, Dio()));

/// Allows clients to pay via Orange Money, Wave, or MTN MoMo.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _phoneController = TextEditingController();
  String? _selectedOperator;
  bool _isLoading = false;
  bool _success = false;

  static const Map<String, String> _operatorIcons = {
    'Orange Money': '🟠',
    'Wave': '🔵',
    'MTN MoMo': '🟡',
  };

  Future<void> _pay() async {
    if (_selectedOperator == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un opérateur')),
      );
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez votre numéro')),
      );
      return;
    }
    final settings = ref.read(appSettingsProvider).value ?? AppSettings.defaults();
    if (settings.paymentApiUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service de paiement non disponible')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(_paymentRepoProvider).initiatePayment(
            bookingId: widget.bookingId,
            amount: settings.contactCost,
            operator: _selectedOperator!,
            phoneNumber: _phoneController.text.trim(),
            paymentApiUrl: settings.paymentApiUrl,
          );
      if (!mounted) return;
      setState(() => _success = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) context.go('/booking-confirmation/${widget.bookingId}');
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final contactCost =
        settingsAsync.value?.contactCost ?? AppConstants.defaultContactCost;

    if (_success) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.success,
                size: 80,
              ),
              const SizedBox(height: 16),
              Text(
                'Paiement réussi !',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Redirection en cours…',
                  style: TextStyle(color: AppColors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    const Text('Montant à payer',
                        style: TextStyle(color: AppColors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      '${contactCost.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Opérateur',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              // Operator cards
              ...AppConstants.mobileOperators.map((op) {
                final isSelected = _selectedOperator == op;
                return GestureDetector(
                  onTap: () => setState(() => _selectedOperator = op),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.gold
                            : AppColors.greyLight,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? AppColors.gold.withOpacity(0.08)
                          : Theme.of(context).colorScheme.surface,
                    ),
                    child: Row(
                      children: [
                        Text(
                          _operatorIcons[op] ?? '💳',
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          op,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppColors.gold),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              Text('Numéro de paiement',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'Ex: 0707070707',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _pay,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.black,
                        ),
                      )
                    : Text(
                        'Payer ${contactCost.toStringAsFixed(0)} FCFA'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
