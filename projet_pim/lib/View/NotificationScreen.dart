import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/View/Event/EventDetailsScreen.dart';
import 'package:projet_pim/View/chat/chat_screen.dart';
import 'package:projet_pim/View/home_screen.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:projet_pim/ViewModel/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;

  NotificationScreen({required this.userId});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  late EventProvider _eventProvider;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _userId;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadUserSession();
    _fetchInitialNotifications();
    _setupWebSocket();
  }

  // 🟢 Charger la session utilisateur depuis SharedPreferences
  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString("user_id");
      _token = prefs.getString("jwt_token");
      if (_userId != null) {
        _eventProvider = EventProvider(userId: _userId!);
      }
    });
  }

  // 🟢 Récupérer les notifications initiales depuis l'API
  Future<void> _fetchInitialNotifications() async {
    try {
      final notifications = await _notificationService.fetchNotifications(widget.userId);
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur: $e');
      setState(() => _isLoading = false);
    }
  }

  // 🟢 Configurer le WebSocket
  void _setupWebSocket() {
    _notificationService.connect(widget.userId);
    _notificationService.listenToNotifications((newNotification) {
      setState(() {
        _notifications.insert(0, newNotification);
      });
    });
  }

  // 🟢 Récupérer les détails d'un événement
  Future<Event> _fetchEventDetails(String placeId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/events/$placeId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Event.fromJson(data['data'], _userId!);
      } else {
        throw Exception('Erreur lors de la récupération des détails de l\'événement');
      }
    } catch (e) {
      print('Erreur: $e');
      throw e;
    }
  }

  // 🟢 Gérer le clic sur une notification
  Future<void> _handleNotificationTap(String notificationId, Map<String, dynamic> notification) async {
    try {
      await _notificationService.markAsRead(notificationId);

      if (notification['type'] == 'MESSAGE') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: notification['data']['conversationId'],
            ),
          ),
        );
      } else if (notification['type'] == 'NEW_PLACE') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FutureBuilder<Event>(
              future: _fetchEventDetails(notification['data']['placeId']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return Scaffold(
                    body: Center(child: Text("Erreur lors du chargement de l'événement")),
                  );
                } else if (snapshot.hasData) {
                  return EventDetailsScreen(
                    event: snapshot.data!,
                    userId: _userId!,
                    token: _token!,
                    eventProvider: _eventProvider,
                  );
                } else {
                  return Scaffold(
                    body: Center(child: Text("Événement introuvable")),
                  );
                }
              },
            ),
          ),
        );
      } else if (notification['type'] == 'INVITATION') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(userId: _userId!),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors du traitement de la notification: $e');
    }
  }

  @override
  void dispose() {
    _notificationService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(child: Text("Aucune notification pour le moment"))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return ListTile(
                      onTap: () => _handleNotificationTap(notification['_id'], notification),
                      leading: Icon(Icons.notifications),
                      title: Text(notification['message']),
                      subtitle: Text(notification['createdAt']),
                      trailing: !notification['isRead']
                          ? Icon(Icons.circle, color: Colors.blue, size: 10)
                          : null,
                    );
                  },
                ),
    );
  }
}
