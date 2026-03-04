/// Card widget showing photographer summary information.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/photographer_model.dart';

/// Displays a photographer's avatar, name, rating, price, specialties, and availability.
class PhotographerCard extends StatelessWidget {
  const PhotographerCard({
    super.key,
    required this.photographer,
    required this.onTap,
  });

  final PhotographerModel photographer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: photographer.avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: photographer.avatarUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _avatarPlaceholder(),
                            errorWidget: (_, __, ___) => _avatarPlaceholder(),
                          )
                        : _avatarPlaceholder(),
                  ),
                  if (photographer.isAvailable)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            photographer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (photographer.badgeVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.verified_rounded,
                              color: AppColors.gold,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (photographer.city != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: AppColors.grey,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            photographer.city!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    // Star rating
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          final filled =
                              i < photographer.rating.floor();
                          final half =
                              !filled && i < photographer.rating;
                          return Icon(
                            half
                                ? Icons.star_half_rounded
                                : filled
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                            size: 14,
                            color: AppColors.gold,
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          photographer.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Specialties
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: photographer.specialties
                          .take(3)
                          .map(
                            (s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                s,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${photographer.pricePerHour.toStringAsFixed(0)} FCFA / h',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
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
    );
  }

  Widget _avatarPlaceholder() => Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.greyLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.person_outline,
          size: 40,
          color: AppColors.grey,
        ),
      );
}
