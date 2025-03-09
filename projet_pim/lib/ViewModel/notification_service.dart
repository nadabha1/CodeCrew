import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class NotificationService {
  final IO.Socket _socket = IO.io('${ApiConstants.baseUrl}', <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
  });

  // 🟢 Connexion au WebSocket
  void connect(String userId) {
    _socket.connect();
    _socket.onConnect((_) {
      print('⚡ Connecté au WebSocket');
      _socket.emit('join', userId); // Rejoindre la room utilisateur
    });
  }

  // 🟢 Écouter les nouvelles notifications
  void listenToNotifications(Function(Map<String, dynamic>) onNotificationReceived) {
    _socket.on('newNotification', (data) {
      print('📢 Nouvelle notification reçue: $data');
      onNotificationReceived(data);
    });
  }

  // 🟢 Fermer la connexion
  void disconnect() {
    _socket.disconnect();
  }

  // 🟢 Récupérer les notifications depuis l'API
Future<List<Map<String, dynamic>>> fetchNotifications(String userId) async {
  final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/notifications/$userId'));

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['data']); // 🟢 Corriger ici
  } else {
    print('Erreur: ${response.body}');
    throw Exception('Erreur lors de la récupération des notifications');
  }
}

    Future<int> getUnreadNotificationsCount(String userId) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/notifications/unread-count/$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['unreadCount'] ?? 0;
    } else {
      print('Erreur lors de la récupération des notifications non lues');
      return 0; // Retourne 0 en cas d'erreur
    }
  }
}
