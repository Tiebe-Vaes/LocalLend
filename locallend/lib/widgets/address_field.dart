import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/theme.dart';
import '../providers/providers.dart';
import '../services/places_service.dart';

/// Payload emitted when the user picks an address suggestion.
class AddressPickResult {
  final double lat;
  final double lng;
  final String formattedAddress;
  const AddressPickResult({
    required this.lat,
    required this.lng,
    required this.formattedAddress,
  });
}

/// Text field with Google Places autocomplete shown in a floating overlay.
class AddressField extends ConsumerStatefulWidget {
  const AddressField({
    super.key,
    required this.controller,
    required this.onPicked,
    this.label = 'Address',
    this.hint = 'Start typing an address…',
  });

  final TextEditingController controller;
  final ValueChanged<AddressPickResult> onPicked;
  final String label;
  final String hint;

  @override
  ConsumerState<AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends ConsumerState<AddressField> {
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  final _uuid = const Uuid();

  Timer? _debounce;
  String _sessionToken = '';
  List<PlaceSuggestion> _suggestions = const [];
  OverlayEntry? _overlay;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _sessionToken = _uuid.v4();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  /// Hides the suggestion overlay when focus is lost.
  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 150), _removeOverlay);
    } else if (_suggestions.isNotEmpty) {
      _showOverlay();
    }
  }

  /// Debounced query — fires Places autocomplete and shows results.
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      if (value.trim().length < 3) {
        setState(() => _suggestions = const []);
        _removeOverlay();
        return;
      }
      setState(() => _loading = true);
      final svc = ref.read(placesServiceProvider);
      final results =
          await svc.autocomplete(value, sessionToken: _sessionToken);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _loading = false;
      });
      if (results.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  /// Fetches details for the tapped suggestion and notifies the parent.
  Future<void> _select(PlaceSuggestion s) async {
    _removeOverlay();
    _focusNode.unfocus();
    final svc = ref.read(placesServiceProvider);
    final details = await svc.details(s.placeId, sessionToken: _sessionToken);
    _sessionToken = _uuid.v4();
    if (details == null) return;
    widget.controller.text = details.formattedAddress;
    widget.onPicked(AddressPickResult(
      lat: details.lat,
      lng: details.lng,
      formattedAddress: details.formattedAddress,
    ));
  }

  /// Builds and inserts the suggestion list overlay below the field.
  void _showOverlay() {
    _removeOverlay();
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    _overlay = OverlayEntry(
      builder: (_) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.border),
                itemBuilder: (_, i) {
                  final s = _suggestions[i];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined,
                        color: AppColors.textMuted),
                    title: Text(
                      s.description,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _select(s),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  /// Tears down any active overlay.
  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : (widget.controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            widget.controller.clear();
                            setState(() => _suggestions = const []);
                            _removeOverlay();
                          },
                        )
                      : null),
            ),
          ),
        ],
      ),
    );
  }
}
