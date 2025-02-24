import 'package:flutter/material.dart';
import 'package:projet_pim/View/home_screen.dart';
import 'package:projet_pim/View/user_profile.dart';

class MainScreen extends StatefulWidget {
  final String userId;
  final String token;

  const MainScreen({required this.userId, required this.token, Key? key})
      : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(userId: widget.userId), // ✅ Pass userId dynamically
      Placeholder(), // Placeholder for Explore Page (Replace with actual widget)
      Placeholder(), // Placeholder for Messages Page (Replace with actual widget)
      UserProfileScreen(
          userId: widget.userId,
          token: widget.token), // ✅ Pass both userId & token
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // ✅ Show selected page dynamically
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF3C7F9),
              Color(0xFFFE9332),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white, // ✅ Couleur des éléments actifs
          unselectedItemColor:
              Colors.white70, // ✅ Couleur des éléments inactifs
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
                icon: Icon(Icons.explore), label: "Explore"),
            BottomNavigationBarItem(
                icon: Icon(Icons.message), label: "Messages"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
