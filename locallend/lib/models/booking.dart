import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils.dart';

enum BookingStatus { upcoming, active, past, cancelled }

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

  List<String> get dayKeys => days.map(dayKey).toList();

  DateTime get firstDay =>
      days.reduce((a, b) => a.isBefore(b) ? a : b);
  DateTime get lastDay =>
      days.reduce((a, b) => a.isAfter(b) ? a : b);

  BookingStatus computeStatus(DateTime now) {
    final today = dayOnly(now);
    if (status == BookingStatus.cancelled) return BookingStatus.cancelled;
    if (today.isAfter(dayOnly(lastDay))) return BookingStatus.past;
    final anyToday = days.any((d) => dayOnly(d) == today);
    if (anyToday) return BookingStatus.active;
    return BookingStatus.upcoming;
  }

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
