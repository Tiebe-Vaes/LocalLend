import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/config.dart';
import 'places_types.dart';

/// Native (mobile/desktop) implementation that calls Google Places REST APIs.
class PlacesService {
  PlacesService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  String get _key => AppConfig.googleMapsApiKey;

  /// Returns address suggestions for the user's query.
  Future<List<PlaceSuggestion>> autocomplete(String input,
      {String? sessionToken}) async {
    if (input.trim().isEmpty || _key.isEmpty) return const [];
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': input,
        'key': _key,
        'sessiontoken': ?sessionToken,
      },
    );
    final res = await _client.get(uri);
    if (res.statusCode != 200) return const [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final preds = (data['predictions'] as List?) ?? const [];
    return preds
        .map((p) => PlaceSuggestion(
              placeId: p['place_id'] as String,
              description: p['description'] as String,
            ))
        .toList();
  }

  /// Resolves a Place id to its coordinates and formatted address.
  Future<PlaceDetails?> details(String placeId, {String? sessionToken}) async {
    if (_key.isEmpty) return null;
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': placeId,
        'fields': 'geometry/location,formatted_address',
        'key': _key,
        'sessiontoken': ?sessionToken,
      },
    );
    final res = await _client.get(uri);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final result = data['result'] as Map<String, dynamic>?;
    if (result == null) return null;
    final loc = (result['geometry']?['location']) as Map<String, dynamic>?;
    if (loc == null) return null;
    return PlaceDetails(
      lat: (loc['lat'] as num).toDouble(),
      lng: (loc['lng'] as num).toDouble(),
      formattedAddress: (result['formatted_address'] ?? '') as String,
    );
  }

  /// Converts coordinates back to a human-readable address.
  Future<String?> reverseGeocode(double lat, double lng) async {
    if (_key.isEmpty) return null;
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {'latlng': '$lat,$lng', 'key': _key},
    );
    final res = await _client.get(uri);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (data['results'] as List?) ?? const [];
    if (results.isEmpty) return null;
    return (results.first['formatted_address'] ?? '') as String;
  }
}
