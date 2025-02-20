import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/auth_provider.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  void _registerUser(BuildContext context) async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill all the fields!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Passwords do not match!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success = await authProvider.registerUser(
      nameController.text,
      emailController.text,
      passwordController.text,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Signup successful!"), backgroundColor: Colors.green),
      );

      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, "/gender-selection");
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Signup failed. Please try again!"),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                  color: Color(0xFFE8EAF6), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                  color: Color(0xFFF8BBD0), shape: BoxShape.circle),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 80),
                Text("Create\nAccount",
                    style:
                        TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
                SizedBox(height: 40),
                TextField(
                    controller: nameController,
                    decoration: _inputDecoration("Name")),
                SizedBox(height: 20),
                TextField(
                    controller: emailController,
                    decoration: _inputDecoration("Email")),
                SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: _isPasswordObscured,
                  decoration: _passwordDecoration("Password", () {
                    setState(() {
                      _isPasswordObscured = !_isPasswordObscured;
                    });
                  }),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: _isConfirmPasswordObscured,
                  decoration: _passwordDecoration("Confirm Password", () {
                    setState(() {
                      _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                    });
                  }),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => _registerUser(context),
                  style: _buttonStyle(),
                  child: Center(child: Text("Done")),
                ),
                Center(
                  child: GestureDetector(
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, "/login"),
                    child: Text("Already have an account? Login",
                        style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  InputDecoration _passwordDecoration(
      String label, VoidCallback toggleVisibility) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      suffixIcon: IconButton(
        icon: Icon(Icons.visibility),
        onPressed: toggleVisibility,
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF2C2C54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: EdgeInsets.symmetric(vertical: 16),
    );
  }
}
