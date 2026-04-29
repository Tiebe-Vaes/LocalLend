class PlaceSuggestion {
  final String placeId;
  final String description;
  const PlaceSuggestion({required this.placeId, required this.description});
}

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
