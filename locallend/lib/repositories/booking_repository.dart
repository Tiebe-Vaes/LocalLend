import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils.dart';
import '../models/booking.dart';

/// CRUD + live streams for the `bookings` collection.
class BookingRepository {
  BookingRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');

  /// Live stream of all bookings made by [renterId].
  Stream<List<Booking>> watchByRenter(String renterId) => _bookings
      .where('renterId', isEqualTo: renterId)
      .snapshots()
      .map((s) => s.docs.map(Booking.fromDoc).toList());

  /// Live stream of every booking on items owned by [ownerId].
  Stream<List<Booking>> watchByOwner(String ownerId) => _bookings
      .where('ownerId', isEqualTo: ownerId)
      .snapshots()
      .map((s) => s.docs.map(Booking.fromDoc).toList());

  /// Live stream of every booking attached to [itemId].
  Stream<List<Booking>> watchByItem(String itemId) => _bookings
      .where('itemId', isEqualTo: itemId)
      .snapshots()
      .map((s) => s.docs.map(Booking.fromDoc).toList());

  /// Transactionally creates a booking, rejecting any day that is already
  /// booked on the same item — prevents two renters claiming the same day.
  Future<Booking> createBooking(Booking booking) async {
    return _db.runTransaction<Booking>((tx) async {
      final query = await _bookings
          .where('itemId', isEqualTo: booking.itemId)
          .where('dayKeys', arrayContainsAny: booking.dayKeys)
          .get();
      final blocking = query.docs.where(
        (d) => (d.data()['status'] ?? '') != BookingStatus.cancelled.name,
      );
      if (blocking.isNotEmpty) {
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

  /// Returns the day-keys taken by *non-cancelled* bookings for [itemId].
  Future<Set<String>> bookedDayKeysForItem(String itemId) async {
    final snap = await _bookings.where('itemId', isEqualTo: itemId).get();
    final result = <String>{};
    for (final d in snap.docs) {
      final b = Booking.fromDoc(d);
      if (b.status == BookingStatus.cancelled) continue;
      result.addAll(b.dayKeys);
    }
    return result;
  }

  /// Marks a booking as cancelled (kept in history, hidden from active rentals).
  Future<void> cancel(String bookingId) =>
      _bookings.doc(bookingId).update({'status': BookingStatus.cancelled.name});

  /// Convenience pass-through to [dayKey] for callers that only see the repo.
  String dayKeyFor(DateTime d) => dayKey(d);
}
