import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String description;
  final String categoryId;
  final double pricePerDay;
  final String? imageUrl;
  final String? imageBase64;
  final double lat;
  final double lng;
  final String locationLabel;
  final bool available;
  final DateTime createdAt;

  const Item({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.pricePerDay,
    this.imageUrl,
    this.imageBase64,
    required this.lat,
    required this.lng,
    required this.locationLabel,
    this.available = true,
    required this.createdAt,
  });

  Item copyWith({bool? available, String? imageUrl, String? imageBase64}) => Item(
        id: id,
        ownerId: ownerId,
        ownerName: ownerName,
        title: title,
        description: description,
        categoryId: categoryId,
        pricePerDay: pricePerDay,
        imageUrl: imageUrl ?? this.imageUrl,
        imageBase64: imageBase64 ?? this.imageBase64,
        lat: lat,
        lng: lng,
        locationLabel: locationLabel,
        available: available ?? this.available,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'ownerName': ownerName,
        'title': title,
        'description': description,
        'categoryId': categoryId,
        'pricePerDay': pricePerDay,
        'imageUrl': imageUrl,
        'imageBase64': imageBase64,
        'lat': lat,
        'lng': lng,
        'locationLabel': locationLabel,
        'available': available,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Item.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Item(
      id: doc.id,
      ownerId: (d['ownerId'] ?? '') as String,
      ownerName: (d['ownerName'] ?? '') as String,
      title: (d['title'] ?? '') as String,
      description: (d['description'] ?? '') as String,
      categoryId: (d['categoryId'] ?? 'other') as String,
      pricePerDay: (d['pricePerDay'] as num?)?.toDouble() ?? 0.0,
      imageUrl: d['imageUrl'] as String?,
      imageBase64: d['imageBase64'] as String?,
      lat: (d['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (d['lng'] as num?)?.toDouble() ?? 0.0,
      locationLabel: (d['locationLabel'] ?? '') as String,
      available: (d['available'] ?? true) as bool,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
