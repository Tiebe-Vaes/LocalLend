import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/item_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(appUserProvider).value;
    final itemsAsync = ref.watch(itemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          final favIds = me?.favoriteItemIds ?? const [];
          final favs = items.where((i) => favIds.contains(i.id)).toList();
          if (favs.isEmpty) {
            return const Center(
              child: Text('No favorites yet. Tap the heart on an item.',
                  style: TextStyle(color: AppColors.textMuted)),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: favs.length,
            itemBuilder: (_, i) => ItemCard(
              item: favs[i],
              userLat: me?.lat,
              userLng: me?.lng,
              onTap: () => context.push('/item/${favs[i].id}'),
            ),
          );
        },
      ),
    );
  }
}
