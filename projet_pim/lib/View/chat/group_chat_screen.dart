import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_sound/public/flutter_sound_player.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/View/Widgets/eventCardMessageWidget.dart';
import 'package:projet_pim/View/chat/CallScreen.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class GroupChatScreen extends StatefulWidget {
  final String conversationId;
  final String groupName;
  final EventProvider eventProvider;
  final String userId;

  const GroupChatScreen({
    required this.conversationId,
    required this.groupName,
    required this.eventProvider,
    required this.userId,
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
  FlutterSoundRecorder? _recorder;
  bool isRecording = false;
  String? _audioPath;
  FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool isPlaying = false;
  String? currentlyPlayingUrl;
  @override
  void initState() {
    super.initState();
    initChat();
    initRecorder();
    _player.openPlayer();
  }

  Future<void> initRecorder() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    await Permission.microphone.request();
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

  void sendMessage({required String text}) async {
    if (_isSending || text.isEmpty) {
      print("⚠️ Message vide ou envoi déjà en cours !");
      return;
    }

    _isSending = true;
    print("🛑 Bouton pressé, envoi du message...");

    final message = {
      'conversationId': widget.conversationId,
      'senderId': _userId,
      'content': text, // Use the passed text here
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
    }
  }

  @override
  void dispose() {
    socket.off('receiveMessage');
    socket.dispose();
    super.dispose();
    _recorder?.closeRecorder();
    _recorder = null;
    _messageController.dispose();
    super.dispose();
    _player.closePlayer();
  }

  Future<void> startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission micro refusée')),
      );
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    _audioPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder!.startRecorder(toFile: _audioPath);
    setState(() => isRecording = true);
  }

  Future<void> stopRecording() async {
    await _recorder!.stopRecorder();
    setState(() => isRecording = false);
    if (_audioPath != null) {
      await sendAudioMessage(_audioPath!);
    }
  }

  Future<void> sendAudioMessage(String path) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/messages/audio'),
    );

    request.fields['conversationId'] = widget.conversationId;
    request.fields['senderId'] = widget.userId;
    request.files.add(await http.MultipartFile.fromPath('audio', path));
    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      fetchMessages();
    } else {
      print("Erreur d'envoi audio: $respStr");
    }
  }

  Widget _buildAudioPlayer(String url, bool isMe) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.audiotrack, color: Colors.deepPurple),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(
              isPlaying && currentlyPlayingUrl == url
                  ? Icons.stop
                  : Icons.play_arrow,
              color: Colors.deepPurple,
            ),
            onPressed: () async {
              if (isPlaying && currentlyPlayingUrl == url) {
                await _player.stopPlayer();
                setState(() {
                  isPlaying = false;
                  currentlyPlayingUrl = null;
                });
              } else {
                await _player.startPlayer(
                  fromURI: "${ApiConstants.baseUrl}/$url",
                  whenFinished: () {
                    setState(() {
                      isPlaying = false;
                      currentlyPlayingUrl = null;
                    });
                  },
                );
                setState(() {
                  isPlaying = true;
                  currentlyPlayingUrl = url;
                });
              }
            },
          ),
          Text("Audio"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: const Color(0xFFFFCDB1),
        actions: [
          IconButton(
            onPressed: () async {
              final callLink = 'call:${'monChannel'}';
              sendMessage(text: callLink); // No need to await here

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    channelName: 'monChannel',
                    conversationId: widget.conversationId,
                    userId: widget.userId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.call),
          )
        ],
      ),
      body: Container(
        /*decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/whatsapp.jpeg'),
            fit: BoxFit.cover,
          ),
        ),*/
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
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? const Color.fromARGB(255, 241, 214, 250)
                            : Colors.white,
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
                          if (message['type'] == 'audio')
                            _buildAudioPlayer(message['content'], isMe)
                          else if (message['content'] != null &&
                              message['content'].toString().startsWith('call:'))
                            // Handle clickable "call:" link
                            GestureDetector(
                              onTap: () {
                                final channelName = message['content']
                                    .toString()
                                    .substring(5); // remove 'call:'
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CallScreen(
                                      channelName: channelName,
                                      conversationId: widget.conversationId,
                                      userId: widget.userId,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                "📞 Rejoindre l'appel",
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            )
                          else
                            Text(
                              message['content'] ?? '',
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
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.deepPurple),
                    onPressed: () {
                      sendMessage(text: _messageController.text);
                    },
                  ),
                  IconButton(
                    icon: Icon(isRecording ? Icons.stop : Icons.mic,
                        color: Colors.redAccent),
                    onPressed: isRecording ? stopRecording : startRecording,
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
