/// Subscriptions screen showing plan cards with quota progress bars.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/subscription_model.dart';

// ---------------------------------------------------------------------------
// Static plan definitions (could also come from backend)
// ---------------------------------------------------------------------------

const _plans = [
  _PlanDef(
    name: AppConstants.planFree,
    price: 0,
    portfolioQuota: 10,
    monthlyMissions: 5,
    features: ['10 photos portfolio', '5 missions/mois', 'Badge basique'],
  ),
  _PlanDef(
    name: AppConstants.planPro,
    price: 9900,
    portfolioQuota: 30,
    monthlyMissions: 20,
    features: [
      '30 photos portfolio',
      '20 missions/mois',
      'Badge Pro',
      'Mise en avant dans les résultats',
    ],
  ),
  _PlanDef(
    name: AppConstants.planPremium,
    price: 24900,
    portfolioQuota: 50,
    monthlyMissions: 999,
    features: [
      '50 photos portfolio',
      'Missions illimitées',
      'Badge Premium ✓',
      'Top des résultats',
      'Support prioritaire',
    ],
  ),
];

class _PlanDef {
  const _PlanDef({
    required this.name,
    required this.price,
    required this.portfolioQuota,
    required this.monthlyMissions,
    required this.features,
  });

  final String name;
  final double price;
  final int portfolioQuota;
  final int monthlyMissions;
  final List<String> features;
}

final _activeSubscriptionProvider =
    FutureProvider.autoDispose<SubscriptionModel?>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;
  final data = await Supabase.instance.client
      .from('subscriptions')
      .select()
      .eq('photographer_id', userId)
      .eq('is_active', true)
      .maybeSingle();
  if (data == null) return null;
  return SubscriptionModel.fromJson(data);
});

/// Displays subscription plan cards with the current plan highlighted.
class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(_activeSubscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Abonnements')),
      body: subAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (activeSub) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (activeSub != null) ...[
              _ActivePlanBanner(subscription: activeSub),
              const SizedBox(height: 24),
            ],
            Text(
              'Choisissez votre plan',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._plans.map((plan) => _PlanCard(
                  plan: plan,
                  isCurrentPlan: activeSub?.planName == plan.name,
                  onSubscribe: () =>
                      _subscribe(context, ref, plan),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _subscribe(
      BuildContext context, WidgetRef ref, _PlanDef plan) async {
    // In a real app this would initiate a payment flow
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abonnement ${plan.name} en cours…'),
        backgroundColor: AppColors.gold,
      ),
    );
  }
}

class _ActivePlanBanner extends StatelessWidget {
  const _ActivePlanBanner({required this.subscription});

  final SubscriptionModel subscription;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(
                'Plan actuel : ${subscription.planName}',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (subscription.expiresAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Expire le ${DateFormat('dd/MM/yyyy').format(subscription.expiresAt!)}',
              style: const TextStyle(color: AppColors.grey),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.photo_library_outlined,
                  size: 14, color: AppColors.grey),
              const SizedBox(width: 4),
              Text('Portfolio: ${subscription.portfolioQuota} photos',
                  style: const TextStyle(color: AppColors.grey, fontSize: 12)),
              const SizedBox(width: 12),
              const Icon(Icons.work_outline, size: 14, color: AppColors.grey),
              const SizedBox(width: 4),
              Text(
                'Missions: ${subscription.monthlyMissions == 999 ? "∞" : subscription.monthlyMissions}/mois',
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isCurrentPlan,
    required this.onSubscribe,
  });

  final _PlanDef plan;
  final bool isCurrentPlan;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final isPremium = plan.name == AppConstants.planPremium;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan
              ? AppColors.gold
              : isPremium
                  ? AppColors.goldLight
                  : AppColors.greyLight,
          width: isCurrentPlan ? 2 : 1,
        ),
        color: isPremium
            ? AppColors.gold.withOpacity(0.06)
            : Theme.of(context).colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  plan.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isPremium ? AppColors.gold : null,
                  ),
                ),
                if (isCurrentPlan) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Actif',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.black,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  plan.price == 0
                      ? 'Gratuit'
                      : '${plan.price.toStringAsFixed(0)} FCFA/mois',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isPremium ? AppColors.gold : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...plan.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: isPremium ? AppColors.gold : AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Text(f, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!isCurrentPlan)
              ElevatedButton(
                onPressed: onSubscribe,
                style: isPremium
                    ? null
                    : ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.surface,
                        foregroundColor: AppColors.gold,
                        side: const BorderSide(color: AppColors.gold),
                      ),
                child: Text(plan.price == 0
                    ? 'Utiliser le plan gratuit'
                    : 'Souscrire'),
              ),
          ],
        ),
      ),
    );
  }
}
