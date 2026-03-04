/// 4-digit PIN setup and verification screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

/// Screen for setting up or verifying the user's 4-digit security PIN.
///
/// [mode] is either `'setup'` (first time) or `'verify'` (subsequent login).
class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key, required this.mode});

  final String mode;

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String _pin = '';
  String _confirm = '';
  bool _isSetupStep2 = false;
  bool _isLoading = false;

  bool get _isSetup => widget.mode == 'setup';

  Future<void> _handlePin() async {
    if (_isSetup && !_isSetupStep2) {
      if (_pin.length < 4) return;
      setState(() => _isSetupStep2 = true);
      _pinController.clear();
      return;
    }

    if (_isSetup) {
      if (_pin != _confirm) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les codes PIN ne correspondent pas'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() {
          _isSetupStep2 = false;
          _pin = '';
          _confirm = '';
        });
        _pinController.clear();
        _confirmController.clear();
        return;
      }
      setState(() => _isLoading = true);
      await ref.read(authProvider.notifier).setPin(_pin);
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.go(AppRoutes.registerRole);
    } else {
      setState(() => _isLoading = true);
      final ok = await ref.read(authProvider.notifier).verifyPin(_pin);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (ok) {
        context.go(AppRoutes.home);
      } else {
        _pinController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN incorrect. Réessayez.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isSetup
        ? (_isSetupStep2 ? 'Confirmez votre PIN' : 'Créez votre PIN')
        : 'Entrez votre PIN';
    final subtitle = _isSetup
        ? (_isSetupStep2
            ? 'Saisissez à nouveau le code pour confirmer'
            : 'Choisissez un code à 4 chiffres pour sécuriser votre compte')
        : 'Saisissez votre code PIN à 4 chiffres';

    return Scaffold(
      appBar: AppBar(title: const Text('Sécurité')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.gold,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.grey),
              ),
              const SizedBox(height: 40),
              PinCodeTextField(
                appContext: context,
                length: 4,
                controller: _isSetupStep2 ? _confirmController : _pinController,
                onChanged: (v) {
                  if (_isSetupStep2) {
                    _confirm = v;
                  } else {
                    _pin = v;
                  }
                },
                onCompleted: (_) => _handlePin(),
                keyboardType: TextInputType.number,
                obscureText: true,
                obscuringCharacter: '●',
                animationType: AnimationType.scale,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.circle,
                  fieldHeight: 64,
                  fieldWidth: 64,
                  activeFillColor: AppColors.gold.withOpacity(0.15),
                  inactiveFillColor:
                      Theme.of(context).colorScheme.surface,
                  selectedFillColor: AppColors.gold.withOpacity(0.2),
                  activeColor: AppColors.gold,
                  inactiveColor: AppColors.grey,
                  selectedColor: AppColors.gold,
                ),
                enableActiveFill: true,
                cursorColor: AppColors.gold,
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const CircularProgressIndicator(color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}
