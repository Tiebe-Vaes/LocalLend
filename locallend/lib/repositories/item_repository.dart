import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/item.dart';

/// CRUD + live streams for the `items` collection.
class ItemRepository {
  ItemRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _items => _db.collection('items');

  /// Live newest-first stream of every item in the marketplace.
  Stream<List<Item>> watchAll() => _items
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Item.fromDoc).toList());

  /// Live stream of items owned by [ownerId].
  Stream<List<Item>> watchByOwner(String ownerId) => _items
      .where('ownerId', isEqualTo: ownerId)
      .snapshots()
      .map((s) => s.docs.map(Item.fromDoc).toList());

  /// Live stream of a single item; emits null after deletion.
  Stream<Item?> watchItem(String id) => _items
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Item.fromDoc(d) : null);

  /// One-shot read of a single item.
  Future<Item?> fetchItem(String id) async {
    final doc = await _items.doc(id).get();
    return doc.exists ? Item.fromDoc(doc) : null;
  }

  /// Persists a new item and returns its generated id.
  Future<String> addItem(Item item) async {
    final ref = await _items.add(item.toMap());
    return ref.id;
  }

  /// Overwrites an existing item with the given snapshot.
  Future<void> updateItem(Item item) =>
      _items.doc(item.id).set(item.toMap(), SetOptions(merge: true));

  /// Flips the manual on/off availability flag for an item.
  Future<void> updateAvailability(String id, bool available) =>
      _items.doc(id).update({'available': available});

  /// Updates the network image URL for an item.
  Future<void> updateImage(String id, String url) =>
      _items.doc(id).update({'imageUrl': url});

  /// Updates the inline base64 image for an item (pass null to clear).
  Future<void> updateImageBase64(String id, String? base64) =>
      _items.doc(id).update({'imageBase64': base64});

  /// Permanently removes an item.
  Future<void> deleteItem(String id) => _items.doc(id).delete();
}
