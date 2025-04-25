import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:projet_pim/CustomAnnotation.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final String role;
  final String? resetPasswordOtp;
  final DateTime? resetPasswordOtpExpires;
  final String job;
  final LatLng location;
  final String bio;
  final String? profileImage; // Peut être null
  final int likes;
  final int coins;
  final int favorites;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.role = 'user',
    this.resetPasswordOtp,
    this.resetPasswordOtpExpires,
    required this.job,
    required this.location,
    required this.bio,
    this.profileImage, // Optionnel

    required this.likes,
    required this.coins,
    required this.favorites,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    LatLng parsedLocation = LatLng(0, 0); // Default value

    // Handle the location field, whether it's a string or map
    if (json['location'] != null) {
      if (json['location'] is String) {
        try {
          List<String> coordinates = json['location'].split(',');
          if (coordinates.length == 2) {
            parsedLocation = LatLng(
              double.tryParse(coordinates[0].trim()) ?? 0.0, // Latitude
              double.tryParse(coordinates[1].trim()) ?? 0.0, // Longitude
            );
          }
        } catch (e) {
          print("❌ Erreur parsing location: $e");
        }
      } else if (json['location'] is Map<String, dynamic>) {
        parsedLocation = LatLng(
          (json['location']['latitude'] ?? 0.0).toDouble(),
          (json['location']['longitude'] ?? 0.0).toDouble(),
        );
      }
    }

    // Parse the user data, ensuring correct types are assigned
    return User(
      id: json['_id'] as String,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? 'user',
      resetPasswordOtp: json['resetPasswordOtp'],
      resetPasswordOtpExpires: json['resetPasswordOtpExpires'] != null
          ? DateTime.tryParse(json['resetPasswordOtpExpires'])
          : null,
      job: json['job'] as String? ?? '',
      location: parsedLocation, // ✅ Handles string or map format
      bio: json['bio'] as String? ?? '',
      profileImage: json['profileImage'] as String?,
      likes: (json['likes'] is int)
          ? json['likes'] as int
          : 0, // Safely cast to int
      coins: (json['coins'] is int)
          ? json['coins'] as int
          : 0, // Safely cast to int
      favorites: (json['favorites'] is int)
          ? json['favorites'] as int
          : 0, // Safely cast to int
    );
  }

  // Method to convert a User instance to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'resetPasswordOtp': resetPasswordOtp,
      'resetPasswordOtpExpires': resetPasswordOtpExpires?.toIso8601String(),
      'job': job,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'bio': bio,
      'profileImage': profileImage,
      'likes': likes,
      'coins': coins,
      'favorites': favorites,
    };
  }

  /// ✅ Convertir un utilisateur en CustomAnnotation pour la vue AR
  CustomAnnotation toAnnotation() {
    // Convert LatLng to Position
    Position position = Position(
      latitude: location.latitude,
      longitude: location.longitude,
      timestamp: DateTime.now(),
      altitude: 10.0, // Set default values for missing parameters
      accuracy: 5.0, // Set default values for missing parameters
      speed: 0, // Set default values for missing parameters
      heading: 0.0, // Set default heading (can be updated if needed)
      headingAccuracy: 1.0, // Set default heading accuracy
      altitudeAccuracy: 5.0, // Set default altitude accuracy
      speedAccuracy: 1.0, // Set default speed accuracy);
    );
    return CustomAnnotation(
      uid: id,
      position: position, // Pass Position instead of LatLng
      title: name,
      subtitle: job,
      imageUrl: profileImage,
    );
  }
}
