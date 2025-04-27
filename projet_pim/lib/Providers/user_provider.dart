import 'package:flutter/material.dart';
import 'package:projet_pim/ViewModel/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _matches = []; 

  // Getter for users
  List<Map<String, dynamic>> get users => _users;
  List<Map<String, dynamic>> get matches => _matches;

  // Method to fetch users
  Future<void> fetchUsers(String token) async {
    try {
      final fetchedUsers = await _userService.getAllUsers(token);
      _users = fetchedUsers;
      notifyListeners();
    } catch (e) {
      print('Error fetching users: $e');
    }
  }
  Future<void> fetchMatches(String userId) async {
  try {
    final fetchedMatches = await _userService.matchUser(userId);
    _matches = fetchedMatches;
    notifyListeners();
  } catch (e) {
    print('Error fetching matches: $e');
  }
}

}
