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
        'title': 'Dyson V11 Vacuum Cleaner',
        'description':
            'Powerful cordless vacuum with 60 min battery life.',
        'categoryId': 'cleaning',
        'pricePerDay': 10.0,
        'lat': 51.2194,
        'lng': 4.4025,
        'locationLabel': 'Meir, 2000 Antwerpen',
        'imageUrl':
            'https://images.unsplash.com/photo-1558317374-067fb5f30001?w=800',
      },
      {
        'title': 'Bosch Electric Lawn Mower',
        'description':
            'Quiet electric mower for medium gardens.',
        'categoryId': 'garden',
        'pricePerDay': 16.0,
        'lat': 51.1703,
        'lng': 4.3906,
        'locationLabel': 'Bist, 2610 Wilrijk',
        'imageUrl':
            'https://images.unsplash.com/photo-1598514983318-2f64f8f4796c?w=800',
      },
      {
        'title': 'KitchenAid Artisan Mixer',
        'description':
            'Premium stand mixer with multiple attachments.',
        'categoryId': 'kitchen',
        'pricePerDay': 14.0,
        'lat': 51.2078,
        'lng': 4.3923,
        'locationLabel': 'Vlaamsekaai, 2000 Antwerpen',
        'imageUrl':
            'https://images.unsplash.com/photo-1578643463396-0997cb5328c1?w=800',
      },
      {
        'title': 'Makita Cordless Drill',
        'description':
            '18V drill with charger and two batteries.',
        'categoryId': 'tools',
        'pricePerDay': 9.0,
        'lat': 51.1998,
        'lng': 4.4320,
        'locationLabel': 'Statiestraat, 2600 Berchem',
        'imageUrl':
            'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=800',
      },
      {
        'title': 'Kärcher Pressure Washer',
        'description':
            'Ideal for patios, bikes and outdoor cleaning.',
        'categoryId': 'cleaning',
        'pricePerDay': 15.0,
        'lat': 51.2233,
        'lng': 4.4638,
        'locationLabel': 'Cogelsplein, 2100 Deurne',
        'imageUrl':
            'https://images.unsplash.com/photo-1604335399105-a0c585fd81a1?w=800',
      },
      {
        'title': 'Philips Steam Iron',
        'description':
            'Fast-heating steam iron with anti-scale system.',
        'categoryId': 'other',
        'pricePerDay': 5.0,
        'lat': 51.2182,
        'lng': 4.4386,
        'locationLabel': 'Turnhoutsebaan, 2140 Borgerhout',
        'imageUrl':
            'https://images.unsplash.com/photo-1610557892470-55d9e80c0bce?w=800',
      },
      {
        'title': 'Bosch Hedge Trimmer',
        'description':
            'Cordless hedge trimmer for precise cuts.',
        'categoryId': 'garden',
        'pricePerDay': 8.0,
        'lat': 51.1750,
        'lng': 4.4195,
        'locationLabel': 'Jules Moretuslei, 2610 Wilrijk',
        'imageUrl':
            'https://images.unsplash.com/photo-1599598425947-5b6f1a1aa3d2?w=800',
      },
      {
        'title': 'Philips Airfryer XXL',
        'description':
            'Large-capacity air fryer for family meals.',
        'categoryId': 'kitchen',
        'pricePerDay': 7.0,
        'lat': 51.2302,
        'lng': 4.4041,
        'locationLabel': 'Hanzestedenplaats, 2000 Antwerpen',
        'imageUrl':
            'https://images.unsplash.com/photo-1626202373052-9cb6c43cf852?w=800',
      },
      {
        'title': 'Wet Tile Cutter',
        'description':
            'Professional tile cutter for renovation projects.',
        'categoryId': 'tools',
        'pricePerDay': 18.0,
        'lat': 51.1946,
        'lng': 4.3908,
        'locationLabel': 'Abdijstraat, 2020 Antwerpen',
        'imageUrl':
            'https://images.unsplash.com/photo-1581094271901-8022df4466f9?w=800',
      },
      {
        'title': 'Epson HD Projector',
        'description':
            '1080p projector for home cinema or presentations.',
        'categoryId': 'electronics',
        'pricePerDay': 20.0,
        'lat': 51.2188,
        'lng': 4.3835,
        'locationLabel': 'Sint-Annastrand, 2050 Antwerpen',
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
