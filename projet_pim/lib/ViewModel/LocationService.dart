import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../Model/carnet.dart';

class LocationService {
  // Mock location stream
  static Stream<Position> get liveLocation async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      yield Position(
        latitude: 36.8065,
        longitude: 10.1815,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,  // Added required parameter
        headingAccuracy: 0,   // Added required parameter
      );
    }
  }

  // Mock distance calculation
  static double getDistanceBetween(Place a, Place b) {
    if (a.coordinates == null || b.coordinates == null) return 0;
    final dx = a.coordinates!.latitude - b.coordinates!.latitude;
    final dy = a.coordinates!.longitude - b.coordinates!.longitude;
    return sqrt(dx * dx + dy * dy) * 111320; // Convert to meters
  }

  // Mock permission check (always granted in mock mode)
  static Future<bool> hasLocationPermission() async => true;
}