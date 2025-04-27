import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/View/chat/NewGroupConversationScreen.dart';
import 'package:projet_pim/View/chat/chat_screen.dart';
import 'package:projet_pim/View/chat/group_chat_screen.dart';
import 'dart:convert';
import 'package:projet_pim/View/chat/new_conversation_screen.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
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

    final response = await http
        .get(Uri.parse('${ApiConstants.baseUrl}/conversations/$_userId'));

    if (response.statusCode == 200) {
      print(response.body); // ✅ Inspectez les données reçues
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

  String getParticipantName(List<dynamic> participants) {
    try {
      final otherParticipant = participants.firstWhere(
        (p) => p['_id'] != _userId,
        orElse: () => null,
      );

      if (otherParticipant != null &&
          otherParticipant is Map &&
          otherParticipant.containsKey('name')) {
        return otherParticipant['name'] ?? 'Utilisateur inconnu';
      }
    } catch (e) {
      print("🚨 Erreur lors de la récupération du nom: $e");
    }
    return 'Utilisateur inconnu';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Conversations"),
        backgroundColor: const Color(0xFFC8C4FF),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : conversations.isEmpty
              ? Center(child: Text("Aucune conversation."))
              : ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final lastMessage = conversation['lastMessage']
                            ?['content'] ??
                        'Aucun message';
                    final List participants = conversation['participants'];
                    final isGroupChat = conversation['title'] != null &&
                        conversation['title'].isNotEmpty;
                    final participantName = isGroupChat
                        ? conversation['title']
                        : getParticipantName(participants);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          participants.firstWhere(
                                (p) => p['_id'] != _userId,
                                orElse: () => {'avatarUrl': null},
                              )['avatarUrl'] ??
                              'https://example.com/default-avatar.png',
                        ),
                        child: isGroupChat
                            ? Icon(Icons.group, color: Colors.white)
                            : Icon(Icons.person, color: Colors.white),
                        backgroundColor: const Color(0xFFC8C4FF),
                      ),
                      title: Text(
                        participantName,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        lastMessage != null && lastMessage.isNotEmpty
                            ? lastMessage
                            : 'Aucun message', // ✅ Affiche un message par défaut
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => isGroupChat
                                ? GroupChatScreen(
                                                                    eventProvider: EventProvider(userId: _userId!),

                                    conversationId: conversation['_id'],
                                    groupName: conversation[
                                        'title'], // ✅ Passe le titre du groupe
                                  )
                                : ChatScreen(
                                  eventProvider: EventProvider(userId: _userId!),
                                  token: "",
                                  userId: _userId!,
                                    conversationId: conversation['_id'],
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: SpeedDial(
        backgroundColor: const Color(0xFFC8C4FF),
        animatedIcon: AnimatedIcons.menu_close,
        overlayColor: Colors.black,
        overlayOpacity: 0.3,
        spacing: 10,
        spaceBetweenChildren: 10,
        children: [
          SpeedDialChild(
            child: Icon(Icons.chat),
            label: 'Conversation privée',
            backgroundColor: Colors.deepPurple.shade100,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => NewConversationScreen()),
              );
              if (result != null) fetchConversations();
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.group),
            label: 'Créer un groupe',
            backgroundColor: Colors.deepPurple.shade100,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => NewGroupConversationScreen()),
              );
              if (result != null) fetchConversations();
            },
          ),
        ],
      ),
    );
  }
}
