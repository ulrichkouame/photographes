/// Full photographer profile screen: header, portfolio, about, reviews, book button.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../data/profile_repository.dart';
import '../../domain/portfolio_photo_model.dart';
import '../../domain/review_model.dart';
import '../../../feed/domain/photographer_model.dart';
import '../widgets/portfolio_grid.dart';

final _profileRepoProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(Supabase.instance.client),
);

final _photographerProfileProvider =
    FutureProvider.family<PhotographerModel?, String>((ref, id) async {
  return ref.read(_profileRepoProvider).getProfile(id);
});

final _portfolioProvider =
    FutureProvider.family<List<PortfolioPhoto>, String>((ref, id) async {
  return ref.read(_profileRepoProvider).getPortfolioPhotos(id);
});

final _reviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, id) async {
  return ref.read(_profileRepoProvider).getReviews(id);
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Displays the full public profile of a photographer.
class PhotographerProfileScreen extends ConsumerWidget {
  const PhotographerProfileScreen({super.key, required this.photographerId});

  final String photographerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync =
        ref.watch(_photographerProfileProvider(photographerId));

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(e.toString())),
      ),
      data: (photographer) {
        if (photographer == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Photographe introuvable')),
          );
        }
        return _ProfileBody(photographer: photographer);
      },
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.photographer});

  final PhotographerModel photographer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(_portfolioProvider(photographer.id));
    final reviewsAsync = ref.watch(_reviewsProvider(photographer.id));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // --- SliverAppBar with cover photo ---
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  photographer.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: photographer.avatarUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(color: AppColors.darkSurface),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    right: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              photographer.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            if (photographer.badgeVerified)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(
                                  Icons.verified_rounded,
                                  color: AppColors.gold,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                        if (photographer.city != null)
                          Text(
                            photographer.city!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.star_rounded,
                        label:
                            '${photographer.rating.toStringAsFixed(1)} / 5',
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.attach_money,
                        label:
                            '${photographer.pricePerHour.toStringAsFixed(0)} FCFA/h',
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.circle,
                        label: photographer.isAvailable
                            ? 'Disponible'
                            : 'Occupé',
                        color: photographer.isAvailable
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Specialties
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: photographer.specialties
                        .map(
                          (s) => Chip(
                            label: Text(s),
                            backgroundColor: AppColors.gold.withOpacity(0.12),
                            labelStyle: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),

                  // About
                  if (photographer.bio != null && photographer.bio!.isNotEmpty) ...[
                    Text(
                      'À propos',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      photographer.bio!,
                      style: const TextStyle(
                        color: AppColors.grey,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Portfolio
                  Text(
                    'Portfolio',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  portfolioAsync.when(
                    loading: () => const SizedBox(
                      height: 200,
                      child: Center(
                        child:
                            CircularProgressIndicator(color: AppColors.gold),
                      ),
                    ),
                    error: (e, _) => Text(e.toString()),
                    data: (photos) => photos.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Aucune photo dans le portfolio',
                              style: TextStyle(color: AppColors.grey),
                            ),
                          )
                        : PortfolioGrid(photos: photos),
                  ),
                  const SizedBox(height: 20),

                  // Reviews
                  Text(
                    'Avis clients',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  reviewsAsync.when(
                    loading: () => const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.gold),
                    ),
                    error: (e, _) => Text(e.toString()),
                    data: (reviews) => reviews.isEmpty
                        ? const Text(
                            'Aucun avis pour le moment',
                            style: TextStyle(color: AppColors.grey),
                          )
                        : Column(
                            children: reviews
                                .map((r) => _ReviewCard(review: r))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: photographer.isAvailable
                ? () => context.push('/booking/${photographer.id}')
                : null,
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Contacter ce photographe'),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.gold.withOpacity(0.2),
                  child: Text(
                    review.clientName.isNotEmpty
                        ? review.clientName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: AppColors.gold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.clientName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(review.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 14,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment!,
                  style: const TextStyle(color: AppColors.grey)),
            ],
          ],
        ),
      ),
    );
  }
}
