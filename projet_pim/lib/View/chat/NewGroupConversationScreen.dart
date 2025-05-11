import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewGroupConversationScreen extends StatefulWidget {
  const NewGroupConversationScreen({super.key});

  @override
  _NewGroupConversationScreenState createState() =>
      _NewGroupConversationScreenState();
}

class _NewGroupConversationScreenState
    extends State<NewGroupConversationScreen> {
  List users = [];
  List<String> selectedUserIds = [];
  TextEditingController groupNameController = TextEditingController();
  String? userId;
  String? token;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString("user_id");
    final storedToken = prefs.getString("jwt_token");

    if (storedUserId != null && storedToken != null) {
      print("User ID and Token retrieved from SharedPreferences.");
      setState(() {
        userId = storedUserId;
        token = storedToken;
      });
      await getFollowing(
          storedUserId); // You can keep storedUserId as it is not null
    } else {
      print("User ID or Token is not available");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Call getFollowing via UserService
  Future<void> getFollowing(String userId) async {
    try {
      print("Fetching the following users for userId: $userId");
      // Get the list of followed users
      UserService userService = UserService();
      List<String> following = await userService.getFollowing(userId);
      print("Following users from the backend: $following");

      if (following.isEmpty) {
        print("No users followed.");
      }

      // Call function to get details of followed users
      List<Map<String, dynamic>> fetchedUsers =
          await getUserById(following, token!);

      setState(() {
        users = fetchedUsers; // Update the list of users with the fetched data
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching followed users: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> getUserById(
      List<String> userIds, String token) async {
    List<Map<String, dynamic>> fetchedUsers = [];

    for (String userId in userIds) {
      try {
        print("Fetching details for userId: $userId");
        final user = await UserService().getUserById(userId, token);
        if (user.containsKey('_id')) {
          print("User details retrieved: $user");
          fetchedUsers.add(user); // Add user to the list
        }
      } catch (e) {
        print("Error fetching details for user $userId: $e");
      }
    }

    return fetchedUsers;
  }

  // Function to create a group conversation
  Future<void> createGroupConversation() async {
    if (groupNameController.text.isEmpty || selectedUserIds.isEmpty) {
      print("Group name or members are missing.");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Group name or members missing.")));
      return;
    }

    final allParticipantIds = [userId!, ...selectedUserIds];
    print("Creating group conversation with participants: $allParticipantIds");

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/conversations/group'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "participants": allParticipantIds,
        "title": groupNameController.text.trim(),
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      print("Group conversation created successfully.");
      Navigator.pop(context, true);
    } else {
      print("Failed to create group conversation: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error creating the group.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create a Group")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: groupNameController,
                    decoration: const InputDecoration(labelText: "Group Name"),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final userId = user['_id'];
                        final isSelected = selectedUserIds.contains(userId);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user['profileImage'] != null
                                ? NetworkImage(user['profileImage'])
                                : const AssetImage('assets/default_profile.png')
                                    as ImageProvider,
                          ),
                          title: Text(user['name']),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (_) {
                              setState(() {
                                if (isSelected) {
                                  selectedUserIds.remove(userId);
                                } else {
                                  selectedUserIds.add(userId);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: createGroupConversation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC8C4FF),
                    ),
                    child: Text("Create Group"),
                  )
                ],
              ),
            ),
    );
  }
}
