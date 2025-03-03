import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatService {
  late IO.Socket socket;

  void connect(String userId) {
    socket = IO.io(
        'http://10.0.2.2:3000',
        IO.OptionBuilder()
            .setTransports(['websocket']).setQuery({'userId': userId}).build());

    socket.onConnect((_) {
      print('Connected to chat server');
    });

    socket.on('receiveMessage', (data) {
      print('New message: $data');
      // Update your chat UI here (state management like Provider, Riverpod, etc.)
    });

    socket.onDisconnect((_) {
      print('Disconnected from chat server');
    });
  }

  void sendMessage(String receiverId, String content) {
    socket.emit('sendMessage', {'receiverId': receiverId, 'content': content});
  }

  void disconnect() {
    socket.disconnect();
  }
}
