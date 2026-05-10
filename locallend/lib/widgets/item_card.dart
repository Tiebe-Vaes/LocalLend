import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import '../core/constants.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/item.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.userLat,
    this.userLng,
  });

  final Item item;
  final VoidCallback onTap;
  final double? userLat;
  final double? userLng;

  Widget _buildImage(String imageData) {
    try {
      if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
        return CachedNetworkImage(
          imageUrl: imageData,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(color: AppColors.background),
          errorWidget: (_, _, _) => Container(
            color: AppColors.background,
            child: const Icon(Icons.broken_image, color: AppColors.textMuted),
          ),
        );
      } else {
        final imageBytes = base64Decode(imageData);
        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.background,
            child: const Icon(Icons.broken_image, color: AppColors.textMuted),
          ),
        );
      }
    } catch (_) {
      return Container(
        color: AppColors.background,
        child: const Icon(Icons.broken_image, color: AppColors.textMuted),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = categoryById(item.categoryId);
    final distance = (userLat != null && userLng != null)
        ? haversineKm(userLat!, userLng!, item.lat, item.lng)
        : null;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.4,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.md),
                  ),
                  child: (item.imageUrl == null || item.imageUrl!.isEmpty)
                      ? Container(
                          color: AppColors.background,
                          child: Icon(cat.icon,
                              size: 40, color: AppColors.textMuted),
                        )
                      : _buildImage(item.imageUrl!),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            distance != null
                                ? '${distance.toStringAsFixed(1)} km'
                                : item.locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '€${item.pricePerDay.toStringAsFixed(0)}/day',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            cat.label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
}
