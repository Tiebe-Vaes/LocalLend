/// Lightweight Place id + label returned by the autocomplete API.
class PlaceSuggestion {
  final String placeId;
  final String description;
  const PlaceSuggestion({required this.placeId, required this.description});
}

/// Resolved coordinates + formatted address for a Place.
class PlaceDetails {
  final double lat;
  final double lng;
  final String formattedAddress;
  const PlaceDetails({
    required this.lat,
    required this.lng,
    required this.formattedAddress,
  });
}
