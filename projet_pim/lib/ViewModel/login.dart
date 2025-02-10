import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginViewModel extends ChangeNotifier {
  String _email = "";
  String _password = "";
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;

  String get email => _email;
  String get password => _password;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;

  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }

 Future<void> login() async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  const String apiUrl = "http://10.0.2.2:3000/auth/login"; // Change if needed

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": _email, "password": _password}),
    );

    // Debugging: Print API response
    debugPrint("Response Code: ${response.statusCode}");
    debugPrint("Response Body: ${response.body}");

    if ( response.statusCode == 201) { // ✅ Adjusted status check
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey("accessToken") && data["accessToken"] != null) { // ✅ Null check
        _token = data["accessToken"];
        await _saveToken(_token!);
        _errorMessage = "Success!";
      } else {
        _errorMessage = "Login failed: No token received!";
      }
    } else {
      _errorMessage = "Invalid email or password!";
    }
  } catch (e) {
    debugPrint("Error: $e");
    _errorMessage = "Error connecting to server!";
  }

  _isLoading = false;
  notifyListeners();
}


  Future<void> _saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("jwt_token", token);
  }

  Future<void> loadToken() async {
    SharedPreferences prefs =await SharedPreferences.getInstance();
    _token = prefs.getString("jwt_token");
    notifyListeners();
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("jwt_token");
    _token = null;
    notifyListeners();
  }
}
