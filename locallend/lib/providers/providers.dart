import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/utils.dart';
import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/item.dart';
import '../models/review.dart';
import '../repositories/auth_repository.dart';
import '../repositories/booking_repository.dart';
import '../repositories/item_repository.dart';
import '../repositories/review_repository.dart';
import '../repositories/storage_repository.dart';
import '../services/places_service.dart';
import '../services/seed_service.dart';

// Central Riverpod registry: Firebase singletons, repositories, streams and
// the browse-filter state.
// Firebase singletons
final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);
final firestoreProvider =
    Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);

// Repositories
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(firebaseAuthProvider), ref.watch(firestoreProvider)),
);
final itemRepositoryProvider =
    Provider<ItemRepository>((ref) => ItemRepository(ref.watch(firestoreProvider)));
final bookingRepositoryProvider = Provider<BookingRepository>(
    (ref) => BookingRepository(ref.watch(firestoreProvider)));
final reviewRepositoryProvider =
    Provider<ReviewRepository>((ref) => ReviewRepository(ref.watch(firestoreProvider)));
final storageRepositoryProvider =
    Provider<StorageRepository>((_) => StorageRepository());
final placesServiceProvider =
    Provider<PlacesService>((_) => PlacesService());
final seedServiceProvider =
    Provider<SeedService>((ref) => SeedService(ref.watch(firestoreProvider)));

// Auth streams
final authStateProvider = StreamProvider<User?>(
    (ref) => ref.watch(authRepositoryProvider).authStateChanges());

final appUserProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchAppUser(user.uid);
});

// Items
final itemsProvider = StreamProvider<List<Item>>(
    (ref) => ref.watch(itemRepositoryProvider).watchAll());

final itemProvider = StreamProvider.family<Item?, String>(
    (ref, id) => ref.watch(itemRepositoryProvider).watchItem(id));

final itemsByOwnerProvider = StreamProvider.family<List<Item>, String>(
    (ref, ownerId) => ref.watch(itemRepositoryProvider).watchByOwner(ownerId));

// Reviews
final reviewsByItemProvider = StreamProvider.family<List<Review>, String>(
    (ref, itemId) => ref.watch(reviewRepositoryProvider).watchByItem(itemId));

// Bookings
final bookingsAsRenterProvider = StreamProvider.family<List<Booking>, String>(
    (ref, uid) => ref.watch(bookingRepositoryProvider).watchByRenter(uid));

final bookingsAsOwnerProvider = StreamProvider.family<List<Booking>, String>(
    (ref, uid) => ref.watch(bookingRepositoryProvider).watchByOwner(uid));

final bookingsByItemProvider = StreamProvider.family<List<Booking>, String>(
    (ref, itemId) => ref.watch(bookingRepositoryProvider).watchByItem(itemId));

// Browse filter state
/// Immutable filter state driving the marketplace browse screen.
class BrowseFilter {
  final String? categoryId;
  final double radiusKm;
  final String query;
  const BrowseFilter({
    this.categoryId,
    this.radiusKm = kDefaultRadiusKm,
    this.query = '',
  });

  /// Returns a new instance with the given fields overridden.
  BrowseFilter copyWith({
    Object? categoryId = const _Sentinel(),
    double? radiusKm,
    String? query,
  }) =>
      BrowseFilter(
        categoryId: categoryId is _Sentinel
            ? this.categoryId
            : categoryId as String?,
        radiusKm: radiusKm ?? this.radiusKm,
        query: query ?? this.query,
      );
}

class _Sentinel {
  const _Sentinel();
}

/// Mutable controller for [BrowseFilter] exposed via [browseFilterProvider].
class BrowseFilterNotifier extends StateNotifier<BrowseFilter> {
  BrowseFilterNotifier() : super(const BrowseFilter());
  /// Sets the active category (null = all categories).
  void setCategory(String? id) => state = state.copyWith(categoryId: id);
  /// Sets the search radius in kilometres.
  void setRadius(double km) => state = state.copyWith(radiusKm: km);
  /// Sets the free-text search query.
  void setQuery(String q) => state = state.copyWith(query: q);
}

final browseFilterProvider =
    StateNotifierProvider<BrowseFilterNotifier, BrowseFilter>(
        (_) => BrowseFilterNotifier());

/// Derived list: applies category/query/radius filters to the items stream.
final filteredItemsProvider = Provider<AsyncValue<List<Item>>>((ref) {
  final asyncItems = ref.watch(itemsProvider);
  final filter = ref.watch(browseFilterProvider);
  final user = ref.watch(appUserProvider).value;

  return asyncItems.whenData((items) {
    final q = filter.query.trim().toLowerCase();
    return items.where((i) {
      if (!i.available) return false;
      if (filter.categoryId != null && i.categoryId != filter.categoryId) {
        return false;
      }
      if (q.isNotEmpty && !i.title.toLowerCase().contains(q)) return false;
      if (user?.lat != null && user?.lng != null) {
        final d = haversineKm(user!.lat!, user.lng!, i.lat, i.lng);
        if (d > filter.radiusKm) return false;
      }
      return true;
    }).toList();
  });
});
