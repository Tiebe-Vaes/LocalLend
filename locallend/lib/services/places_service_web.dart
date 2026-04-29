import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'places_types.dart';

@JS('google.maps.places.AutocompleteService')
extension type _AutocompleteService._(JSObject _) implements JSObject {
  external _AutocompleteService();
  external void getPlacePredictions(JSObject request, JSFunction callback);
}

@JS('google.maps.places.PlacesService')
extension type _PlacesService._(JSObject _) implements JSObject {
  external _PlacesService(JSObject attrContainer);
  external void getDetails(JSObject request, JSFunction callback);
}

@JS('google.maps.Geocoder')
extension type _Geocoder._(JSObject _) implements JSObject {
  external _Geocoder();
  external void geocode(JSObject request, JSFunction callback);
}

class PlacesService {
  _AutocompleteService? _auto;
  _PlacesService? _details;
  _Geocoder? _geocoder;

  _AutocompleteService _autoSvc() => _auto ??= _AutocompleteService();

  _PlacesService _detailsSvc() =>
      _details ??= _PlacesService(web.HTMLDivElement() as JSObject);

  _Geocoder _geocoderSvc() => _geocoder ??= _Geocoder();

  Future<List<PlaceSuggestion>> autocomplete(String input,
      {String? sessionToken}) async {
    if (input.trim().length < 2) return const [];
    final completer = Completer<List<PlaceSuggestion>>();
    final req = <String, dynamic>{'input': input}.jsify() as JSObject;

    final cb = ((JSAny? results, JSAny? status) {
      if (results == null) {
        if (!completer.isCompleted) completer.complete(const []);
        return;
      }
      final arr = results as JSArray;
      final list = <PlaceSuggestion>[];
      final length = (arr as JSObject).getProperty('length'.toJS) as JSNumber;
      final n = length.toDartInt;
      for (var i = 0; i < n; i++) {
        final item =
            (arr as JSObject).getProperty(i.toString().toJS) as JSObject;
        final placeId = item.getProperty('place_id'.toJS) as JSString?;
        final desc = item.getProperty('description'.toJS) as JSString?;
        if (placeId != null && desc != null) {
          list.add(PlaceSuggestion(
            placeId: placeId.toDart,
            description: desc.toDart,
          ));
        }
      }
      if (!completer.isCompleted) completer.complete(list);
    }).toJS;

    _autoSvc().getPlacePredictions(req, cb);
    return completer.future;
  }

  Future<PlaceDetails?> details(String placeId, {String? sessionToken}) async {
    final completer = Completer<PlaceDetails?>();
    final req = <String, dynamic>{
      'placeId': placeId,
      'fields': ['geometry.location', 'formatted_address'],
    }.jsify() as JSObject;

    final cb = ((JSAny? place, JSAny? status) {
      if (place == null) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final p = place as JSObject;
      final geom = p.getProperty('geometry'.toJS) as JSObject?;
      final loc = geom?.getProperty('location'.toJS) as JSObject?;
      if (loc == null) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final latFn = loc.getProperty('lat'.toJS) as JSFunction;
      final lngFn = loc.getProperty('lng'.toJS) as JSFunction;
      final lat = (latFn.callAsFunction(loc) as JSNumber).toDartDouble;
      final lng = (lngFn.callAsFunction(loc) as JSNumber).toDartDouble;
      final addr = p.getProperty('formatted_address'.toJS) as JSString?;
      if (!completer.isCompleted) {
        completer.complete(PlaceDetails(
          lat: lat,
          lng: lng,
          formattedAddress: addr?.toDart ?? '',
        ));
      }
    }).toJS;

    _detailsSvc().getDetails(req, cb);
    return completer.future;
  }

  Future<String?> reverseGeocode(double lat, double lng) async {
    final completer = Completer<String?>();
    final req = <String, dynamic>{
      'location': {'lat': lat, 'lng': lng},
    }.jsify() as JSObject;

    final cb = ((JSAny? results, JSAny? status) {
      if (results == null) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final arr = results as JSObject;
      final length = arr.getProperty('length'.toJS) as JSNumber;
      if (length.toDartInt == 0) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final first = arr.getProperty('0'.toJS) as JSObject;
      final addr = first.getProperty('formatted_address'.toJS) as JSString?;
      if (!completer.isCompleted) completer.complete(addr?.toDart);
    }).toJS;

    _geocoderSvc().geocode(req, cb);
    return completer.future;
  }
}
