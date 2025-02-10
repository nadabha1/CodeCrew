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

  Future<void> login(String email, String password) async {
    final data = await _authService.login(email, password);
    _token = data['accessToken'];

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('token', _token!);

    _user = User.fromJson(data['user']);
    notifyListeners();
  }

  Future<void> forgotPassword(String email) async {
    await _authService.forgotPassword(email);
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    await _authService.resetPasswordWithOtp(email, otp, newPassword);
  }

  void logout() async {
    _user = null;
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    prefs.remove('token');
    notifyListeners();
  }

  Future<void> verifyOtp(String email, String otp) async {
   await _authService.verifyOtp(email, otp);  }

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<bool> registerUser(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    const String apiUrl = "http://localhost:3000/users/register";

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

      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

}
