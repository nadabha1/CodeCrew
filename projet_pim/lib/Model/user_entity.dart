class User {
  final String name;
  final String email;
  final String password;
  final String role;
  final String? resetPasswordOtp;
  final DateTime? resetPasswordOtpExpires;

  User({
    required this.name,
    required this.email,
    required this.password,
    this.role = 'user',
    this.resetPasswordOtp,
    this.resetPasswordOtpExpires,
  });

  // Factory method to create a User instance from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? 'user',
      resetPasswordOtp: json['resetPasswordOtp'],
      resetPasswordOtpExpires: json['resetPasswordOtpExpires'] != null
          ? DateTime.parse(json['resetPasswordOtpExpires'])
          : null,
    );
  }

  // Method to convert a User instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'resetPasswordOtp': resetPasswordOtp,
      'resetPasswordOtpExpires': resetPasswordOtpExpires?.toIso8601String(),
    };
  }
}
