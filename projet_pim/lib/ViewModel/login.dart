import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_pim/View/login.dart';
import 'package:projet_pim/View/main_screen.dart';
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

  /// ✅ **Login method to authenticate the user**
  Future<void> login(BuildContext context) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    const String apiUrl = "http://10.0.2.2:3000/auth/login"; // Adjust as needed

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": _email, "password": _password}),
      );

      debugPrint("Response Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey("accessToken") && data["accessToken"] != null) {
          _token = data["accessToken"];
          _id = data["id"];

          await _saveSession(_token!, _id!); // ✅ Save session
          _errorMessage = null;

          await Future.delayed(const Duration(seconds: 2));

          // ✅ Navigate to MainScreen after successful login
          Navigator.pushReplacement(
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

  /// ✅ **Save User Session (Token + ID)**
  Future<void> _saveSession(String token, String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("jwt_token", token);
    await prefs.setString("user_id", id);
    debugPrint("Session Saved: Token=$token, UserID=$id");
  }

  /// ✅ **Load Session on App Start**
  Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("jwt_token");
    _id = prefs.getString("user_id");

    if (_token != null && _id != null) {
      notifyListeners();
      debugPrint("Session Loaded: Token=$_token, UserID=$_id");
      return true; // ✅ Session exists
    } else {
      return false; // ❌ No session found
    }
  }

  /// ✅ **Logout and Clear Session**
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("jwt_token");
    await prefs.remove("user_id");

    _token = null;
    _id = null;
    notifyListeners();
    
    debugPrint("Session Cleared");

    // ✅ Navigate back to Login Screen after logout
      Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => LoginView()),
    (Route<dynamic> route) => false, // Remove all previous routes
  );

  }

  /// ✅ **Helper to toggle the loading state**
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// ✅ **Parse error message from API response**
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
