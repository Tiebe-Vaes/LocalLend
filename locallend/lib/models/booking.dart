import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils.dart';

/// Stored status of a booking; the live status is derived from the dates.
enum BookingStatus { upcoming, active, past, cancelled }

/// A reservation of one item for a specific set of days by one renter.
class Booking {
  final String id;
  final String itemId;
  final String itemTitle;
  final String ownerId;
  final String renterId;
  final String renterName;
  final List<DateTime> days;
  final double totalPrice;
  final BookingStatus status;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.ownerId,
    required this.renterId,
    required this.renterName,
    required this.days,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  /// All booked days as `YYYY-MM-DD` strings (used for overlap queries).
  List<String> get dayKeys => days.map(dayKey).toList();

  /// Earliest day in the booking.
  DateTime get firstDay =>
      days.reduce((a, b) => a.isBefore(b) ? a : b);
  /// Latest day in the booking.
  DateTime get lastDay =>
      days.reduce((a, b) => a.isAfter(b) ? a : b);

  /// Live status derived from [now]: cancelled stays sticky, otherwise
  /// returns past / active / upcoming based on the booking's days.
  BookingStatus computeStatus(DateTime now) {
    final today = dayOnly(now);
    if (status == BookingStatus.cancelled) return BookingStatus.cancelled;
    if (today.isAfter(dayOnly(lastDay))) return BookingStatus.past;
    final anyToday = days.any((d) => dayOnly(d) == today);
    if (anyToday) return BookingStatus.active;
    return BookingStatus.upcoming;
  }

  /// Serialises the booking to a Firestore-compatible map.
  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'itemTitle': itemTitle,
        'ownerId': ownerId,
        'renterId': renterId,
        'renterName': renterName,
        'dayKeys': dayKeys,
        'days': days.map(Timestamp.fromDate).toList(),
        'totalPrice': totalPrice,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Hydrates a [Booking] from a Firestore document.
  factory Booking.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Booking(
      id: doc.id,
      itemId: (d['itemId'] ?? '') as String,
      itemTitle: (d['itemTitle'] ?? '') as String,
      ownerId: (d['ownerId'] ?? '') as String,
      renterId: (d['renterId'] ?? '') as String,
      renterName: (d['renterName'] ?? '') as String,
      days: ((d['days'] ?? const []) as List)
          .map((t) => (t as Timestamp).toDate())
          .toList(),
      totalPrice: (d['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: BookingStatus.values.firstWhere(
        (s) => s.name == (d['status'] ?? 'upcoming'),
        orElse: () => BookingStatus.upcoming,
      ),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
