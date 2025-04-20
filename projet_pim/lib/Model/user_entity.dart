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
  final String location;
  final String bio;
  final String? profileImage;
  final int likes;
  final int coins;
  final int favorites;

  // Simplified location fields (keep only what mock AR needs)
  final LatLng? coordinates;
  final List<String> searchHistory;

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
    this.profileImage,
    required this.likes,
    required this.coins,
    required this.favorites,
    this.coordinates,
    this.searchHistory = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
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
      job: json['job'] ?? '',
      location: json['location'] ?? '',
      bio: json['bio'] ?? '',
      profileImage: json['profileImage'],
      likes: json['likes'] ?? 0,
      coins: json['coins'] ?? 0,
      favorites: json['favorites'] ?? 0,
      coordinates: json['coordinates'] != null
          ? LatLng(json['coordinates']['lat'], json['coordinates']['lng'])
          : null,
      searchHistory: (json['searchHistory'] as List?)?.cast<String>() ?? [],
    );
  }

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
      'location': location,
      'bio': bio,
      'profileImage': profileImage,
      'likes': likes,
      'coins': coins,
      'favorites': favorites,
      'coordinates': coordinates != null
          ? {'lat': coordinates!.latitude, 'lng': coordinates!.longitude}
          : null,
      'searchHistory': searchHistory,
    };
  }
}