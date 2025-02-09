import 'package:flutter/material.dart';
import 'package:projet_pim/View/reset_password_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    void _sendOtp() async {
  try {
    await authProvider.forgotPassword(_emailController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('OTP sent to your email')),
    );

    // Navigate to Reset Password Screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResetPasswordScreen(email: _emailController.text),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}


    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FC), // Light purple background
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              "Forgot Password",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),

            // Subtitle
            Text(
              "Enter your email to receive a password reset OTP",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 40),

            // Email Input
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),

            // Send OTP Button
            ElevatedButton(
              onPressed: _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A), // Purple button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: 16,
                ),
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Center(child: Text('Send OTP')),
            ),
            SizedBox(height: 10),

            // Cancel Button
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
