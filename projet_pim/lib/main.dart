import 'package:flutter/material.dart';
import 'package:projet_pim/View/add_place_screen.dart';
import 'package:projet_pim/View/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:projet_pim/Providers/auth_provider.dart';
import 'package:projet_pim/Providers/carnet_provider.dart';
import 'package:projet_pim/View/home_screen.dart';
import 'package:projet_pim/View/login.dart';
import 'package:projet_pim/View/signup_page.dart';
import 'package:projet_pim/View/forgot_password_screen.dart';
import 'package:projet_pim/View/reset_password_screen.dart';
import 'package:projet_pim/View/user_profile.dart';
import 'package:projet_pim/ViewModel/login.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<LoginViewModel>(create: (_) => LoginViewModel()..loadToken()),
        ChangeNotifierProvider<CarnetProvider>(create: (_) => CarnetProvider()), // ✅ Ensuring CarnetProvider is included
      ],
      child: const MyApp(), // ✅ Using 'const' for optimization
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Flutter Signup App",
      theme: ThemeData(primarySwatch: Colors.blue),
      home:  MainScreen(), // ✅ Using 'const' when possible
      routes: {
        '/home': (context) =>  HomeScreen(userId: '67a37ac68b9e4e153a914e9e'),
        '/signup': (context) =>  SignUpPage(),
        '/forgot-password': (context) =>  ForgotPasswordScreen(),
        '/reset-password': (context) =>  ResetPasswordScreen(email: ''),
        '/login': (context) =>  LoginView(),
        '/profile': (context) => const UserProfileScreen(
              userId: 'exampleId',
              token: 'exampleToken',
            ),
        '/add-place': (context) => AddPlaceScreen(carnetId: ''), // ✅ New Route

      },
    );
  }
}
