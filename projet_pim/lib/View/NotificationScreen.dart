import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/View/Event/EventDetailsScreen.dart';
import 'package:projet_pim/View/chat/chat_screen.dart';
import 'package:projet_pim/View/profile.dart';
import 'package:projet_pim/View/user_profile.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:projet_pim/ViewModel/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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

  final Map<String, IconData> notificationIcons = {
    'FOLLOW': Icons.person_add,
    'NEW_EVENT_All': Icons.event,
    'COMMENT': Icons.comment,
    'LIKE': Icons.thumb_up,
    'MESSAGE': Icons.message,
    'NEW_Event': Icons.calendar_today, // 🛠 Add this for trip reminder
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
      print('🔴 Error: $e');
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
      await _notificationService.markAsRead(notificationId);

      if (notification['type'] == 'NEW_EVENT_All') {
        final eventId = notification['data']?['eventId'] ?? '';
        if (eventId.isNotEmpty) {
          final event = await _fetchEventDetails(eventId);
          final isJoined = await _isUserJoined(eventId);

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
      } else if (notification['type'] == 'FOLLOW') {
        final followerId = notification['data']?['followerId'] ?? '';
        if (followerId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TravelerProfileScreen(
                travelerId: followerId,
                loggedInUserId: widget.userId,
                token: _token!,
              ),
            ),
          );
        }
      } else if (notification['type'] == 'MESSAGE') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              eventProvider: EventProvider(userId: _userId!),
              token: _token!,
              userId: widget.userId,
              conversationId: notification['data']?['conversationId'] ?? '',
            ),
          ),
        );
      } else if (notification['type'] == 'NEW_Event') {
        // 🟢 Trip reminder notification clicked
        final tripId = notification['data']?['tripId'] ?? '';
        final destination = notification['message']
            .toString()
            .split('to ')
            .last
            .split(' starts')
            .first;

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Trip Reminder'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Get ready for your trip!'),
                const SizedBox(height: 8),
                Text('Destination: $destination',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('🔴 Error handling notification: $e');
    }
  }

  Future<bool> _isUserJoined(String eventId) async {
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

  Future<Event> _fetchEventDetails(String eventId) async {
    final response =
        await http.get(Uri.parse('${ApiConstants.baseUrl}/events/$eventId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final eventData = data['data'] ?? data;
      return Event.fromJson(eventData, _userId!);
    } else {
      throw Exception('Error fetching event details');
    }
  }

  String formatDate(String dateString) {
    final dateTime = DateTime.parse(dateString);
    return DateFormat('HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text("No notifications yet"))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final iconType = notificationIcons[notification['type']] ??
                        Icons.notifications;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      elevation: 5,
                      child: ListTile(
                        onTap: () => _handleNotificationTap(
                            notification['_id'], notification),
                        leading: Icon(iconType, color: Colors.blue),
                        title: Text(notification['message'],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          formatDate(notification['createdAt']),
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: !notification['isRead']
                            ? const Icon(Icons.circle,
                                color: Colors.blue, size: 10)
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
