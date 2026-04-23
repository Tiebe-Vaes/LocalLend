import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final double? lat;
  final double? lng;
  final List<String> favoriteItemIds;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.lat,
    this.lng,
    this.favoriteItemIds = const [],
    required this.createdAt,
  });

  AppUser copyWith({
    String? displayName,
    double? lat,
    double? lng,
    List<String>? favoriteItemIds,
  }) => AppUser(
        id: id,
        email: email,
        displayName: displayName ?? this.displayName,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        favoriteItemIds: favoriteItemIds ?? this.favoriteItemIds,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'lat': lat,
        'lng': lng,
        'favoriteItemIds': favoriteItemIds,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      id: doc.id,
      email: (d['email'] ?? '') as String,
      displayName: (d['displayName'] ?? '') as String,
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
      favoriteItemIds: List<String>.from(d['favoriteItemIds'] ?? const []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
