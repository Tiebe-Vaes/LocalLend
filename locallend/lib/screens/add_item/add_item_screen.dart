import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/item.dart';
import '../../providers/providers.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/rounded_text_field.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});
  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _location = TextEditingController();
  String _categoryId = kCategories.first.id;
  LatLng? _point;
  GoogleMapController? _mapCtrl;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied ||
          p == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final ll = LatLng(pos.latitude, pos.longitude);
      setState(() => _point = ll);
      _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(ll, 14));
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a location on the map.')),
      );
      return;
    }
    final me = ref.read(appUserProvider).value;
    if (me == null) return;
    setState(() => _saving = true);
    try {
      final itemRepo = ref.read(itemRepositoryProvider);

      final item = Item(
        id: '',
        ownerId: me.id,
        ownerName: me.displayName,
        title: _title.text.trim(),
        description: _desc.text.trim(),
        categoryId: _categoryId,
        pricePerDay: double.parse(_price.text.trim()),
        imageUrl: null,
        lat: _point!.latitude,
        lng: _point!.longitude,
        locationLabel: _location.text.trim().isEmpty ? 'Nearby' : _location.text.trim(),
        createdAt: DateTime.now(),
      );
      await itemRepo.addItem(item);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = _point ?? const LatLng(51.2194, 4.4025);
    return Scaffold(
      appBar: AppBar(title: const Text('List an item')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.textMuted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Image uploads unavailable in your region. Items will display with category icons.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            RoundedTextField(
              controller: _title,
              label: 'Title',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            RoundedTextField(
              controller: _desc,
              label: 'Description',
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            const Text('Category'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in kCategories)
                  CategoryChip(
                    category: c,
                    selected: _categoryId == c.id,
                    onTap: () => setState(() => _categoryId = c.id),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            RoundedTextField(
              controller: _price,
              label: 'Price per day (€)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v.trim()) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            RoundedTextField(
              controller: _location,
              label: 'Location label',
              hint: 'e.g. Antwerp, Zuid',
            ),
            const SizedBox(height: 12),
            const Text('Pin location (tap map)'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                height: 200,
                child: GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: initial, zoom: 13),
                  onMapCreated: (c) => _mapCtrl = c,
                  onTap: (ll) => setState(() => _point = ll),
                  markers: _point == null
                      ? {}
                      : {
                          Marker(
                            markerId: const MarkerId('new'),
                            position: _point!,
                          ),
                        },
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _useCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Use current location'),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Publish',
              loading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
