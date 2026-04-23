import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/review.dart';
import '../../providers/providers.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/rounded_text_field.dart';
import '../../widgets/section_header.dart';

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemProvider(itemId));
    final reviewsAsync = ref.watch(reviewsByItemProvider(itemId));
    final me = ref.watch(appUserProvider).value;
    final isFav = me?.favoriteItemIds.contains(itemId) ?? false;

    return itemAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (item) {
        if (item == null) {
          return const Scaffold(body: Center(child: Text('Item not found')));
        }
        final cat = categoryById(item.categoryId);
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back,
                        color: AppColors.textPrimary),
                  ),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  if (me != null && me.id != item.ownerId)
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_outline,
                        color: isFav ? AppColors.danger : AppColors.textMuted,
                      ),
                      onPressed: () => ref
                          .read(authRepositoryProvider)
                          .toggleFavorite(me.id, itemId, !isFav),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: (item.imageUrl == null || item.imageUrl!.isEmpty)
                      ? Container(
                          color: AppColors.background,
                          child: Icon(cat.icon,
                              size: 80, color: AppColors.textMuted),
                        )
                      : CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(item.title,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700)),
                          ),
                          Text('€${item.pricePerDay.toStringAsFixed(0)}/day',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(item.locationLabel,
                            style: const TextStyle(
                                color: AppColors.textMuted)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(cat.label,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: SizedBox(
                          height: 160,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(item.lat, item.lng),
                              zoom: 14,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('item'),
                                position: LatLng(item.lat, item.lng),
                              ),
                            },
                            liteModeEnabled: true,
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SectionHeader('Description'),
                      const SizedBox(height: 8),
                      Text(item.description),
                      const SizedBox(height: 24),
                      const SectionHeader('Reviews'),
                      const SizedBox(height: 8),
                      reviewsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Text('Error: $e'),
                        data: (reviews) => reviews.isEmpty
                            ? const Text('No reviews yet.',
                                style:
                                    TextStyle(color: AppColors.textMuted))
                            : Column(
                                children: reviews
                                    .map((r) => _ReviewTile(review: r))
                                    .toList(),
                              ),
                      ),
                      if (me != null && me.id != item.ownerId) ...[
                        const SizedBox(height: 16),
                        _AddReviewBox(itemId: item.id),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomSheet: Container(
            color: AppColors.background,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SafeArea(
              top: false,
              child: PrimaryButton(
                label: item.available ? 'Rent now' : 'Unavailable',
                icon: Icons.calendar_today_outlined,
                onPressed: item.available
                    ? () => context.push('/item/${item.id}/book')
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final Review review;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(review.userName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            RatingStars(rating: review.rating.toDouble()),
          ]),
          const SizedBox(height: 4),
          Text(review.text),
        ],
      ),
    );
  }
}

class _AddReviewBox extends ConsumerStatefulWidget {
  const _AddReviewBox({required this.itemId});
  final String itemId;
  @override
  ConsumerState<_AddReviewBox> createState() => _AddReviewBoxState();
}

class _AddReviewBoxState extends ConsumerState<_AddReviewBox> {
  final _ctrl = TextEditingController();
  int _rating = 5;
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final me = ref.read(appUserProvider).value;
    if (me == null || _ctrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await ref.read(reviewRepositoryProvider).addReview(
          Review(
            id: '',
            itemId: widget.itemId,
            userId: me.id,
            userName: me.displayName,
            rating: _rating,
            text: _ctrl.text.trim(),
            createdAt: DateTime.now(),
          ),
        );
    if (mounted) {
      _ctrl.clear();
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Leave a review',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          RatingStars(
            rating: _rating.toDouble(),
            size: 24,
            onChanged: (v) => setState(() => _rating = v),
          ),
          const SizedBox(height: 8),
          RoundedTextField(
            controller: _ctrl,
            hint: 'Share your experience',
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          PrimaryButton(
              label: 'Post review', loading: _saving, onPressed: _submit),
        ],
      ),
    );
  }
}
