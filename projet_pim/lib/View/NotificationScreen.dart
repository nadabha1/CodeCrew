import 'package:flutter/material.dart';
import 'package:projet_pim/ViewModel/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;

  NotificationScreen({required this.userId});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialNotifications();
    _setupWebSocket(); // 🟢 Configurer le WebSocket
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
        _notifications.insert(0, newNotification); // Ajouter la nouvelle notification en haut
      });
    });
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
  leading: Icon(Icons.notifications),
  title: Text(
    notification['message'].toString().replaceAll(
        notification['sender'].toString(),
        notification['sender']['name'] ?? 'Utilisateur inconnu'), // 🟢 Remplace l'ID par le nom
  ),
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
