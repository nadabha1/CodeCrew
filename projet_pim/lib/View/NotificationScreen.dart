import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/View/Event/EventDetailsScreen.dart';
import 'package:projet_pim/View/chat/chat_screen.dart';
import 'package:projet_pim/View/profile.dart';
import 'package:projet_pim/View/user_profile.dart';
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

  // 🟢 Icônes spécifiques selon le type de notification
  final Map<String, IconData> notificationIcons = {
    'FOLLOW': Icons.person_add,
    'NEW_EVENT_All': Icons.event,
    'COMMENT': Icons.comment,
    'LIKE': Icons.thumb_up,
    'MESSAGE': Icons.message,
  };

  @override
  void initState() {
    super.initState();
    _loadUserSession();
    _fetchInitialNotifications();
    _setupWebSocket();
  }

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

  Future<void> _fetchInitialNotifications() async {
    try {
      final notifications =
          await _notificationService.fetchNotifications(widget.userId);
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('🔴 Erreur: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupWebSocket() {
    _notificationService.connect(widget.userId);
    _notificationService.listenToNotifications((newNotification) {
      setState(() {
        _notifications.insert(0, newNotification);
      });
    });
  }

  Future<void> _handleNotificationTap(
      String notificationId, Map<String, dynamic> notification) async {
    try {
      print("🟢 Notification ID: $notificationId");
      print("🟢 Notification Type: ${notification['type']}");
      await _notificationService.markAsRead(notificationId);

      if (notification['type'].trim() == 'NEW_EVENT_All') {
        final eventId = notification['data']?['eventId'] ?? '';
        print("🟢 Event ID trouvé: $eventId");

        if (eventId.isNotEmpty) {
          final event = await _fetchEventDetails(eventId);
          final isJoined = await _isUserJoined(eventId);

          print("🟢 Utilisateur a rejoint: $isJoined");

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text("Nouvel événement: ${event.title}"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(event.description),
                  SizedBox(height: 10),
                  Text("Lieu: ${event.location}"),
                  Text(
                      "Start Date: ${DateFormat('yyyy-MM-dd').format(event.startDate.toLocal())}")
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Fermer"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (!isJoined) {
                      _showJoinConfirmationDialog(event);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailsScreen(
                            event: event,
                            userId: _userId!,
                            token: _token!,
                            eventProvider: _eventProvider,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(isJoined
                      ? "Voir plus"
                      : "Rejoindre - ${event.joinPrice} Coins"),
                ),
              ],
            ),
          );
        }
      } else if (notification['type'] == 'FOLLOW') {
        // 🟢 Navigation spécifique pour le type FOLLOW
        final followerId = notification['data']?['followerId'] ?? '';
        print("🟢 Follower ID: $followerId");

        if (followerId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TravelerProfileScreen(
                travelerId: followerId,
                loggedInUserId: widget.userId,
              ),
            ),
          );
        }
      }
      if (notification['type'] == 'MESSAGE') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: notification['data']?['conversationId'] ?? '',
            ),
          ),
        );
      } else if (notification['type'] == 'NEW_Event') {
        final eventId = notification['data']?['eventId'] ?? '';
        print("🟢 ID de l'événement reçu: $eventId");

        if (eventId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FutureBuilder<Event>(
                future: _fetchEventDetails(eventId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError) {
                    print(
                        "🔴 Erreur lors de la récupération de l'événement: ${snapshot.error}");
                    return Scaffold(
                      body: Center(
                          child:
                              Text("Erreur lors du chargement de l'événement")),
                    );
                  } else if (snapshot.hasData) {
                    print("🟢 Événement récupéré avec succès !");
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
        } else {
          print("🔴 Aucune ID d'événement trouvée.");
        }
      }
    } catch (e) {
      print('🔴 Erreur lors du traitement de la notification: $e');
    }
  }

  Future<bool> _isUserJoined(String eventId) async {
    print("🟢 Checking if user joined event: $eventId");
    final response = await http.get(Uri.parse(
        '${ApiConstants.baseUrl}/events/$eventId/joined/${widget.userId}'));
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['joined'] == true;
    } else {
      print("🔴 Failed to check if user joined: ${response.body}");
      return false;
    }
  }

  void _showJoinConfirmationDialog(Event event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Rejoindre l\'événement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Voulez-vous rejoindre l\'événement "${event.title}" ?'),
              SizedBox(height: 10),
              Text(
                'Coût d\'inscription : ${event.joinPrice} coins',
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                Navigator.pop(context);
                await _eventProvider.joinEvent(widget.userId, event.id);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailsScreen(
                      event: event,
                      userId: _userId!,
                      token: _token!,
                      eventProvider: _eventProvider,
                    ),
                  ),
                );
              },
              child: Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }


  Future<Event> _fetchEventDetails(String eventId) async {
  print("🟢 Fetching event details for ID: $eventId");
  final response =
      await http.get(Uri.parse('${ApiConstants.baseUrl}/events/$eventId'));

  if (response.statusCode == 200) {
    print("🔍 Response body: ${response.body}");

    if (response.body.trim().isEmpty) {
      throw Exception('La réponse est vide');
    }

    final decoded = jsonDecode(response.body);
    final eventData = decoded is Map<String, dynamic> && decoded.containsKey('data')
        ? decoded['data']
        : decoded;

    return Event.fromJson(eventData, _userId!);
  } else {
    print("🔴 Failed to fetch event details: ${response.body}");
    throw Exception('Erreur lors de la récupération des détails de l\'événement');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notifications")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(child: Text("Aucune notification pour le moment"))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final iconType = notificationIcons[notification['type']] ??
                        Icons.notifications;

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      elevation: 5,
                      child: ListTile(
                        onTap: () => _handleNotificationTap(
                            notification['_id'], notification),
                        leading: Icon(iconType, color: Colors.blue),
                        title: Text(notification['message'],
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          notification['createdAt'],
                          style: TextStyle(color: Colors.grey),
                        ),
                        trailing: !notification['isRead']
                            ? Icon(Icons.circle, color: Colors.blue, size: 10)
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
