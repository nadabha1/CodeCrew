import 'package:flutter/material.dart';
import 'package:projet_pim/View/ExploreScreen.dart';
import 'package:projet_pim/View/Widgets/custom_bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projet_pim/View/home_screen.dart';
import 'package:projet_pim/View/user_profile.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? _userId;
  String? _token;
  bool _isLoading = true; // To prevent null errors before loading session

  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _loadSession(); // Load token and userId from SharedPreferences
  }

  /// ✅ Load User Session (Token & UserID)
  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString("user_id");
      _token = prefs.getString("jwt_token");
      _isLoading = false;

      // ✅ If token & userId are missing, redirect to Login
      if (_userId == null || _token == null) {
        Navigator.pushReplacementNamed(context, "/login");
      } else {
        _pages = [
          HomeScreen(userId: _userId!), // ✅ Pass dynamic userId
          ExploreScreen(userId: _userId!), // ✅ Page Explore avec token

          Placeholder(), // Messages (To be replaced)
          UserProfileScreen(
              userId: _userId!, token: _token!), // ✅ Pass userId & token
        ];
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Show loading screen while retrieving session data
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
