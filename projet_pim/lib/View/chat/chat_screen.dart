import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

Future<void> fetchMessages() async {
  final url = 'http://10.0.2.2:3000/messages/conversation/${widget.conversationId}'; // ✅ Nouvelle URL correcte
final prefs = await SharedPreferences.getInstance();
   _userId = prefs.getString("user_id");  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final List<dynamic> jsonData = jsonDecode(response.body);
    print("📩 Messages reçus: $jsonData");  // 👀 Vérifier le contenu reçu

    setState(() {
      messages = jsonData.map((msg) => {
        'id': msg['_id'],
        'content': msg['content'],
        'sender': msg['sender'],  // S'assurer que c'est bien 'sender' et pas 'senderId'
      }).toList();
    });
  } else {
    print("❌ Erreur de chargement: ${response.body}");
  }
}



  Future<void> sendMessage() async {
  final messageText = _messageController.text;
  if (messageText.isEmpty) return;

  final prefs = await SharedPreferences.getInstance();
   _userId = prefs.getString("user_id");

  final url = 'http://10.0.2.2:3000/messages';  // ✅ Correction de l'URL
  final response = await http.post(
    Uri.parse(url),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "conversationId": widget.conversationId,
      "senderId": _userId, // 🔥 Remplacez par l'ID de l'utilisateur connecté
      "content": messageText,  // ✅ Correction du champ (`content` au lieu de `text`)
    }),
  );

  if (response.statusCode == 201) {
    _messageController.clear();
    fetchMessages(); // 🔥 Actualisation des messages après envoi
  } else {
    print("❌ Erreur d'envoi: ${response.body}");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMe = message['sender'] == _userId;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.deepPurple : Colors.grey[300],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      message['content'], // Assure-toi que c'est bien 'content' et pas 'text'
                      style: TextStyle(color: isMe ? Colors.white : Colors.black),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
