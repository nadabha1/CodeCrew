import 'package:flutter/material.dart';
import 'package:projet_pim/Providers/UserPreferences.dart';
import 'package:projet_pim/Providers/auth_provider.dart';
import 'package:projet_pim/Providers/carnet_provider.dart';
import 'package:projet_pim/Providers/theme_provider.dart';
import 'package:projet_pim/Providers/user_provider.dart';
import 'package:projet_pim/View/UserPreferences/EventPreferencePage.dart';
import 'package:projet_pim/View/UserPreferences/FinalConfirmationPage.dart';
import 'package:projet_pim/View/UserPreferences/GenderSelectionPage.dart';
import 'package:projet_pim/View/UserPreferences/PreferredEventTime.dart';
import 'package:projet_pim/View/UserPreferences/SocialInteractionPage.dart';
import 'package:projet_pim/View/UserPreferences/activity_selection_page.dart';
import 'package:projet_pim/View/carnet&place/add_place_screen.dart';
import 'package:projet_pim/View/forgot_password_screen.dart';
import 'package:projet_pim/View/home_screen.dart';
import 'package:projet_pim/View/reset_password_screen.dart';
import 'package:projet_pim/View/signup_page.dart';
import 'package:projet_pim/View/user_profile.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projet_pim/View/login.dart';
import 'package:projet_pim/View/main_screen.dart';
import 'package:projet_pim/ViewModel/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("jwt_token");
  String? userId = prefs.getString("user_id");
  bool isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<LoginViewModel>(
            create: (_) => LoginViewModel()..loadSession()),
        ChangeNotifierProvider<CarnetProvider>(create: (_) => CarnetProvider()),
          ChangeNotifierProvider<UserPreferences>(create: (_) => UserPreferences()),
        ChangeNotifierProvider<UserProvider>(
            create: (_) => UserProvider()), // Add UserProvider here
        ChangeNotifierProvider<ThemeProvider>(
            create: (_) => ThemeProvider(isDarkMode)),
      ],
      child: MyApp(userId: userId, token: token),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? userId;
  final String? token;

  const MyApp({Key? key, this.userId, this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, ThemeProvider, child) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Flutter App",
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeProvider.themeMode,
        // theme: ThemeData(primarySwatch: Colors.blue),
        home: userId != null && token != null
            ? MainScreen() // ✅ If session exists, go to MainScreen
            : LoginView(), // Otherwise, show login screen
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
          '/add-place': (context) =>
              AddPlaceScreen(carnetId: ''), // ✅ New Route
        },
      );
    });
  }
}
