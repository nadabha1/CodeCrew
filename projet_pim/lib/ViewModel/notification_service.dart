import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class NotificationService {
  final IO.Socket _socket = IO.io('${ApiConstants.baseUrl}', <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
  });

  void connect(String userId) {
    _socket.connect();
    _socket.onConnect((_) {
      print('⚡ Connected to WebSocket');
      _socket.emit('join', userId);
    });
  }

  void listenToNotifications(Function(Map<String, dynamic>) onNotificationReceived) {
    _socket.on('newNotification', (data) {
      print('📢 New notification received: $data');
      onNotificationReceived(data);
    });
  }

  void disconnect() {
    _socket.disconnect();
  }

  Future<List<Map<String, dynamic>>> fetchNotifications(String userId) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/notifications/$userId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      print('Error: ${response.body}');
      throw Exception('Error fetching notifications');
    }
  }

  Future<int> getUnreadNotificationsCount(String userId) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/notifications/unread-count/$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['unreadCount'] ?? 0;
    } else {
      print('Error fetching unread notifications');
      return 0;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/notifications/$notificationId/read'),
    );

    if (response.statusCode != 200) {
      throw Exception('Error marking notification as read');
    }
  }
}
