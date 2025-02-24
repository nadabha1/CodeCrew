import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:projet_pim/View/main_screen.dart';

class LoginViewModel extends ChangeNotifier {
  String _email = "";
  String _password = "";
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  String? _userId;

  // Getters
  String get email => _email;
  String get password => _password;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  String? get userId => _userId;

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
    _errorMessage = null;
    notifyListeners();

    const String apiUrl =
        "http://localhost:3000/auth/login"; // Localhost for emulator

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": _email, "password": _password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey("accessToken") && data["accessToken"] != null) {
          _token = data["accessToken"];
          _userId = data["id"];

          await _saveSession(_token!, _userId!); // ✅ Save session

          _errorMessage = null;
          notifyListeners();

          // Navigate to Home Page after login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(),
            ),
          );
        } else {
          _errorMessage = "Login failed: Token missing!";
        }
      } else {
        _errorMessage = _parseError(response.body);
      }
    } catch (e) {
      _errorMessage = "Connection error. Please try again.";
    }

    _setLoading(false);
    notifyListeners();
  }

  /// ✅ Save user session (ID & Token)
  Future<void> _saveSession(String token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("jwt_token", token);
    await prefs.setString("user_id", userId);
    print("✅ Session saved: Token=$token, UserID=$userId"); // Debug log
  }

  /// ✅ Load session (Retrieve saved ID & Token)
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("jwt_token");
    _userId = prefs.getString("user_id");
    notifyListeners();
    print("🔄 Session loaded: Token=$_token, UserID=$_userId"); // Debug log
  }

  /// ✅ Logout and clear session
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("jwt_token");
    await prefs.remove("user_id");

    _token = null;
    _userId = null;
    notifyListeners();

    // Navigate back to Login page
    Navigator.pushReplacementNamed(context, "/login");
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _parseError(String responseBody) {
    try {
      final Map<String, dynamic> errorData = jsonDecode(responseBody);
      return errorData["message"] ?? "An unknown error occurred.";
    } catch (e) {
      return "An error occurred. Please try again.";
    }
  }
}
