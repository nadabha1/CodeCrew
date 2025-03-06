import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NewConversationScreen extends StatefulWidget {
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
    final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/users/all')); // Remplace par ton API
    if (response.statusCode == 200) {
      setState(() {
        users = json.decode(response.body);
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
    final url = 'http://10.0.2.2:3000/conversations/$_userId';
    final body = jsonEncode({"otherUserId": otherUserId}); // ✅ Corrigé

    print("📤 Envoi de la requête: $url avec body: $body");

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: body, // ✅ Pas besoin de double jsonEncode()
    );

    print("📬 Réponse Code: ${response.statusCode}");
    print("📬 Réponse Body: ${response.body}");

    if (response.statusCode == 201) {
      Navigator.pop(context, json.decode(response.body));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Erreur lors de la création de la conversation: ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nouvelle Conversation")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
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
