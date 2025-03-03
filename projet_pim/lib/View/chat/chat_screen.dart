import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    final url =
        'http://localhost:3000/messages/conversation/${widget.conversationId}';
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString("user_id");
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

        // ✅ Trouver le nom de l'autre utilisateur dès le premier message de lui
        String? detectedOtherUserName;
        for (var msg in messages) {
          if (msg['sender']?['_id'].toString() != _userId.toString()) {
            detectedOtherUserName =
                msg['sender']?['name'] ?? "Utilisateur inconnu";
            break; // Dès qu'on trouve le nom, on arrête la boucle
          }
        }

        // ✅ Si on a trouvé un nom, on le met à jour
        if (detectedOtherUserName != null) {
          otherUserName = detectedOtherUserName;
        } else {
          otherUserName = "Utilisateur inconnu"; // Valeur par défaut
        }
      });
    } else {
      print("❌ Erreur de chargement: ${response.body}");
    }
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null || timestamp == "") return "⏳"; // Handle null case
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
      return "⏳"; // Default fallback
    }
  }

  Future<void> sendMessage() async {
    final messageText = _messageController.text;
    if (messageText.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString("user_id");

    final url = 'http://localhost:3000/messages';
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "conversationId": widget.conversationId,
        "senderId": _userId,
        "content": messageText,
        "createdAt": DateTime.now()
            .millisecondsSinceEpoch, // Utilise DateTime.now().millisecondsSinceEpoch pour récupérer le timestamp en millisecondes
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
        title: Text(otherUserName ?? "Chat"), // Nom du correspondant
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
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (!isMe) // N'affiche le nom que pour l'autre utilisateur
                            Padding(
                              padding: EdgeInsets.only(left: 50, right: 0),
                              child: Text(
                                message['sender']?['name'] ??
                                    "Utilisateur inconnu",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700]),
                              ),
                            ),
                          Container(
                            margin: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 10),
                            padding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color(0xFFF3C7F9)
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                                bottomLeft: isMe
                                    ? Radius.circular(12)
                                    : Radius.circular(0),
                                bottomRight: isMe
                                    ? Radius.circular(0)
                                    : Radius.circular(12),
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
                        ],
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
