import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/View/Event/EventDetailsScreen.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final EventProvider eventProvider;
  final String token;
  final String userId;

  ChatScreen({
    required this.conversationId,
    required this.eventProvider,
    required this.token,
    required this.userId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, dynamic>> messages = [];
  final TextEditingController _messageController = TextEditingController();
  String? otherUserName;
  FlutterSoundRecorder? _recorder;
  bool isRecording = false;
  String? _audioPath;
  FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool isPlaying = false;
  String? currentlyPlayingUrl;

  @override
  void initState() {
    super.initState();
    fetchConversations();
    fetchMessages();
    initRecorder();
    _player.openPlayer();
  }

  Future<void> initRecorder() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    await Permission.microphone.request();
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _recorder = null;
    _messageController.dispose();
    super.dispose();
    _player.closePlayer();
  }

  Future<void> fetchConversations() async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseUrl}/conversations/name/${widget.conversationId}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final participants = data['participants'];
      final other = participants.firstWhere(
        (p) => p['_id'] != widget.userId,
        orElse: () => null,
      );
      setState(() {
        otherUserName = other?['name'] ?? "Utilisateur";
      });
    }
  }

  Future<void> fetchMessages() async {
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseUrl}/messages/conversation/${widget.conversationId}'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        messages = data.map((msg) {
          return {
            'id': msg['_id'],
            'sender': msg['sender'],
            'content': msg['content'],
            'type': msg['type'] ?? 'text',
            'eventId': msg['event'],
            'createdAt': msg['createdAt']
          };
        }).toList();
      });
    }
  }

  String formatTimestamp(dynamic ts) {
    if (ts == null) return "";
    DateTime dateTime = DateTime.parse(ts).toLocal();
    return DateFormat('HH:mm').format(dateTime);
  }

  Future<void> sendMessage({String? text, String? eventId}) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/messages'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "conversationId": widget.conversationId,
        "senderId": widget.userId,
        "content": text ?? '',
        "type": eventId != null ? "shared_event" : "text",
        "eventId": eventId,
      }),
    );

    if (response.statusCode == 201) {
      _messageController.clear();
      fetchMessages();
    } else {
      print("❌ Erreur d'envoi: ${response.body}");
    }
  }

  Widget _buildSharedEventCard(String eventId) {
    return FutureBuilder<Event>(
      future: widget.eventProvider.getEventById(eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Chargement...");
        }
        if (!snapshot.hasData) {
          return Text("Événement introuvable");
        }

        final event = snapshot.data!;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailsScreen(
                  event: event,
                  userId: widget.userId,
                  token: widget.token,
                  eventProvider: widget.eventProvider,
                ),
              ),
            );
          },
          child: Card(
            color: Color(0xFFE6F0FF),
            margin: EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("📢 ${event.title}",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(
                      "📍 Lieu : ${event.location.latitude.toStringAsFixed(4)}, ${event.location.longitude.toStringAsFixed(4)}"),
                  Text(
                      "📅 Début : ${DateFormat('dd MMM yyyy, HH:mm').format(event.startDate)}"),
                  Text("🔗 Rejoins : chat/${event.id}"),
                ],
              ),
            ),
          ),
        );
      },
    );
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
      decoration: BoxDecoration(
        color: isMe ? Colors.deepPurple[100] : Colors.grey[300],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(isMe ? 12 : 0),
          bottomRight: Radius.circular(isMe ? 0 : 12),
        ),
      ),
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
        title: Text(otherUserName ?? "Discussion"),
        backgroundColor: const Color(0xFFFFCDB1),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['sender']?['_id'] == widget.userId;

                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: msg['type'] == 'shared_event'
                      ? _buildSharedEventCard(msg['eventId'])
                      : msg['type'] == 'audio'
                          ? _buildAudioPlayer(msg['content'], isMe)
                          : Container(
                              margin: EdgeInsets.symmetric(vertical: 6),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.deepPurple[100]
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(msg['content'] ?? ""),
                                  SizedBox(height: 4),
                                  Text(formatTimestamp(msg['createdAt']),
                                      style: TextStyle(fontSize: 10)),
                                ],
                              ),
                            ),
                );
              },
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
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
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 6),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: () =>
                      sendMessage(text: _messageController.text.trim()),
                ),
                IconButton(
                  icon: Icon(isRecording ? Icons.stop : Icons.mic,
                      color: Colors.redAccent),
                  onPressed: isRecording ? stopRecording : startRecording,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
