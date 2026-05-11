import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Injects the Google Maps JS SDK (with Places library) into the document head.
Future<void> loadGoogleMapsScript(String apiKey) async {
  final completer = Completer<void>();
  final script = web.HTMLScriptElement()
    ..src =
        'https://maps.googleapis.com/maps/api/js?key=$apiKey&libraries=places&loading=async'
    ..async = true;
  script.onload = ((web.Event _) => completer.complete()).toJS;
  script.onerror = ((web.Event _) => completer.complete()).toJS;
  web.document.head!.append(script);
  return completer.future;
}
