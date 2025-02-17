import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_pim/View/home_screen.dart';
import 'package:projet_pim/View/main_screen.dart';
import 'package:projet_pim/View/user_profile.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginViewModel extends ChangeNotifier {
  String _email = "";
  String _password = "";
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  String? _id;

  // Getters
  String get email => _email;
  String get password => _password;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  String? get id => _id;

  // Setters
  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }

  /// Login method to authenticate the user
  Future<void> login(BuildContext context) async {
    _setLoading(true);
    _errorMessage = null; // Reset error message before login
    notifyListeners();

    const String apiUrl =
        "http://localhost:3000/auth/login"; // Adjust as needed

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": _email, "password": _password}),
      );

      // Log API response for debugging
      debugPrint("Response Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey("accessToken") && data["accessToken"] != null) {
          _token = data["accessToken"];
          _id = data["id"];

          await _saveToken(_token!);
          _errorMessage = null; // Clear error if login is successful
          await Future.delayed(const Duration(seconds: 2)); // Simulate API call

          // Navigate to profile screen after login
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(
                userId: _id!,
                token: _token!,
              ),
            ),
          );
        } else {
          _errorMessage = "Login failed: Missing token!";
        }
      } else {
        _errorMessage = _parseError(response.body);
      }
    } catch (e) {
      debugPrint("Error: $e");
      _errorMessage = "Error connecting to server. Please try again later.";
    }

    _setLoading(false);
    notifyListeners();
  }

  /// Save token to shared preferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("jwt_token", token);
  }

  /// Load token from shared preferences
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("jwt_token");
    notifyListeners();
  }

  /// Logout and clear token
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("jwt_token");
    _token = null;
    notifyListeners();
  }

  /// Helper to toggle the loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Parse error message from API response
  String _parseError(String responseBody) {
    try {
      final Map<String, dynamic> errorData = jsonDecode(responseBody);
      return errorData["message"] ?? "An unknown error occurred.";
    } catch (e) {
      debugPrint("Error parsing error message: $e");
      return "An error occurred. Please try again.";
    }
  }
}
