// Firebase Storage is unavailable in this region.
// Images are optional; items without images use a category icon placeholder.
// To enable images, use an external image hosting service or enable Storage
// in a different region and update this implementation.

class StorageRepository {
  StorageRepository();

  /// Image uploads are disabled. Always returns null.
  /// Users can still add items; they'll display with category-based placeholders.
  Future<String?> uploadItemImage(dynamic file) async {
    return null; // No-op: images not supported in this region
  }
}
