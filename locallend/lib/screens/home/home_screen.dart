import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/item_card.dart';

/// Main browse screen: search bar, category chips and grid of items.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncLocation());
  }

  /// Requests location permission and persists the user's current coords.
  Future<void> _syncLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final uid = ref.read(authStateProvider).value?.uid;
      if (uid != null) {
        await ref
            .read(authRepositoryProvider)
            .updateLocation(uid, pos.latitude, pos.longitude);
      }
    } catch (_) {/* fail silently on the demo */}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Opens the bottom-sheet filter editor.
  void _openFilter() {
    final filter = ref.read(browseFilterProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _FilterSheet(initial: filter),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(filteredItemsProvider);
    final user = ref.watch(appUserProvider).value;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hello 👋',
                            style: TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          user?.displayName.isNotEmpty == true
                              ? user!.displayName
                              : 'Browse nearby items',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Search for vacuum, drill…',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) =>
                          ref.read(browseFilterProvider.notifier).setQuery(v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: InkWell(
                      onTap: _openFilter,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Icon(Icons.tune, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: kCategories.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    final selected = ref
                            .watch(browseFilterProvider)
                            .categoryId ==
                        null;
                    return InkWell(
                      onTap: () => ref
                          .read(browseFilterProvider.notifier)
                          .setCategory(null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'All',
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }
                  final cat = kCategories[i - 1];
                  final selected =
                      ref.watch(browseFilterProvider).categoryId == cat.id;
                  return CategoryChip(
                    category: cat,
                    selected: selected,
                    onTap: () => ref
                        .read(browseFilterProvider.notifier)
                        .setCategory(selected ? null : cat.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(
                        child: Text('No items match your filters.',
                            style: TextStyle(color: AppColors.textMuted)));
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final it = list[i];
                      return ItemCard(
                        item: it,
                        userLat: user?.lat,
                        userLng: user?.lng,
                        onTap: () => context.push('/item/${it.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet editor for the [BrowseFilter] (category + radius).
class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.initial});
  final BrowseFilter initial;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late String? _catId = widget.initial.categoryId;
  late double _radius = widget.initial.radiusKm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          const Text('Category'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in kCategories)
                CategoryChip(
                  category: c,
                  selected: _catId == c.id,
                  onTap: () => setState(
                      () => _catId = _catId == c.id ? null : c.id),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Distance'),
              const Spacer(),
              Text('${_radius.toStringAsFixed(0)} km'),
            ],
          ),
          Slider(
            value: _radius,
            min: 1,
            max: kMaxRadiusKm,
            divisions: kMaxRadiusKm.toInt() - 1,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _radius = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _catId = null;
                      _radius = kDefaultRadiusKm;
                    });
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(browseFilterProvider.notifier)
                      ..setCategory(_catId)
                      ..setRadius(_radius);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
