import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';
import 'dart:collection';

class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;

  GeocodingService._internal();

  final Map<String, String> _cache = HashMap(); // Cache for geocoding results

  Future<String> getAddressFromLatLng(double lat, double lng,
      {int retries = 3}) async {
    final key = "$lat,$lng";
    if (_cache.containsKey(key)) {
      print("📦 Returning cached address for $key");
      return _cache[key]!;
    }

    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        print(
            "🌍 Fetching address for coordinates: $lat, $lng (Attempt ${attempt + 1})");
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          String address =
              "${place.street}, ${place.locality}, ${place.country}";
          _cache[key] = address; // Cache the result
          print("✅ Geocoding successful: $address");
          return address;
        }
        print("❌ Geocoding returned no results.");
        return "Unknown Location";
      } on PlatformException catch (e) {
        if (e.code == 'IO_ERROR') {
          print("❌ Geocoding failed: I/O error occurred. Retrying...");
          await Future.delayed(Duration(seconds: 1)); // Wait before retrying
          continue;
        }
        print("❌ Geocoding failed: ${e.message}");
        return "Unknown Location";
      } catch (e) {
        print("❌ Unexpected error during geocoding: $e");
        return "Unknown Location";
      }
    }
    print("❌ Geocoding failed after $retries attempts.");
    return "Unknown Location (Retries Exhausted)";
  }

  Future<String> getAddressFromStringCoords(String coords,
      {int retries = 3}) async {
    try {
      final parts = coords.split(',');
      if (parts.length != 2) return "Invalid Coordinates";

      final lat = double.parse(parts[0]);
      final lng = double.parse(parts[1]);
      return await getAddressFromLatLng(lat, lng, retries: retries);
    } catch (e) {
      print("❌ Error parsing coordinates: $e");
      return "Unknown Location";
    }
  }
}
