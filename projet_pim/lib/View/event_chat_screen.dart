import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart';

class EventChatScreen extends StatefulWidget {
  final String eventId;
  final String userId;

  const EventChatScreen({required this.eventId, required this.userId});

  @override
  _EventChatScreenState createState() => _EventChatScreenState();
}

class _EventChatScreenState extends State<EventChatScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _messages = [];
  TextEditingController _messageController = TextEditingController();
  late IO.Socket _socket;
  bool _isConnected = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();

    _socket = IO.io('http://10.0.2.2:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'forceNew': true,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
    });

    _socket.onConnect((_) {
      print('Connected to socket at http://10.0.2.2:3000');
      _isConnected = true;
      _socket.emit('joinEvent', {'eventId': widget.eventId, 'userId': widget.userId});
    });

    _socket.on('joined', (data) {
      print('Joined event: $data');
    });

    _socket.on('receiveMessage', (data) {
      print('Received message: $data');
      setState(() {
        _messages.add({
          'eventId': data['eventId'],
          'userId': data['userId'],
          'message': data['message'],
          'timestamp': data['timestamp'],
          '_id': data['_id'],
        });
        _animationController.forward(from: 0.0); // Trigger animation on new message
      });
    });

    _socket.on('initialMessages', (data) {
      print('Initial messages: $data');
      setState(() {
        _messages = List<Map<String, dynamic>>.from(data.map((msg) => {
          'eventId': msg['eventId'],
          'userId': msg['userId'],
          'message': msg['message'],
          'timestamp': msg['timestamp'],
          '_id': msg['_id'],
        }));
        _animationController.forward(from: 0.0); // Trigger animation on initial load
      });
    });

    _socket.onDisconnect((_) {
      print('Disconnected from socket');
      _isConnected = false;
    });

    _socket.onError((err) {
      print('Socket error: $err');
    });

    _socket.onConnectError((err) {
      print('Connect error: $err');
    });

    _socket.onConnectTimeout((_) {
      print('Connection timeout');
    });

    _socket.on('error', (data) {
      print('Server error: $data');
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _socket.disconnect();
    _socket.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void sendMessage(String message) {
    if (message.isNotEmpty && _isConnected) {
      print('Sending message: $message to event ${widget.eventId}');
      _socket.emit('sendMessage', {
        'eventId': widget.eventId,
        'userId': widget.userId,
        'message': message,
      });
      _messageController.clear();
      print('Message sent (awaiting server confirmation via receiveMessage)');
    } else {
      print('Cannot send: ${_isConnected ? "Message is empty" : "Not connected"}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat for ${widget.eventId.substring(0, 8)}...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF4A90E2),
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFE0E7FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ListView.builder(
                  padding: EdgeInsets.all(16.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isSender = message['userId'] == widget.userId;
                    final timestamp = message['timestamp']?.toString() ?? '';
                    final timeParts = timestamp.contains(' ') ? timestamp.split(' ') : ['', timestamp];
                    final time = timeParts.length > 1 ? timeParts[1].split('.')[0] : '';

                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Align(
                        alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                          decoration: BoxDecoration(
                            color: isSender ? Color(0xFF4A90E2) : Color(0xFFEFF2F7),
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4.0,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['message'],
                                style: TextStyle(
                                  color: isSender ? Colors.white : Colors.black87,
                                  fontSize: 16.0,
                                ),
                              ),
                              SizedBox(height: 4.0),
                              Text(
                                time.isNotEmpty ? time : 'N/A',
                                style: TextStyle(
                                  color: isSender ? Colors.white70 : Colors.black54,
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6.0,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Color(0xFFF0F2F5),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      ),
                      onChanged: (text) => setState(() {}), // Force rebuild on text change
                    ),
                  ),
                  SizedBox(width: 8.0),
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: _isConnected && _messageController.text.isNotEmpty ? Color(0xFF4A90E2) : Colors.grey,
                    onPressed: _isConnected && _messageController.text.isNotEmpty
                        ? () => sendMessage(_messageController.text)
                        : null,
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