import 'package:flutter/material.dart';
import '../core/theme.dart';

/// 5-star rating display; becomes tappable when [onChanged] is provided.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.onChanged,
  });

  final double rating;
  final double size;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.round();
        final star = Icon(
          filled ? Icons.star : Icons.star_border,
          size: size,
          color: AppColors.primary,
        );
        if (onChanged == null) return star;
        return GestureDetector(
          onTap: () => onChanged!(i + 1),
          child: Padding(padding: const EdgeInsets.all(2), child: star),
        );
      }),
    );
  }
}
