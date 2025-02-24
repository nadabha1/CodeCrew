import 'package:flutter/material.dart';
import 'package:projet_pim/View/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Providers/auth_provider.dart';
import 'Providers/carnet_provider.dart';
import 'Providers/theme_provider.dart';
import 'View/home_screen.dart';
import 'View/login.dart';
import 'View/signup_page.dart';
import 'View/user_profile.dart';
import 'View/carnet&place/add_place_screen.dart';
import 'View/UserPreferences/EventPreferencePage.dart';
import 'View/UserPreferences/FinalConfirmationPage.dart';
import 'View/UserPreferences/GenderSelectionPage.dart';
import 'View/UserPreferences/PreferredEventTime.dart';
import 'View/UserPreferences/SocialInteractionPage.dart';
import 'View/UserPreferences/activity_selection_page.dart';
import 'View/forgot_password_screen.dart';
import 'View/reset_password_screen.dart';
import 'ViewModel/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load Theme preference before starting the app
  final prefs = await SharedPreferences.getInstance();
  bool isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<CarnetProvider>(create: (_) => CarnetProvider()),
        ChangeNotifierProvider<LoginViewModel>(create: (_) => LoginViewModel()..loadSession()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider(isDarkMode)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  /// ✅ **Load session data from SharedPreferences**
  Future<Map<String, String?>> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');
    String? userId = prefs.getString('user_id');

    return {'token': token, 'userId': userId};
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Flutter Signup App",
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.themeMode,

          // ✅ **Use FutureBuilder to check session before showing screen**
          home: FutureBuilder<Map<String, String?>>(
            future: _loadSession(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              String? savedToken = snapshot.data?['token'];
              String? savedUserId = snapshot.data?['userId'];

              if (savedToken != null && savedUserId != null) {
                return MainScreen(userId: savedUserId, token: savedToken,); // ✅ Redirect to Home if session exists
              } else {
                return LoginView(); // ✅ Redirect to Login if no session
              }
            },
          ),

          routes: {
            '/home': (context) => HomeScreen(userId: '67a37ac68b9e4e153a914e9e'),
            '/signup': (context) => SignUpPage(),
            '/gender-selection': (context) => GenderSelectionPage(),
            '/activity-selection': (context) => ActivitySelectionPage(),
            '/event-preference': (context) => EventPreferencePage(),
            '/social-interaction': (context) => SocialInteractionPage(),
            '/preferred-event-time': (context) => PreferredEventTimePage(),
            '/final-confirmation': (context) => FinalConfirmationPage(),
            '/forgot-password': (context) => ForgotPasswordScreen(),
            '/reset-password': (context) => ResetPasswordScreen(email: ''),
            '/login': (context) => LoginView(),
            '/profile': (context) => const UserProfileScreen(
                  userId: 'exampleId',
                  token: 'exampleToken',
                ),
            '/add-place': (context) => AddPlaceScreen(carnetId: ''),
          },
        );
      },
    );
  }
}
