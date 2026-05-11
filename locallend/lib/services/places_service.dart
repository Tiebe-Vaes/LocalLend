// Conditional export: native uses REST, web uses the Google Maps JS SDK.
export 'places_types.dart';
export 'places_service_io.dart'
    if (dart.library.js_interop) 'places_service_web.dart';
