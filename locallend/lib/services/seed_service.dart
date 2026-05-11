import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils.dart';

/// Idempotent demo seeder. Writes a few sample items if the `items`
/// collection is empty. Safe to call on every launch.
/// Seeds and reseeds the demo Firestore data.
class SeedService {
  SeedService(this._db);
  final FirebaseFirestore _db;

  static const _flag = 'seeded_v2';

  /// Writes the demo dataset on first launch; no-op once `seeded_v2` is recorded.
  Future<void> seedIfEmpty() async {
    final meta = await _db.collection('meta').doc(_flag).get();
    if (meta.exists) return;

    final batch = _db.batch();
    final col = _db.collection('items');
    final now = Timestamp.fromDate(DateTime.now());
    final defaultAvail = _next30Days();

    final samples = <Map<String, dynamic>>[
      {
        'title': 'Bosch Cordless Vacuum',
        'description':
            'Lightweight cordless vacuum, 40 min runtime. Great for quick clean-ups.',
        'categoryId': 'cleaning',
        'pricePerDay': 8.0,
        'lat': 51.2213,
        'lng': 4.3997,
        'locationLabel': 'Grote Markt, 2000 Antwerpen',
        'imageUrl':
            'https://images.unsplash.com/photo-1558317374-067fb5f30001?w=800',
      },
      {
        'title': 'Electric Lawn Mower',
        'description': 'Silent electric mower, 40 cm cutting width.',
        'categoryId': 'garden',
        'pricePerDay': 15.0,
        'lat': 51.2058,
        'lng': 4.4290,
        'locationLabel': 'Dageraadplaats, 2018 Antwerpen (Zurenborg)',
        'imageUrl':
            'https://images.unsplash.com/photo-1558904541-efa843a96f01?w=800',
      },
      {
        'title': 'KitchenAid Stand Mixer',
        'description': 'Classic stand mixer with whisk, dough hook and paddle.',
        'categoryId': 'kitchen',
        'pricePerDay': 12.0,
        'lat': 51.2074,
        'lng': 4.3925,
        'locationLabel': 'Vlaamsekaai, 2000 Antwerpen (Het Zuid)',
        'imageUrl':
            'https://images.unsplash.com/photo-1578643463396-0997cb5328c1?w=800',
      },
      {
        'title': 'Makita Power Drill',
        'description': '18V brushless drill, two batteries, charger included.',
        'categoryId': 'tools',
        'pricePerDay': 10.0,
        'lat': 51.1989,
        'lng': 4.4326,
        'locationLabel': 'Statiestraat, 2600 Berchem',
        'imageUrl':
            'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=800',
      },
      {
        'title': 'Karcher Pressure Washer',
        'description': 'High-pressure washer, ideal for driveways and bikes.',
        'categoryId': 'cleaning',
        'pricePerDay': 14.0,
        'lat': 51.2236,
        'lng': 4.4636,
        'locationLabel': 'Cogelsplein, 2100 Deurne',
        'imageUrl':
            'https://images.unsplash.com/photo-1617104666168-4b3f8d4d1c96?w=800',
      },
      {
        'title': 'Philips Steam Iron',
        'description': 'Powerful steam iron with anti-calc system.',
        'categoryId': 'other',
        'pricePerDay': 4.0,
        'lat': 51.2186,
        'lng': 4.4380,
        'locationLabel': 'Turnhoutsebaan, 2140 Borgerhout',
        'imageUrl':
            'https://images.unsplash.com/photo-1610557892470-55d9e80c0bce?w=800',
      },
      {
        'title': 'Bosch Hedge Trimmer',
        'description': '50 cm cordless hedge trimmer, two batteries included.',
        'categoryId': 'garden',
        'pricePerDay': 9.0,
        'lat': 51.1707,
        'lng': 4.3920,
        'locationLabel': 'Bist, 2610 Wilrijk',
        'imageUrl':
            'https://images.unsplash.com/photo-1599598425947-5b6f1a1aa3d2?w=800',
      },
      {
        'title': 'Philips Airfryer XXL',
        'description': '7.3 L airfryer, fits a whole chicken.',
        'categoryId': 'kitchen',
        'pricePerDay': 6.0,
        'lat': 51.2295,
        'lng': 4.4051,
        'locationLabel': 'Hanzestedenplaats, 2000 Antwerpen (Eilandje)',
        'imageUrl':
            'https://images.unsplash.com/photo-1626202373052-9cb6c43cf852?w=800',
      },
      {
        'title': 'Wet Tile Cutter',
        'description':
            'Electric wet tile cutter, 600 mm cutting length. Ideal for bathroom renos.',
        'categoryId': 'tools',
        'pricePerDay': 18.0,
        'lat': 51.1942,
        'lng': 4.3911,
        'locationLabel': 'Abdijstraat, 2020 Antwerpen (Kiel)',
        'imageUrl':
            'https://images.unsplash.com/photo-1581094271901-8022df4466f9?w=800',
      },
      {
        'title': 'Epson Full HD Projector',
        'description':
            '1080p projector with HDMI + speakers. Perfect for outdoor movie nights.',
        'categoryId': 'electronics',
        'pricePerDay': 20.0,
        'lat': 51.2189,
        'lng': 4.3837,
        'locationLabel': 'Sint-Annastrand, 2050 Antwerpen (Linkeroever)',
        'imageUrl':
            'https://images.unsplash.com/photo-1626379953822-baec19c3accd?w=800',
      },
    ];

    for (final s in samples) {
      final ref = col.doc();
      batch.set(ref, {
        ...s,
        'ownerId': 'demo_owner',
        'ownerName': 'Demo Owner',
        'available': true,
        'availableDayKeys': defaultAvail,
        'createdAt': now,
      });
    }
    batch.set(_db.collection('meta').doc(_flag), {'seededAt': now});
    await batch.commit();
  }

  /// Destroys all items, bookings and reviews, then reseeds demo data.
  /// Intended for the in-app "Reseed" button — wipes everything visible.
  Future<void> reseedAll() async {
    await _clearCollection('items');
    await _clearCollection('bookings');
    await _clearCollection('reviews');
    await _clearCollection('meta');
    await seedIfEmpty();
  }

  /// Day-keys for the 30 days starting tomorrow, used as default availability.
  List<String> _next30Days() {
    final start = dayOnly(DateTime.now()).add(const Duration(days: 1));
    return [
      for (var i = 0; i < 30; i++)
        dayKey(start.add(Duration(days: i))),
    ];
  }

  /// Deletes every document in [name] in 450-op batches.
  Future<void> _clearCollection(String name) async {
    final snap = await _db.collection(name).get();
    if (snap.docs.isEmpty) return;
    // Batch is capped at 500 ops.
    var batch = _db.batch();
    var count = 0;
    for (final d in snap.docs) {
      batch.delete(d.reference);
      count++;
      if (count == 450) {
        await batch.commit();
        batch = _db.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
  }
}
