import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils.dart';

/// Idempotent demo seeder. Writes a few sample items if the `items`
/// collection is empty. Safe to call on every launch.
/// Seeds and reseeds the demo Firestore data.
class SeedService {
  SeedService(this._db);
  final FirebaseFirestore _db;

  static const _flag = 'seeded_v3';

  /// Writes the demo dataset on first launch; no-op once `seeded_v2` is recorded.
  Future<void> seedIfEmpty() async {
    final meta = await _db.collection('meta').doc(_flag).get();
    if (meta.exists) return;

    final batch = _db.batch();
    final col = _db.collection('items');
    final now = Timestamp.fromDate(DateTime.now());
    final defaultAvail = _next30Days();

    // 6 items, one per category. Images verified against unsplash.com to
    // actually show the described product.
    final samples = <Map<String, dynamic>>[
      {
        'title': 'KitchenAid Artisan Stand Mixer',
        'description':
            'Iconic 4.8L tilt-head stand mixer in pink. Includes flat beater, '
                'dough hook and wire whip. Perfect for bread, cakes and large '
                'batches of cookies. Cleaned after every rental.',
        'categoryId': 'kitchen',
        'pricePerDay': 14.0,
        'lat': 51.2078,
        'lng': 4.3923,
        'locationLabel': 'Vlaamsekaai, 2000 Antwerpen',
        'imageUrl':
            'https://images.unsplash.com/photo-1547091267-6b2be403a763?w=800&auto=format&fit=crop',
      },
      {
        'title': 'Petrol Lawn Mower',
        'description':
            'Self-propelled petrol lawn mower with 46 cm cutting width. '
                'Suitable for gardens up to 800 m². Fuel and oil included for '
                'the first tank — bring it back full.',
        'categoryId': 'garden',
        'pricePerDay': 18.0,
        'lat': 51.1703,
        'lng': 4.3906,
        'locationLabel': 'Bist, 2610 Wilrijk',
        'imageUrl':
            'https://images.unsplash.com/photo-1731082686849-d2e0a4d2c70c?w=800&auto=format&fit=crop',
      },
      {
        'title': 'Kärcher K5 Pressure Washer',
        'description':
            '145 bar electric pressure washer. Comes with patio cleaner '
                'attachment, dirtblaster lance and 8 m hose. Great for terraces, '
                'driveways, bikes and garden furniture.',
        'categoryId': 'cleaning',
        'pricePerDay': 15.0,
        'lat': 51.2233,
        'lng': 4.4638,
        'locationLabel': 'Cogelsplein, 2100 Deurne',
        'imageUrl':
            'https://images.unsplash.com/photo-1630868837435-5f7abc85e012?w=800&auto=format&fit=crop',
      },
      {
        'title': 'Makita 18V Cordless Drill Set',
        'description':
            'Brushless 18V combi drill with two LXT batteries, fast charger '
                'and 40-piece bit set in a hard case. Hammer mode included for '
                'masonry. Ideal for furniture assembly and small renovations.',
        'categoryId': 'tools',
        'pricePerDay': 9.0,
        'lat': 51.1998,
        'lng': 4.4320,
        'locationLabel': 'Statiestraat, 2600 Berchem',
        'imageUrl':
            'https://images.unsplash.com/photo-1518709414768-a88981a4515d?w=800&auto=format&fit=crop',
      },
      {
        'title': 'Full HD Home Cinema Projector',
        'description':
            '1080p LED projector with 3500 lumens and HDMI + USB inputs. '
                'Projects up to 200" — great for movie nights, garden cinema '
                'or presentations. HDMI cable and remote included.',
        'categoryId': 'electronics',
        'pricePerDay': 20.0,
        'lat': 51.2188,
        'lng': 4.3835,
        'locationLabel': 'Sint-Annastrand, 2050 Antwerpen',
        'imageUrl':
            'https://images.unsplash.com/photo-1535016120720-40c646be5580?w=800&auto=format&fit=crop',
      },
      {
        'title': '3-Person Camping Tent',
        'description':
            'Lightweight 3-person dome tent with full rainfly and sewn-in '
                'groundsheet. Pitches in under 10 minutes. Comes with footprint, '
                'pegs and carry bag. Used a handful of weekends, no leaks.',
        'categoryId': 'other',
        'pricePerDay': 12.0,
        'lat': 51.2182,
        'lng': 4.4386,
        'locationLabel': 'Turnhoutsebaan, 2140 Borgerhout',
        'imageUrl':
            'https://images.unsplash.com/photo-1562206513-6a81cfc73936?w=800&auto=format&fit=crop',
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
