import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:projet_pim/Model/user_model.dart';
import 'package:projet_pim/View/reset_password_screen.dart';
import 'package:projet_pim/ViewModel/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  final AuthService _authService = AuthService();

  bool _isLoading = false;

  bool get isLoading => _isLoading;
 final String baseUrl =
      "http://10.0.2.2:3000/auth"; // Remplace par ton URL de base
//  final String baseUrl ="http://localhost:3000/auth"; // Remplace par ton URL de base

  /// Handles user login
  Future<void> login(String email, String password) async {
    try {
      final data = await _authService.login(email, password);
      _token = data['accessToken'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);

      _user = User.fromJson(data['user']);
      notifyListeners();
    } catch (e) {
      rethrow; // Rethrow the exception to handle it in the UI layer if needed
    }
  }

  /// Handles password
  ///
  ///  functionality

  bool _isOtpVerified = false;
  bool get isOtpVerified => _isOtpVerified;
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> verifyOtp(BuildContext context, String email, String otp) async {
    if (otp.isEmpty) {
      _showMessage(context, "Please enter the OTP");
      return;
    }
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      _setLoading(false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isOtpVerified = true;
        notifyListeners();
        _showMessage(context, "OTP verified successfully");
      } else {
        final error =
            jsonDecode(response.body)['error'] ?? 'Error verifying OTP';
        throw Exception(error);
      }
    } catch (e) {
      _setLoading(false);
      _showMessage(context, "Error verifying OTP: ${e.toString()}");
    }
  }

  Future<void> resetPassword(
      BuildContext context, String email, String otp, String password) async {
    if (password.isEmpty) {
      _showMessage(context, "Please enter a new password");
      return;
    }

    _setLoading(true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password-with-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp, 'password': password}),
      );

      _setLoading(false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage(context, "Password reset successful");

        Navigator.pushReplacementNamed(context, '/login');
      } else {
        final error =
            jsonDecode(response.body)['error'] ?? 'Error resetting password';
        throw Exception(error);
      }
    } catch (e) {
      _setLoading(false);
      _showMessage(context, "Error resetting password: ${e.toString()}");
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Handles user logout
  void logout() async {
    _user = null;
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  /// Registers a new user
  Future<bool> registerUser(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    const String apiUrl = "http://10.0.2.2:3000/users/register";
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        _handleHttpError(response);
        return false;
      }
    } catch (e) {
      debugPrint("Error during registration: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handles HTTP errors and logs the response
  void _handleHttpError(http.Response response) {
    debugPrint("HTTP Error: ${response.statusCode} - ${response.body}");
  }

  Future<void> sendOtp(BuildContext context, String email) async {
    if (email.isEmpty) {
      _showMessage(context, 'Please enter your email');
      return;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      _showMessage(context, 'Please enter a valid email address');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 201 || response.statusCode == 200) {
        final message =
            jsonDecode(response.body)['message'] ?? 'OTP sent successfully';
        _showMessage(context, message);

        // Naviguer vers l'écran de réinitialisation du mot de passe
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(email: email),
          ),
        );
      } else {
        final errorResponse = jsonDecode(response.body);
        final errorMessage =
            errorResponse['error'] ?? 'Failed to send OTP. Please try again.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      _showMessage(context, 'Error: ${e.toString()}');
    }
  }
}
