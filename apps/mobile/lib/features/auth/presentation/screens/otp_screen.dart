/// 6-digit OTP verification screen with countdown resend.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';

/// Screen for entering the 6-digit WhatsApp OTP.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  String _otp = '';
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez le code à 6 chiffres')),
      );
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .verifyOtp(widget.phoneNumber, _otp);

    if (!mounted) return;

    if (success) {
      // Check if user has a profile/role already set
      context.go('${AppRoutes.pin}?mode=setup');
    } else {
      final state = ref.read(authProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state is AuthError ? state.message : 'Code incorrect',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    await ref.read(authProvider.notifier).sendOtp(widget.phoneNumber);
    _startCountdown();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code renvoyé via WhatsApp')),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    final maskedPhone = widget.phoneNumber.replaceRange(
      4,
      widget.phoneNumber.length - 2,
      '****',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Vérification')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Code de vérification',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Entrez le code à 6 chiffres envoyé via WhatsApp au $maskedPhone',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.grey),
              ),
              const SizedBox(height: 40),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                onChanged: (v) => _otp = v,
                onCompleted: (v) {
                  _otp = v;
                  _verifyOtp();
                },
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 46,
                  activeFillColor: AppColors.gold.withOpacity(0.1),
                  inactiveFillColor:
                      Theme.of(context).colorScheme.surface,
                  selectedFillColor: AppColors.gold.withOpacity(0.15),
                  activeColor: AppColors.gold,
                  inactiveColor: AppColors.grey,
                  selectedColor: AppColors.gold,
                ),
                enableActiveFill: true,
                cursorColor: AppColors.gold,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _verifyOtp,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.black,
                        ),
                      )
                    : const Text('Vérifier'),
              ),
              const SizedBox(height: 20),
              Center(
                child: _secondsLeft > 0
                    ? Text(
                        'Renvoyer le code dans ${_secondsLeft}s',
                        style: const TextStyle(color: AppColors.grey),
                      )
                    : TextButton(
                        onPressed: _resendOtp,
                        child: const Text('Renvoyer le code'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
