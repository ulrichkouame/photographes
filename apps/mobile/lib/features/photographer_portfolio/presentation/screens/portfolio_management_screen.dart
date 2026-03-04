/// Portfolio management screen: drag-drop grid, add, star, delete.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/portfolio_repository.dart';
import '../../domain/portfolio_photo_model.dart';

final _portfolioMgmtRepoProvider = Provider<PortfolioManagementRepository>(
    (ref) => PortfolioManagementRepository(Supabase.instance.client));

final _myPhotosProvider =
    FutureProvider.autoDispose<List<PortfolioPhoto>>((ref) async {
  return ref.read(_portfolioMgmtRepoProvider).getMyPhotos();
});

/// Allows the photographer to manage their portfolio photos with drag-drop reordering.
class PortfolioManagementScreen extends ConsumerStatefulWidget {
  const PortfolioManagementScreen({super.key});

  @override
  ConsumerState<PortfolioManagementScreen> createState() =>
      _PortfolioManagementScreenState();
}

class _PortfolioManagementScreenState
    extends ConsumerState<PortfolioManagementScreen> {
  final _imagePicker = ImagePicker();
  bool _isUploading = false;

  Future<void> _addPhoto() async {
    final photos = await ref.read(_myPhotosProvider.future).catchError((_) => <PortfolioPhoto>[]);
    if (photos.length >= AppConstants.portfolioMaxPhotosDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Maximum ${AppConstants.portfolioMaxPhotosDefault} photos atteint'),
        ),
      );
      return;
    }
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _isUploading = true);
    try {
      await ref
          .read(_portfolioMgmtRepoProvider)
          .uploadPhoto(File(picked.path));
      ref.invalidate(_myPhotosProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deletePhoto(PortfolioPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la photo ?'),
        content: const Text('Cette action est irréversible.'),
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
    if (confirmed != true) return;
    try {
      await ref
          .read(_portfolioMgmtRepoProvider)
          .deletePhoto(photo.id, photo.url);
      ref.invalidate(_myPhotosProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _toggleFeatured(PortfolioPhoto photo) async {
    await ref.read(_portfolioMgmtRepoProvider).setFeatured(
          photo.id,
          isFeatured: !photo.isFeatured,
        );
    ref.invalidate(_myPhotosProvider);
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(_myPhotosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon portfolio')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _addPhoto,
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.black),
              )
            : const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Ajouter'),
      ),
      body: photosAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (photos) {
          final quota = AppConstants.portfolioMaxPhotosDefault;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Photos: ${photos.length} / $quota',
                      style: const TextStyle(color: AppColors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: photos.length / quota,
                        backgroundColor: AppColors.greyLight,
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: photos.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_library_outlined,
                                size: 64, color: AppColors.grey),
                            SizedBox(height: 12),
                            Text(
                              'Ajoutez au moins 3 photos\npour activer votre profil',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.grey),
                            ),
                          ],
                        ),
                      )
                    : ReorderableBuilder(
                        onReorder: (orderEntities) {
                          var reordered = List<PortfolioPhoto>.from(photos);
                          for (final entity in orderEntities) {
                            final item = reordered.removeAt(entity.oldIndex);
                            reordered.insert(entity.newIndex, item);
                          }
                          ref
                              .read(_portfolioMgmtRepoProvider)
                              .reorder(reordered);
                          ref.invalidate(_myPhotosProvider);
                        },
                        builder: (children) => GridView(
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                          ),
                          children: children,
                        ),
                        children: photos
                            .map(
                              (photo) => _PhotoTile(
                                key: ValueKey(photo.id),
                                photo: photo,
                                onDelete: () => _deletePhoto(photo),
                                onToggleFeatured: () =>
                                    _toggleFeatured(photo),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    super.key,
    required this.photo,
    required this.onDelete,
    required this.onToggleFeatured,
  });

  final PortfolioPhoto photo;
  final VoidCallback onDelete;
  final VoidCallback onToggleFeatured;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: photo.thumbnailUrl ?? photo.url,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              Container(color: AppColors.greyLight),
          errorWidget: (_, __, ___) =>
              Container(color: AppColors.greyLight),
        ),
        // Star button
        Positioned(
          top: 4,
          left: 4,
          child: GestureDetector(
            onTap: onToggleFeatured,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(
                photo.isFeatured ? Icons.star_rounded : Icons.star_outline_rounded,
                color: AppColors.gold,
                size: 18,
              ),
            ),
          ),
        ),
        // Delete button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
