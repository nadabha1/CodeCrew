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
  final String? profileImage; // Peut être null
  final List<String> followers;
  final List<String> following;
  final int likes;
  final int coins;

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
    required this.followers,
    required this.following,
    required this.likes,
    required this.coins,
  });

  // Factory method to create a User instance from JSON
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
      job: json['job'] as String? ?? '', // Évite les erreurs si null
      location: json['location'] as String? ?? '',
      bio: json['bio'] as String? ?? '',

      profileImage: json['profileImage'] as String?, // Peut être null
      followers: List<String>.from(
          json['followers'] ?? []), // Assure une liste vide si null
      following: List<String>.from(json['following'] ?? []),
      likes: json['likes'] as int? ?? 0, // Si null, met 0
      coins: json['likes'] as int? ?? 0, // Si null, met 0
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
      'location': location,
      'bio': bio,
      'profileImage': profileImage,
      'followers': followers,
      'following': following,
      'likes': likes,
      'coins': coins,
    };
  }
}
