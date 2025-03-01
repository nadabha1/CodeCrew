import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_pim/View/chat/chat_screen.dart';
import 'dart:convert';

import 'package:projet_pim/View/chat/new_conversation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConversationListScreen extends StatefulWidget {
  @override
  _ConversationListScreenState createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  List conversations = [];
  bool isLoading = true;
  String? _userId;


  @override
  void initState() {
    super.initState();
    fetchConversations();
  }

  Future<void> fetchConversations() async {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString("user_id");

    final response = await http.get(Uri.parse('http://10.0.2.2:3000/conversations/$_userId'));

    if (response.statusCode == 200) {
      setState(() {
        conversations = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Erreur lors du chargement des conversations');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Conversations"),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : conversations.isEmpty
              ? Center(child: Text("Aucune conversation."))
              : ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final lastMessage = conversation['lastMessage']?['content'] ?? 'Aucun message';
                    final List participants = conversation['participants'];
final otherParticipant = participants.firstWhere(
  (p) => p['_id'] != _userId, // Remplace par l'ID du user connecté
  orElse: () => null,
);

return ListTile(
  leading: CircleAvatar(
    backgroundImage: NetworkImage(otherParticipant?['avatarUrl'] ?? ''),
  ),
  title: Text(
    otherParticipant?['name'] ?? "Utilisateur inconnu",
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
  subtitle: Text(
    lastMessage,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  ),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversationId: conversation['_id']),
      ),
    );
  },
);

                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewConversationScreen()),
          );
        },
        backgroundColor: Colors.deepPurple,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
