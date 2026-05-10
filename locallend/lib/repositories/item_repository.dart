import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/item.dart';

class ItemRepository {
  ItemRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _items => _db.collection('items');

  Stream<List<Item>> watchAll() => _items
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Item.fromDoc).toList());

  Stream<List<Item>> watchByOwner(String ownerId) => _items
      .where('ownerId', isEqualTo: ownerId)
      .snapshots()
      .map((s) => s.docs.map(Item.fromDoc).toList());

  Stream<Item?> watchItem(String id) => _items
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Item.fromDoc(d) : null);

  Future<Item?> fetchItem(String id) async {
    final doc = await _items.doc(id).get();
    return doc.exists ? Item.fromDoc(doc) : null;
  }

  Stream<List<Item>> getAllItems() {
    return _items
        .where('available', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Item.fromDoc(d)).toList());
  }

  Future<String> addItem(Item item) async {
    final ref = await _items.add(item.toMap());
    return ref.id;
  }

  Future<void> updateAvailability(String id, bool available) =>
      _items.doc(id).update({'available': available});

  Future<void> updateImage(String id, String url) =>
      _items.doc(id).update({'imageUrl': url});

  Future<void> deleteItem(String id) => _items.doc(id).delete();
}
