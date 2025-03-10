import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:projet_pim/Model/user_model.dart';
import 'package:projet_pim/View/reset_password_screen.dart';
import 'package:projet_pim/ViewModel/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Providers/UserPreferences.dart';
import 'package:http/http.dart' as http;

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  String? _userId; // Private field

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  String? get userId => _userId; // Public getter for _userId

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isOtpVerified = false;
  bool get isOtpVerified => _isOtpVerified;

  final String baseUrl = "http://localhost:3000"; // Updated base URL

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> login(String email, String password) async {
    try {
      final data = await _authService.login(email, password);
      _token = data['accessToken'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      _user = User.fromJson(data['user']);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifyOtp(BuildContext context, String email, String otp) async {
    if (otp.isEmpty) {
      _showMessage(context, "Please enter the OTP");
      return;
    }
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );
      _setLoading(false);
      if (response.statusCode == 200 || response.statusCode == 201) {
        _isOtpVerified = true;
        notifyListeners();
        _showMessage(context, "OTP verified successfully");
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Error verifying OTP';
        throw Exception(error);
      }
    } catch (e) {
      _setLoading(false);
      _showMessage(context, "Error verifying OTP: ${e.toString()}");
    }
  }

  Future<void> resetPassword(BuildContext context, String email, String otp, String password) async {
    if (password.isEmpty) {
      _showMessage(context, "Please enter a new password");
      return;
    }
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password-with-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp, 'password': password}),
      );
      _setLoading(false);
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage(context, "Password reset successful");
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Error resetting password';
        throw Exception(error);
      }
    } catch (e) {
      _setLoading(false);
      _showMessage(context, "Error resetting password: ${e.toString()}");
    }
  }

  void logout() async {
    _user = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  Future<bool> registerUser(String name, String email, String password, UserPreferences preferences) async {
    _isLoading = true;
    notifyListeners();

    const String apiUrl = "http://localhost:3000/users/register";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user": {"name": name, "email": email, "password": password},
          "preferences": preferences.toJson(),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _userId = userData['_id'].toString(); // Set _userId
        debugPrint("User ID after registration: $_userId");
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

  Future<bool> addUserPreferences(UserPreferences preferences) async {
    if (_userId == null) {
      debugPrint("User ID not set. Cannot add preferences.");
      return false;
    }

    String apiUrl = "$baseUrl/users/$_userId/preferences"; // Updated endpoint

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(preferences.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint("Preferences added successfully");
        return true;
      } else {
        debugPrint("Failed to add preferences: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error adding preferences: $e");
      return false;
    }
  }

  Future<UserPreferences?> getUserPreferences(String userId) async {
    String apiUrl = "$baseUrl/users/$userId/preferences"; // Updated endpoint

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserPreferences.fromJson(data);
      } else {
        debugPrint("Failed to fetch preferences: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching preferences: $e");
      return null;
    }
  }

  Future<bool> updateUserPreferences(String userId, UserPreferences preferences) async {
    String apiUrl = "$baseUrl/users/$userId/preferences"; // Updated endpoint

    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(preferences.toJson()),
      );

      if (response.statusCode == 200) {
        debugPrint("Preferences updated successfully");
        return true;
      } else {
        debugPrint("Failed to update preferences: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error updating preferences: $e");
      return false;
    }
  }

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
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      _isLoading = false;
      notifyListeners();
      if (response.statusCode == 201 || response.statusCode == 200) {
        final message = jsonDecode(response.body)['message'] ?? 'OTP sent successfully';
        _showMessage(context, message);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ResetPasswordScreen(email: email)),
        );
      } else {
        final errorResponse = jsonDecode(response.body);
        final errorMessage = errorResponse['error'] ?? 'Failed to send OTP. Please try again.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      _showMessage(context, 'Error: ${e.toString()}');
    }
  }

  Future<bool> checkUserVerification(String email) async {
    final String apiUrl = "$baseUrl/users/checkverification";

    try {
      debugPrint("🔄 Checking verification status for: $email");
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
      debugPrint("📩 Backend response status: ${response.statusCode}");
      debugPrint("📩 Response body: ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        bool isVerified = data['isVerified'] ?? false;
        debugPrint("✅ Verification status received: $isVerified");
        return isVerified;
      } else {
        debugPrint("⚠️ Unexpected HTTP status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error checking verification: $e");
    }
    return false;
  }
}