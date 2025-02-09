import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  ResetPasswordScreen({required this.email});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isOtpVerified = false;

  void _verifyOtp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.verifyOtp(widget.email, _otpController.text);
      setState(() {
        _isOtpVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP verified successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _resetPassword() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.resetPassword(
        widget.email,
        _otpController.text,
        _passwordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset successful')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FC),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              _isOtpVerified ? "Set New Password" : "Verify OTP",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),

            // Subtitle
            Text(
              _isOtpVerified
                  ? "Enter your new password"
                  : "Enter the OTP sent to your email",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 40),

            // OTP Input
            if (!_isOtpVerified)
              TextField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: 'OTP',
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
                keyboardType: TextInputType.number,
              ),
            SizedBox(height: 20),

            // New Password Input
            if (_isOtpVerified)
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
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
                obscureText: true,
              ),
            SizedBox(height: 20),

            // Verify or Reset Button
            ElevatedButton(
              onPressed: _isOtpVerified ? _resetPassword : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A), // Purple button
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
              child: Center(
                child: Text(_isOtpVerified ? 'Reset Password' : 'Verify OTP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
