import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ViewModel/login.dart';

class LoginView extends StatefulWidget {
  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  Widget build(BuildContext context) {
    final loginViewModel = Provider.of<LoginViewModel>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background with Abstract Shapes
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.purple.shade50],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -50,
            left: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: Colors.purple.shade200,
            ),
          ),
          Positioned(
            top: 100,
            right: -50,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.pink.shade100,
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: Colors.purple.shade100,
            ),
          ),

          // Login Form
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  const Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Good to see you back! ❤️",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Email Input
                  TextField(
                    onChanged: loginViewModel.setEmail,
                    decoration: InputDecoration(
                      labelText: "Email",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Password Input
                  TextField(
                    onChanged: loginViewModel.setPassword,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Login Button
                  loginViewModel.isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () => loginViewModel.login(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade900,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: const Text(
                            "Next",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),

                  // Error Message
                  if (loginViewModel.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      loginViewModel.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
