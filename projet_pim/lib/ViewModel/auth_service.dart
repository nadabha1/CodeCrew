import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl =
      'http://localhost:3000/auth'; // Replace with your backend URL

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Invalid credentials');
    }
  }

  Future<String> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body)['message'] ?? 'OTP sent successfully';
    } else {
      final errorResponse = jsonDecode(response.body);
      final errorMessage = errorResponse['error'] ?? 'Failed to send OTP';
      throw Exception(errorMessage);
    }
  }

  Future<String> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['message'];
    } else {
      throw Exception('Invalid or expired OTP');
    }
  }

  Future<String> resetPasswordWithOtp(
      String email, String otp, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password-with-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'password': newPassword,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['message'];
    } else {
      throw Exception('Failed to reset password: ${response.body}');
    }
  }
}
