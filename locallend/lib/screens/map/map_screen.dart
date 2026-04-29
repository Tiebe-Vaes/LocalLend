import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme.dart';
import '../../models/item.dart';
import '../../providers/providers.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  Item? _selected;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsProvider);
    final user = ref.watch(appUserProvider).value;

    final initial = LatLng(
      user?.lat ?? 51.2194,
      user?.lng ?? 4.4025,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          final available = items.where((i) => i.available).toList();
          final markers = <Marker>{
            for (final it in available)
              Marker(
                markerId: MarkerId(it.id),
                position: LatLng(it.lat, it.lng),
                infoWindow: InfoWindow(
                  title: it.title,
                  snippet: '€${it.pricePerDay.toStringAsFixed(0)}/day',
                ),
                onTap: () => setState(() => _selected = it),
              ),
          };

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: initial, zoom: 12),
                markers: markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onTap: (_) => setState(() => _selected = null),
              ),
              if (_selected != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _ItemPreviewCard(
                    item: _selected!,
                    onClose: () => setState(() => _selected = null),
                    onOpen: () =>
                        context.push('/item/${_selected!.id}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ItemPreviewCard extends StatelessWidget {
  const _ItemPreviewCard({
    required this.item,
    required this.onClose,
    required this.onOpen,
  });
  final Item item;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 6,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.locationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '€${item.pricePerDay.toStringAsFixed(0)}/day',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
