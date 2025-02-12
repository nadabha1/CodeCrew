import 'package:flutter/material.dart';
import 'package:projet_pim/Providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final forgotPasswordProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FC),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Forgot Password",
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 10),

            const Text(
              "Enter your email to receive a password reset OTP",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // Send OTP Button
            ElevatedButton(
              onPressed: forgotPasswordProvider.isLoading
                  ? null
                  : () => forgotPasswordProvider.sendOtp(context, _emailController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: forgotPasswordProvider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Center(child: Text('Send OTP')),
            ),
            const SizedBox(height: 10),

            // Cancel Button
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
