/// Role selection screen: CLIENT or PHOTOGRAPHE.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';

/// Lets the user choose their role in the marketplace.
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  String? _selectedRole;
  bool _isLoading = false;

  Future<void> _confirmRole() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir un rôle')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': userId,
          'role': _selectedRole,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      if (!mounted) return;
      if (_selectedRole == 'CLIENT') {
        context.go(AppRoutes.registerClient);
      } else {
        context.go(AppRoutes.registerPhotographer);
      }
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Vous êtes…',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sélectionnez votre profil pour personnaliser votre expérience.',
                style:
                    Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.grey),
              ),
              const SizedBox(height: 40),
              _RoleCard(
                title: 'Client',
                subtitle: 'Je cherche un photographe pour mon événement',
                icon: Icons.person_search_outlined,
                isSelected: _selectedRole == 'CLIENT',
                onTap: () => setState(() => _selectedRole = 'CLIENT'),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                title: 'Photographe',
                subtitle: 'Je propose mes services de photographie',
                icon: Icons.camera_alt_outlined,
                isSelected: _selectedRole == 'PHOTOGRAPHE',
                onTap: () => setState(() => _selectedRole = 'PHOTOGRAPHE'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _confirmRole,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.black,
                        ),
                      )
                    : const Text('Continuer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.greyLight,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? AppColors.gold.withOpacity(0.08)
              : Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.gold
                    : AppColors.greyLight,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.black : AppColors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}
