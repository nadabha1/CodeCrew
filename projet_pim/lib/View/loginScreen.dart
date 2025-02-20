import 'package:flutter/material.dart';
import 'package:projet_pim/ViewModel/facebook_auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FacebookAuthService _facebookAuthService = FacebookAuthService();

  void _loginWithFacebook() async {
    final userData = await _facebookAuthService.signInWithFacebook();

    if (userData != null) {
      print("✅ Facebook Login Success: ${userData['name']}"); // ✅ Fix Here

      // Save user info (if needed) and navigate
      Navigator.pushReplacementNamed(context, '/home', arguments: userData);
    } else {
      print("❌ Facebook Login Failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _loginWithFacebook,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: Text("Login with Facebook", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
