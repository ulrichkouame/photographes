/// 3-column portfolio photo grid with photo_view zoom on tap.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/portfolio_photo_model.dart';

/// Renders portfolio photos in a 3-column grid. Tapping opens a zoomable gallery.
class PortfolioGrid extends StatelessWidget {
  const PortfolioGrid({super.key, required this.photos});

  final List<PortfolioPhoto> photos;

  void _openGallery(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenGallery(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return GestureDetector(
          onTap: () => _openGallery(context, index),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: photo.thumbnailUrl ?? photo.url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.greyLight,
                  child: const Icon(Icons.image_outlined, color: AppColors.grey),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.greyLight,
                  child: const Icon(Icons.broken_image_outlined, color: AppColors.grey),
                ),
              ),
              if (photo.isFeatured)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(Icons.star_rounded, color: AppColors.gold, size: 16),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Full-screen swipeable gallery using [PhotoViewGallery].
class _FullScreenGallery extends StatefulWidget {
  const _FullScreenGallery({
    required this.photos,
    required this.initialIndex,
  });

  final List<PortfolioPhoto> photos;
  final int initialIndex;

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.photos.length}'),
      ),
      body: PhotoViewGallery.builder(
        itemCount: widget.photos.length,
        pageController: PageController(initialPage: widget.initialIndex),
        onPageChanged: (i) => setState(() => _currentIndex = i),
        builder: (context, index) => PhotoViewGalleryPageOptions(
          imageProvider:
              CachedNetworkImageProvider(widget.photos[index].url),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
        ),
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }
}
