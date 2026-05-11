import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/review.dart';

/// Reads and writes reviews scoped to one item.
class ReviewRepository {
  ReviewRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _db.collection('reviews');

  /// Live newest-first stream of reviews for [itemId].
  Stream<List<Review>> watchByItem(String itemId) => _reviews
      .where('itemId', isEqualTo: itemId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Review.fromDoc).toList());

  /// Persists a new review.
  Future<void> addReview(Review review) => _reviews.add(review.toMap());
}
