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
import '../../core/utils.dart';
import '../../models/item.dart';
import '../../providers/providers.dart';
import '../../widgets/address_field.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/rounded_text_field.dart';

/// Form to create a new item listing — title, category, photo, location, etc.
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
  final Set<String> _availDayKeys = {};

  /// Opens the per-day availability picker sheet.
  Future<void> _pickAvailabilityDays() async {
    final picked = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _AvailabilityPicker(initial: _availDayKeys),
    );
    if (picked != null) {
      setState(() {
        _availDayKeys
          ..clear()
          ..addAll(picked);
      });
    }
  }

  /// Opens the image picker, resizes/encodes the result and rejects oversize files.
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

  /// Shows the gallery/camera/remove sheet for the image field.
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

  /// Reads GPS, reverse-geocodes it and prefills the address field.
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

  /// Stores the picked address and recenters the map.
  void _onAddressPicked(AddressPickResult r) {
    final ll = LatLng(r.lat, r.lng);
    setState(() {
      _point = ll;
      _formattedAddress = r.formattedAddress;
    });
    _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(ll, 15));
  }

  /// Validates the form and writes the new item to Firestore.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick an address.')),
      );
      return;
    }
    if (_availDayKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick at least one available day.')),
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
        availableDayKeys: _availDayKeys.toList()..sort(),
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
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickAvailabilityDays,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available,
                        color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Availability',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(
                            _availDayKeys.isEmpty
                                ? 'Tap to select the days this item is available'
                                : '${_availDayKeys.length} day(s) selected',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textMuted),
                  ],
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

/// Bottom-sheet calendar that lets the owner toggle individual available days.
class _AvailabilityPicker extends StatefulWidget {
  const _AvailabilityPicker({required this.initial});
  final Set<String> initial;

  @override
  State<_AvailabilityPicker> createState() => _AvailabilityPickerState();
}

class _AvailabilityPickerState extends State<_AvailabilityPicker> {
  late final Set<String> _selected = {...widget.initial};
  late DateTime _month =
      DateTime(DateTime.now().year, DateTime.now().month);

  /// Adds or removes a single day from the selection.
  void _toggle(DateTime day) {
    final k = dayKey(day);
    setState(() {
      if (_selected.contains(k)) {
        _selected.remove(k);
      } else {
        _selected.add(k);
      }
    });
  }

  /// Bulk-select or bulk-clear all eligible days of the visible month.
  void _selectMonth({bool select = true}) {
    final tomorrow = dayOnly(DateTime.now()).add(const Duration(days: 1));
    final last = DateTime(_month.year, _month.month + 1, 0).day;
    setState(() {
      for (var i = 1; i <= last; i++) {
        final d = DateTime(_month.year, _month.month, i);
        if (d.isBefore(tomorrow)) continue;
        final k = dayKey(d);
        if (select) {
          _selected.add(k);
        } else {
          _selected.remove(k);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tomorrow = dayOnly(DateTime.now()).add(const Duration(days: 1));
    final last = DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday;
    final cells = <DateTime?>[
      for (var i = 1; i < firstWeekday; i++) null,
      for (var i = 1; i <= last; i++) DateTime(_month.year, _month.month, i),
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text('Pick available days',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                Text('${_selected.length} selected',
                    style: const TextStyle(color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _month =
                      DateTime(_month.year, _month.month - 1)),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _monthLabel(_month),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _month =
                      DateTime(_month.year, _month.month + 1)),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => _selectMonth(select: true),
                  child: const Text('Select month'),
                ),
                TextButton(
                  onPressed: () => _selectMonth(select: false),
                  child: const Text('Clear month'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d,
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                controller: scrollCtrl,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: cells.length,
                itemBuilder: (_, i) {
                  final day = cells[i];
                  if (day == null) return const SizedBox.shrink();
                  final tooEarly = dayOnly(day).isBefore(tomorrow);
                  final selected = _selected.contains(dayKey(day));
                  return GestureDetector(
                    onTap: tooEarly ? null : () => _toggle(day),
                    child: Container(
                      decoration: BoxDecoration(
                        color: tooEarly
                            ? AppColors.background
                            : (selected
                                ? AppColors.primary
                                : AppColors.surface),
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: selected
                              ? AppColors.primaryDark
                              : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: tooEarly
                                ? AppColors.textMuted
                                : (selected
                                    ? Colors.white
                                    : AppColors.textPrimary),
                            decoration: tooEarly
                                ? TextDecoration.lineThrough
                                : null,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Done',
                onPressed: () => Navigator.pop(context, _selected),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "January 2026"-style label for the month header.
  String _monthLabel(DateTime m) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[m.month - 1]} ${m.year}';
  }
}
