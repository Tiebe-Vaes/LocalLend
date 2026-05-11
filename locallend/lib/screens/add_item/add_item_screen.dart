import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/item.dart';
import '../../providers/providers.dart';
import '../../widgets/address_field.dart';
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
  final _address = TextEditingController();
  String _categoryId = kCategories.first.id;
  LatLng? _point;
  String _formattedAddress = '';
  GoogleMapController? _mapCtrl;
  bool _saving = false;
  Uint8List? _imageBytes;
  String? _imageBase64;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      // Firestore doc limit ~1MB. Reject if encoded would exceed ~900KB.
      final encoded = base64Encode(bytes);
      if (encoded.length > 900 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image too large. Pick a smaller one.'),
            ),
          );
        }
        return;
      }
      setState(() {
        _imageBytes = bytes;
        _imageBase64 = encoded;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image pick failed: $e')),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_imageBytes != null)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.danger),
                title: const Text('Remove image'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _imageBytes = null;
                    _imageBase64 = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _address.dispose();
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
      final addr = await ref
          .read(placesServiceProvider)
          .reverseGeocode(pos.latitude, pos.longitude);
      setState(() {
        _point = ll;
        _formattedAddress = addr ?? '';
        _address.text = _formattedAddress;
      });
      _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(ll, 15));
    } catch (_) {}
  }

  void _onAddressPicked(AddressPickResult r) {
    final ll = LatLng(r.lat, r.lng);
    setState(() {
      _point = ll;
      _formattedAddress = r.formattedAddress;
    });
    _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(ll, 15));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick an address.')),
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
        imageBase64: _imageBase64,
        lat: _point!.latitude,
        lng: _point!.longitude,
        locationLabel: _formattedAddress,
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
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imageBytes == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                size: 36, color: AppColors.textMuted),
                            SizedBox(height: 8),
                            Text('Add a photo',
                                style: TextStyle(color: AppColors.textMuted)),
                          ],
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_imageBytes!, fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: Colors.black54,
                              shape: const CircleBorder(),
                              child: IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.white, size: 18),
                                onPressed: _showImageSourceSheet,
                              ),
                            ),
                          ),
                        ],
                      ),
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
            AddressField(
              controller: _address,
              onPicked: _onAddressPicked,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _useCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Use current location'),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                height: 360,
                child: GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: initial, zoom: 13),
                  onMapCreated: (c) => _mapCtrl = c,
                  markers: _point == null
                      ? {}
                      : {
                          Marker(
                            markerId: const MarkerId('new'),
                            position: _point!,
                          ),
                        },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),
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
