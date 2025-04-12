import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;

  ChatScreen({required this.conversationId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, dynamic>> messages = [];
  final TextEditingController _messageController = TextEditingController();
  String? _userId;
  String? otherUserName; // Stocke le nom du correspondant
  List conversations = [];

  @override
  void initState() {
    super.initState();
    getUserId();
    fetchConversations(); // ✅ Appel pour récupérer les noms des participants
    fetchMessages();
  }

  Future<void> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString("user_id");
  }

  Future<void> fetchConversations() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString("user_id");
    bool isLoading = true;

    final response = await http.get(Uri.parse(
        '${ApiConstants.baseUrl}/conversations/name/${widget.conversationId}'));

    if (response.statusCode == 200) {
      // ✅ Correction: utilise Map au lieu de List
      final Map<String, dynamic> conversationData = json.decode(response.body);

      setState(() {
        isLoading = false;

        // ✅ Accède aux participants de la conversation
        final List participants = conversationData['participants'] ?? [];

        // ✅ Récupère le nom du participant
        String name = getParticipantName(participants);
        setState(() {
          otherUserName = name; // ✅ Met à jour le nom du correspondant
        });
      });
    } else {
      setState(() {
        isLoading = false;
      });
      print('❌ Erreur lors du chargement des conversations');
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

  Future<void> fetchMessages() async {
    final url =
        '${ApiConstants.baseUrl}/messages/conversation/${widget.conversationId}';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      setState(() {
        messages = jsonData
            .map((msg) => {
                  'id': msg['_id'],
                  'content': msg['content'],
                  'sender': msg['sender'],
                  'createdAt': msg['createdAt'],
                })
            .toList();
      });
    } else {
      print("❌ Erreur de chargement: ${response.body}");
    }
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null || timestamp == "") return "⏳";
    try {
      DateTime dateTime;
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp).toLocal();
      } else if (timestamp is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
      } else {
        return "⏳";
      }
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      print("Error parsing timestamp: $timestamp");
      return "⏳";
    }
  }

  Future<void> sendMessage() async {
    final messageText = _messageController.text;
    if (messageText.isEmpty) return;

    final url = '${ApiConstants.baseUrl}/messages';
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "conversationId": widget.conversationId,
        "senderId": _userId,
        "content": messageText,
        "createdAt": DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      _messageController.clear();
      fetchMessages();
    } else {
      print("❌ Erreur d'envoi: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(otherUserName ?? "Utilisateur inconnu"),
        backgroundColor: const Color(0xFFFFCDB1),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                "assets/whatsapp.jpeg",
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: messages.length,
                  padding: EdgeInsets.all(10),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['sender']?['_id'].toString() ==
                        _userId.toString();

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color:
                              isMe ? const Color(0xFFF3C7F9) : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                            bottomLeft:
                                isMe ? Radius.circular(12) : Radius.circular(0),
                            bottomRight:
                                isMe ? Radius.circular(0) : Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['content'],
                              style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                  fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Text(
                              formatTimestamp(message['createdAt']),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: "Écrire un message...",
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCDB1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send, color: Colors.white),
                        onPressed: sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
