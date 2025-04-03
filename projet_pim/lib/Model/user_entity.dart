import 'package:latlong2/latlong.dart';

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

  // Factory method to create a User instance from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    LatLng parsedLocation = LatLng(0, 0); // Valeur par défaut

    if (json['location'] != null) {
      if (json['location'] is String) {
        try {
          List<String> coordinates = json['location'].split(',');
          parsedLocation = LatLng(
            double.parse(coordinates[0].trim()), // Latitude
            double.parse(coordinates[1].trim()), // Longitude
          );
        } catch (e) {
          print("❌ Erreur parsing location: $e");
        }
      } else if (json['location'] is Map<String, dynamic>) {
        parsedLocation = LatLng(
          (json['location']['latitude'] ?? 0).toDouble(),
          (json['location']['longitude'] ?? 0).toDouble(),
        );
      }
    }

    return User(
      id: json['_id'] as String,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? 'user',
      resetPasswordOtp: json['resetPasswordOtp'],
      resetPasswordOtpExpires: json['resetPasswordOtpExpires'] != null
          ? DateTime.parse(json['resetPasswordOtpExpires'])
          : null,
      job: json['job'] as String? ?? '',
      location: parsedLocation, // ✅ Gère string ou Map
      bio: json['bio'] as String? ?? '',
      profileImage: json['profileImage'] as String?,
      likes: json['likes'] as int? ?? 0,
      coins: json['coins'] as int? ?? 0,
      favorites: json['favorites'] as int? ?? 0,
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
}
