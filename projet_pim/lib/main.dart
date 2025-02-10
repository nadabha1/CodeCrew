import 'package:flutter/material.dart';
import 'package:projet_pim/View/forgot_password_screen.dart';
import 'package:projet_pim/View/reset_password_screen.dart';
import 'package:provider/provider.dart';
import './providers/auth_provider.dart';


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
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        title: 'User Management',
        initialRoute: '/forgot-password',
        routes: {
          '/forgot-password': (context) => ForgotPasswordScreen(),
          '/reset-password': (context) => ResetPasswordScreen(email: 'nadabha135@gmail.com'),
        },
      ),
    );
  }
}
