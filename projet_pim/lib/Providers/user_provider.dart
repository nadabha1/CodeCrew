import 'package:flutter/material.dart';
import 'package:projet_pim/ViewModel/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _users = [];

  // Getter for users
  List<Map<String, dynamic>> get users => _users;

  // Method to fetch users
  Future<void> fetchUsers(String token) async {
    try {
      final fetchedUsers = await _userService.getAllUsers2(token);
      _users = fetchedUsers;
      notifyListeners();
    } catch (e) {
      print('Error fetching users: $e');
    }
  }
}
