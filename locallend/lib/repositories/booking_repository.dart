import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils.dart';
import '../models/booking.dart';

class BookingRepository {
  BookingRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');

  Stream<List<Booking>> watchByRenter(String renterId) => _bookings
      .where('renterId', isEqualTo: renterId)
      .snapshots()
      .map((s) => s.docs.map(Booking.fromDoc).toList());

  Stream<List<Booking>> watchByOwner(String ownerId) => _bookings
      .where('ownerId', isEqualTo: ownerId)
      .snapshots()
      .map((s) => s.docs.map(Booking.fromDoc).toList());

  Stream<List<Booking>> watchByItem(String itemId) => _bookings
      .where('itemId', isEqualTo: itemId)
      .snapshots()
      .map((s) => s.docs.map(Booking.fromDoc).toList());

  /// Creates a booking, rejecting any day that is already booked.
  Future<Booking> createBooking(Booking booking) async {
    return _db.runTransaction<Booking>((tx) async {
      final query = await _bookings
          .where('itemId', isEqualTo: booking.itemId)
          .where('dayKeys', arrayContainsAny: booking.dayKeys)
          .get();
      if (query.docs.isNotEmpty) {
        throw StateError('One or more days already booked for this item.');
      }
      final ref = _bookings.doc();
      tx.set(ref, booking.toMap());
      return Booking(
        id: ref.id,
        itemId: booking.itemId,
        itemTitle: booking.itemTitle,
        ownerId: booking.ownerId,
        renterId: booking.renterId,
        renterName: booking.renterName,
        days: booking.days,
        totalPrice: booking.totalPrice,
        status: booking.status,
        createdAt: booking.createdAt,
      );
    });
  }

  Future<Set<String>> bookedDayKeysForItem(String itemId) async {
    final snap = await _bookings.where('itemId', isEqualTo: itemId).get();
    final result = <String>{};
    for (final d in snap.docs) {
      final b = Booking.fromDoc(d);
      result.addAll(b.dayKeys);
    }
    return result;
  }

  Future<void> cancel(String bookingId) =>
      _bookings.doc(bookingId).update({'status': BookingStatus.cancelled.name});

  String dayKeyFor(DateTime d) => dayKey(d);
}
