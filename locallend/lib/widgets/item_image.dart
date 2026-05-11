import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/item.dart';

/// Renders the right image for an item: inline base64 → URL → category icon.
class ItemImage extends StatelessWidget {
  const ItemImage({
    super.key,
    required this.item,
    required this.placeholderIcon,
    this.fit = BoxFit.cover,
    this.placeholderSize = 40,
  });

  final Item item;
  final IconData placeholderIcon;
  final BoxFit fit;
  final double placeholderSize;

  @override
  Widget build(BuildContext context) {
    final b64 = item.imageBase64;
    if (b64 != null && b64.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(b64);
        return Image.memory(
          bytes,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, e, s) => _placeholder(),
        );
      } catch (_) {
        return _placeholder();
      }
    }
    final url = item.imageUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        placeholder: (_, _) => Container(color: AppColors.background),
        errorWidget: (_, _, _) => _placeholder(broken: true),
      );
    }
    return _placeholder();
  }

  Widget _placeholder({bool broken = false}) => Container(
        color: AppColors.background,
        child: Icon(
          broken ? Icons.broken_image : placeholderIcon,
          size: placeholderSize,
          color: AppColors.textMuted,
        ),
      );
}
