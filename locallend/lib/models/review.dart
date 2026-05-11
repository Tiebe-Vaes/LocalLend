import 'package:cloud_firestore/cloud_firestore.dart';

/// A renter's star rating and text comment attached to one item.
class Review {
  final String id;
  final String itemId;
  final String userId;
  final String userName;
  final int rating;
  final String text;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.text,
    required this.createdAt,
  });

  /// Serialises the review to a Firestore-compatible map.
  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Hydrates a [Review] from a Firestore document.
  factory Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Review(
      id: doc.id,
      itemId: (d['itemId'] ?? '') as String,
      userId: (d['userId'] ?? '') as String,
      userName: (d['userName'] ?? '') as String,
      rating: (d['rating'] as num?)?.toInt() ?? 0,
      text: (d['text'] ?? '') as String,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
