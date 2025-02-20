import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FacebookAuthService {
  Future<Map<String, dynamic>?> signInWithFacebook() async {
    try {
      // Start Facebook Login
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        // ✅ Get the Facebook Access Token
        final AccessToken? accessToken = result.accessToken;

        if (accessToken != null) {
          print("✅ Facebook Login Successful!");
          print("🔑 Token: ${accessToken.tokenString}");

          // 🔥 Send Token to Backend for Verification
          final response = await http.post(
            Uri.parse("http://10.0.2.2:3000/auth/facebook"), // Your NestJS API Endpoint
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"access_token": accessToken.tokenString}),
          );

          if (response.statusCode == 200|| response.statusCode ==201) {
            final userData = jsonDecode(response.body);
            print("✅ User Data: $userData");
            return userData; // 🔥 Fix: Return Map instead of UserCredential
          } else {
            print("❌ Error Authenticating with Backend: ${response.body}");
            return null;
          }
        }
      } else {
        print("❌ Facebook Login Failed: ${result.message}");
        return null;
      }
    } catch (e) {
      print("❌ Error during Facebook Login: $e");
      return null;
    }
  }

  Future<void> logout() async {
    await FacebookAuth.instance.logOut();
    print("✅ User logged out");
  }
}
