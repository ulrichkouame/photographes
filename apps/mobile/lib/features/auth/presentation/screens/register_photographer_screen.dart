/// Photographer onboarding: name, bio, city, specialties multi-select.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';

/// Collects detailed profile information for a new photographer.
class RegisterPhotographerScreen extends StatefulWidget {
  const RegisterPhotographerScreen({super.key});

  @override
  State<RegisterPhotographerScreen> createState() =>
      _RegisterPhotographerScreenState();
}

class _RegisterPhotographerScreenState
    extends State<RegisterPhotographerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedCity;
  final Set<String> _selectedSpecialties = {};
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner votre ville')),
      );
      return;
    }
    if (_selectedSpecialties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sélectionnez au moins une spécialité')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client.from('photographes_profiles').upsert({
          'id': userId,
          'full_name': _nameController.text.trim(),
          'bio': _bioController.text.trim(),
          'city': _selectedCity,
          'specialties': _selectedSpecialties.toList(),
          'price_per_hour': double.tryParse(_priceController.text) ?? 0,
          'role': 'PHOTOGRAPHE',
          'is_available': true,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      if (!mounted) return;
      context.go(AppRoutes.photographerDashboard);
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
    _nameController.dispose();
    _bioController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil photographe')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Créez votre profil',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Les clients verront ces informations sur votre profil.',
                  style: const TextStyle(color: AppColors.grey),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Biographie',
                    hintText:
                        'Décrivez votre style, votre expérience, vos équipements…',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tarif horaire (FCFA)',
                    prefixIcon: Icon(Icons.attach_money_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  items: AppConstants.communes
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Ville / Commune',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  onChanged: (v) => setState(() => _selectedCity = v),
                  validator: (v) => v == null ? 'Champ requis' : null,
                ),
                const SizedBox(height: 24),
                Text(
                  'Spécialités',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.specialties.map((specialty) {
                    final isSelected = _selectedSpecialties.contains(specialty);
                    return FilterChip(
                      label: Text(specialty),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSpecialties.add(specialty);
                          } else {
                            _selectedSpecialties.remove(specialty);
                          }
                        });
                      },
                      selectedColor: AppColors.gold,
                      checkmarkColor: AppColors.black,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.black,
                          ),
                        )
                      : const Text('Créer mon profil'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
