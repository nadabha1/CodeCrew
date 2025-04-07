import 'package:flutter/material.dart';
import 'package:projet_pim/View/ExploreScreen.dart';
import 'package:projet_pim/View/NotificationScreen.dart';
import 'package:projet_pim/View/Widgets/custom_bottom_nav.dart';
import 'package:projet_pim/View/chat/conversation_list_screen.dart';
import 'package:projet_pim/ViewModel/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projet_pim/View/home_screen.dart';
import 'package:projet_pim/View/user_profile.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? _userId;
  String? _token;
  bool _isLoading = true;
  int _unreadNotifications = 0;
  final NotificationService _notificationService = NotificationService();

  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString("user_id");
      _token = prefs.getString("jwt_token");
      _isLoading = false;

      if (_userId == null || _token == null) {
        Navigator.pushReplacementNamed(context, "/login");
      } else {
        _fetchUnreadNotifications();
        _pages = [
          HomeScreen(userId: _userId!),
          ExploreScreen(userId: _userId!),
          ConversationListScreen(),
          NotificationScreen(userId: _userId!),
          UserProfileScreen(userId: _userId!, token: _token!),
        ];
      }
    });
  }

  Future<void> _fetchUnreadNotifications() async {
    if (_userId != null) {
      final count = await _notificationService.getUnreadNotificationsCount(_userId!);
      setState(() {
        _unreadNotifications = count;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        unreadNotifications: _unreadNotifications,
      ),
    );
  }
}
