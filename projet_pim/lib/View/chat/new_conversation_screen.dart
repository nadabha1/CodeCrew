import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NewConversationScreen extends StatefulWidget {
  const NewConversationScreen({super.key});

  @override
  _NewConversationScreenState createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen> {
  List users = [];
  bool isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString("user_id");

    final response =
        await http.get(Uri.parse('${ApiConstants.baseUrl}/users/all'));
    if (response.statusCode == 200) {
      final allUsers = json.decode(response.body);
      setState(() {
        users = allUsers
            .where((user) => user['_id'] != _userId)
            .toList(); // ✅ Exclude the logged-in user
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void startConversation(String otherUserId) async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString("user_id");
    final url = '${ApiConstants.baseUrl}/conversations/$_userId';
    final body = jsonEncode({"otherUserId": otherUserId}); // ✅ Corrected

    print("📤 Sending request: $url with body: $body");

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: body, // ✅ No need for double jsonEncode()
    );

    print("📬 Response Code: ${response.statusCode}");
    print("📬 Response Body: ${response.body}");

    if (response.statusCode == 201) {
      Navigator.pop(context, json.decode(response.body));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error creating conversation: ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Conversation")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                      backgroundImage: NetworkImage(user['profileImage'])),
                  title: Text(user['name']),
                  onTap: () => startConversation(
                    user['_id'],
                  ),
                );
              },
            ),
    );
  }
}
