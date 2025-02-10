import 'package:flutter/material.dart';
import 'package:projet_pim/View/forgot_password_screen.dart';
import 'package:projet_pim/View/reset_password_screen.dart';
import 'package:provider/provider.dart';
import '/Providers/auth_provider.dart'; // Correct path to match folder structure
import 'view/signup_page.dart'; // Correct path to the SignUpPage

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Flutter Signup App", // Optional: Add a title for the app
      theme: ThemeData(primarySwatch: Colors.blue), // Optional: Define a theme
      home: SignUpPage(),
      routes: {
        '/signup': (context) => SignUpPage(), // Define a route to the SignUpPage
        '/forgot-password': (context) => ForgotPasswordScreen(),
        '/reset-password': (context) => ResetPasswordScreen(email: 'nadabha135@gmail.com'),      },
    );
  }
}
