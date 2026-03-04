/// Services CRUD screen for photographers.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/service_model.dart';

final _servicesProvider =
    FutureProvider.autoDispose<List<ServiceModel>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  final data = await Supabase.instance.client
      .from('services')
      .select()
      .eq('photographer_id', userId)
      .order('created_at');
  return (data as List)
      .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Lists, adds, edits, and deletes photographer services.
class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(_servicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes services')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceForm(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: servicesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (services) {
          if (services.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.design_services_outlined,
                      size: 64, color: AppColors.grey),
                  SizedBox(height: 12),
                  Text('Ajoutez vos services',
                      style: TextStyle(color: AppColors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Dismissible(
                key: Key(service.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: AppColors.error,
                  child:
                      const Icon(Icons.delete_outline, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Supprimer ce service ?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Annuler')),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Supprimer',
                                style: TextStyle(color: AppColors.error))),
                      ],
                    ),
                  );
                },
                onDismissed: (_) async {
                  await Supabase.instance.client
                      .from('services')
                      .delete()
                      .eq('id', service.id);
                  ref.invalidate(_servicesProvider);
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(service.name,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: service.description != null
                        ? Text(service.description!)
                        : null,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${service.price.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (service.durationHours != null)
                          Text(
                            '${service.durationHours}h',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.grey),
                          ),
                      ],
                    ),
                    onTap: () =>
                        _showServiceForm(context, ref, service),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showServiceForm(
    BuildContext context,
    WidgetRef ref,
    ServiceModel? existing,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ServiceFormSheet(existing: existing, ref: ref),
    );
    ref.invalidate(_servicesProvider);
  }
}

class _ServiceFormSheet extends StatefulWidget {
  const _ServiceFormSheet({this.existing, required this.ref});

  final ServiceModel? existing;
  final WidgetRef ref;

  @override
  State<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<_ServiceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _descCtrl =
        TextEditingController(text: widget.existing?.description ?? '');
    _priceCtrl = TextEditingController(
        text: widget.existing?.price.toStringAsFixed(0) ?? '');
    _durationCtrl = TextEditingController(
        text: widget.existing?.durationHours?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final payload = {
      'photographer_id': userId,
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'price': double.tryParse(_priceCtrl.text) ?? 0,
      'duration_hours': double.tryParse(_durationCtrl.text),
      'is_active': true,
    };
    try {
      if (widget.existing != null) {
        await Supabase.instance.client
            .from('services')
            .update(payload)
            .eq('id', widget.existing!.id);
      } else {
        await Supabase.instance.client.from('services').insert(payload);
      }
      if (mounted) Navigator.pop(context);
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
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.existing != null ? 'Modifier le service' : 'Nouveau service',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom du service'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Prix (FCFA)'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Champ requis' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Durée (h)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.black),
                    )
                  : const Text('Enregistrer'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
