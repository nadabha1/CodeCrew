import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class GroupChatScreen extends StatefulWidget {
  final String conversationId;
  final String groupName;

  const GroupChatScreen({
    required this.conversationId,
    required this.groupName,
  });

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  List<Map<String, dynamic>> messages = [];
  final TextEditingController _messageController = TextEditingController();
  late IO.Socket socket;
  String? _userId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    initChat();
  }

  void initChat() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString("user_id");

    socket = IO.io('${ApiConstants.baseUrl}', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print("✅ Connexion WebSocket réussie !");
      socket.emit('joinRoom', widget.conversationId);
    });

    socket.off('receiveMessage');
    socket.on('receiveMessage', (data) {
      print("📩 Message reçu côté client: $data");
      setState(() {
        if (!messages.any((msg) => msg['_id'] == data['_id'])) {
          messages.add(data);
        }
      });
    });

    socket.onDisconnect((_) => print("❌ Connexion WebSocket fermée."));

    fetchMessages();
  }

  Future<void> fetchMessages() async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseUrl}/messages/c/${widget.conversationId}'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      setState(() {
        messages = jsonData.cast<Map<String, dynamic>>();
      });
    } else {
      print("❌ Erreur lors de la récupération des messages : ${response.body}");
    }
  }

  void sendMessage() async {
    if (_isSending || _messageController.text.isEmpty) {
      print("⚠️ Message vide ou envoi déjà en cours !");
      return;
    }

    _isSending = true;
    print("🛑 Bouton pressé, envoi du message...");

    final message = {
      'conversationId': widget.conversationId,
      'senderId': _userId,
      'content': _messageController.text,
    };

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/messages'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("✅ Message envoyé avec succès : ${response.body}");
        final newMessage = jsonDecode(response.body);
        setState(() {
          messages.add(newMessage);
        });
      } else {
        print("❌ Erreur lors de l'envoi du message : ${response.body}");
      }
    } catch (e) {
      print("❌ Erreur réseau lors de l'envoi du message : $e");
    } finally {
      _isSending = false;
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    socket.off('receiveMessage');
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/whatsapp.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMe = (message['sender'] is String)
                      ? message['sender'] == _userId // Si sender est une chaîne
                      : message['sender']['_id'] ==
                          _userId; // Si sender est un objet

                  final senderName = (message['sender'] is String)
                      ? 'Utilisateur inconnu' // Si sender est juste un ID, pas de nom
                      : message['sender']['name'] ??
                          'Utilisateur inconnu'; // Si sender est un objet

                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      padding: EdgeInsets.all(8),
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue[200] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                senderName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          Text(
                            message['content'],
                            style: TextStyle(color: Colors.black),
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
                        hintText: 'Enter a message...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: sendMessage,
                    backgroundColor: Colors.orangeAccent,
                    child: Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
