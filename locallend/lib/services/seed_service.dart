import 'package:cloud_firestore/cloud_firestore.dart';

/// Idempotent demo seeder. Writes a few sample items if the `items`
/// collection is empty. Safe to call on every launch.
class SeedService {
  SeedService(this._db);
  final FirebaseFirestore _db;

  static const _flag = 'seeded_v1';

  Future<void> seedIfEmpty() async {
    final meta = await _db.collection('meta').doc(_flag).get();
    if (meta.exists) return;

    final batch = _db.batch();
    final col = _db.collection('items');
    final now = Timestamp.fromDate(DateTime.now());

    final samples = <Map<String, dynamic>>[
      {
        'title': 'Bosch Cordless Vacuum',
        'description':
            'Lightweight cordless vacuum, 40 min runtime. Great for quick clean-ups.',
        'categoryId': 'cleaning',
        'pricePerDay': 8.0,
        'lat': 51.2194,
        'lng': 4.4025,
        'locationLabel': 'Antwerp, Centrum',
        'imageUrl':
            'https://images.unsplash.com/photo-1558317374-067fb5f30001?w=800',
      },
      {
        'title': 'Electric Lawn Mower',
        'description': 'Silent electric mower, 40 cm cutting width.',
        'categoryId': 'garden',
        'pricePerDay': 15.0,
        'lat': 51.2230,
        'lng': 4.4150,
        'locationLabel': 'Antwerp, Zurenborg',
        'imageUrl':
            'https://images.unsplash.com/photo-1558904541-efa843a96f01?w=800',
      },
      {
        'title': 'KitchenAid Stand Mixer',
        'description': 'Classic stand mixer with whisk, dough hook and paddle.',
        'categoryId': 'kitchen',
        'pricePerDay': 12.0,
        'lat': 51.2100,
        'lng': 4.3950,
        'locationLabel': 'Antwerp, Zuid',
        'imageUrl':
            'https://images.unsplash.com/photo-1578643463396-0997cb5328c1?w=800',
      },
      {
        'title': 'Makita Power Drill',
        'description': '18V brushless drill, two batteries, charger included.',
        'categoryId': 'tools',
        'pricePerDay': 10.0,
        'lat': 51.2260,
        'lng': 4.4080,
        'locationLabel': 'Antwerp, Kiel',
        'imageUrl':
            'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=800',
      },
      {
        'title': 'Pressure Washer',
        'description': 'High-pressure washer, ideal for driveways and bikes.',
        'categoryId': 'cleaning',
        'pricePerDay': 14.0,
        'lat': 51.2400,
        'lng': 4.4200,
        'locationLabel': 'Antwerp, Deurne',
        'imageUrl':
            'https://images.unsplash.com/photo-1617104666168-4b3f8d4d1c96?w=800',
      },
    ];

    for (final s in samples) {
      final ref = col.doc();
      batch.set(ref, {
        ...s,
        'ownerId': 'demo_owner',
        'ownerName': 'Demo Owner',
        'available': true,
        'createdAt': now,
      });
    }
    batch.set(_db.collection('meta').doc(_flag), {'seededAt': now});
    await batch.commit();
  }
}
