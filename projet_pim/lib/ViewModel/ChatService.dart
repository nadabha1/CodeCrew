import 'package:projet_pim/Providers/conversation_provider.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatService {
  late IO.Socket socket;
  final ConversationProvider conversationProvider;

  ChatService({required this.conversationProvider});

  void connect(String userId) {
    socket = IO.io(
        '${ApiConstants.baseUrl}/carnets',
        IO.OptionBuilder()
            .setTransports(['websocket']).setQuery({'userId': userId}).build());

    socket.onConnect((_) {
      print('Connected to chat server');
    });

    socket.on('receiveMessage', (data) {
      print('New message: $data');
      // Update the conversation's last message using the provider
      conversationProvider.updateLastMessage(data['conversationId'], data['content']);
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
