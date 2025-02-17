import 'package:flutter/material.dart';
import 'package:projet_pim/Providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ResetPasswordScreen extends StatelessWidget {
  final String email;
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  ResetPasswordScreen({required this.email});

  @override
  Widget build(BuildContext context) {
    final resetPasswordProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FC),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  resetPasswordProvider.isOtpVerified ? "Set New Password" : "Verify OTP",
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),


                // Subtitle
                Text(
                  resetPasswordProvider.isOtpVerified
                      ? "Enter your new password below"
                      : "Enter the OTP sent to your email",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 40),

                // OTP Input
                if (!resetPasswordProvider.isOtpVerified)
                  TextField(
                    controller: _otpController,
                    decoration: InputDecoration(
                      labelText: 'OTP',
                      labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                if (!resetPasswordProvider.isOtpVerified) const SizedBox(height: 20),

                // New Password Input
                if (resetPasswordProvider.isOtpVerified)
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      labelStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    obscureText: true,
                  ),
                if (resetPasswordProvider.isOtpVerified) const SizedBox(height: 20),

                // Verify or Reset Button
                resetPasswordProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: () {
                          if (resetPasswordProvider.isOtpVerified) {
                            resetPasswordProvider.resetPassword(
                              context,
                              email,
                              _otpController.text,
                              _passwordController.text,
                            );
                          } else {
                            resetPasswordProvider.verifyOtp(
                              context,
                              email,
                              _otpController.text,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A1B9A), // Purple button
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: Center(
                          child: Text(resetPasswordProvider.isOtpVerified ? 'Reset Password' : 'Verify OTP'),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
