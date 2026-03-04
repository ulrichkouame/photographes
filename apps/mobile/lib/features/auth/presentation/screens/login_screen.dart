/// Login screen: phone number input with CI (+225) country code prefix.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';

/// Phone number entry screen that triggers OTP via WasenderAPI.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final rawPhone = _phoneController.text.trim().replaceAll(' ', '');
    final fullPhone =
        '${AppConstants.defaultCountryCode}$rawPhone';

    await ref.read(authProvider.notifier).sendOtp(fullPhone);

    if (!mounted) return;
    final state = ref.read(authProvider);
    if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      context.push(
        '${AppRoutes.otp}?phone=${Uri.encodeComponent(fullPhone)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 40,
                      color: AppColors.gold,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Bienvenue sur',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.grey,
                      ),
                ),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Entrez votre numéro WhatsApp pour recevoir un code de vérification.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.grey),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: 'Numéro WhatsApp',
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '🇨🇮',
                            style: TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppConstants.defaultCountryCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 1,
                            height: 20,
                            color: AppColors.grey,
                          ),
                        ],
                      ),
                    ),
                    counterText: '',
                    hintText: '07 XX XX XX XX',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir votre numéro';
                    }
                    if (value.trim().length < 8) {
                      return 'Numéro invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: isLoading ? null : _sendOtp,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.black,
                          ),
                        )
                      : const Text('Envoyer le code'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Vous recevrez un code via WhatsApp',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
