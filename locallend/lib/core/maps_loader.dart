// Conditional export: web uses the real loader; mobile uses the no-op stub.
export 'maps_loader_stub.dart'
    if (dart.library.html) 'maps_loader_web.dart';
