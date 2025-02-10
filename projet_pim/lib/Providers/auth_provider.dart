import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:projet_pim/Model/user_model.dart';
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

  /// Handles forgot password functionality
Future<void> forgotPassword(String email) async {
  try {
    final message = await _authService.forgotPassword(email);
    debugPrint('Forgot Password Success: $message');
  } catch (e) {
    debugPrint('Error in forgotPassword: $e');
    rethrow;
  }
}


  /// Handles password 
  /// 
  ///  functionality
  Future<void> resetPassword(String email, String otp, String newPassword) async {
    try {
      await _authService.resetPasswordWithOtp(email, otp, newPassword);
    } catch (e) {
      rethrow;
    }
  }

  /// Handles user logout
  void logout() async {
    _user = null;
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  /// Verifies the OTP for email verification
  Future<void> verifyOtp(String email, String otp) async {
    try {
      await _authService.verifyOtp(email, otp);
    } catch (e) {
      rethrow;
    }
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
}
