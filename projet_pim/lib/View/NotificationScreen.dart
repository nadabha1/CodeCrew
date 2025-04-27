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
import 'package:intl/intl.dart'; // Import the intl package for date formatting

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

  // 🟢 Icons for each notification type
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
      print("🟢 Notification ID: $notificationId");
      print("🟢 Notification Type: ${notification['type']}");
      await _notificationService.markAsRead(notificationId);

      if (notification['type'].trim() == 'NEW_EVENT_All') {
        final eventId = notification['data']?['eventId'] ?? '';
        print("🟢 Event ID found: $eventId");

        if (eventId.isNotEmpty) {
          final event = await _fetchEventDetails(eventId);
          final isJoined = await _isUserJoined(eventId);

          print("🟢 User has joined: $isJoined");

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text("New Event: ${event.title}"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(event.description),
                  SizedBox(height: 10),
                  Text("Location: ${event.location}"),
                  Text("Date: ${event.startDate.toLocal()}".split(' ')[0]),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close"),
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
                      ? "See more"
                      : "Join - ${event.joinPrice} Coins"),
                ),
              ],
            ),
          );
        }
      } else if (notification['type'] == 'FOLLOW') {
        final followerId = notification['data']?['followerId'] ?? '';
        print("🟢 Follower ID: $followerId");

        if (followerId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TravelerProfileScreen(
                travelerId: followerId,
                loggedInUserId: widget.userId,
                token: '$_token',
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
              eventProvider: EventProvider(userId: _userId!),
              token: _token!,
              userId: widget.userId,
              conversationId: notification['data']?['conversationId'] ?? '',
            ),
          ),
        );
      } else if (notification['type'] == 'NEW_Event') {
        final eventId = notification['data']?['eventId'] ?? '';
        print("🟢 Event ID received: $eventId");

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
                    print("🔴 Error fetching event: ${snapshot.error}");
                    return Scaffold(
                      body: Center(child: Text("Error loading event")),
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
                      body: Center(child: Text("Event not found")),
                    );
                  }
                },
              ),
            ),
          );
        } else {
          print("🔴 No event ID found.");
        }
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

  void _showJoinConfirmationDialog(Event event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Join the event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Do you want to join the event "${event.title}"?'),
              SizedBox(height: 10),
              Text(
                'Join cost: ${event.joinPrice} coins',
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
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
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<Event> _fetchEventDetails(String eventId) async {
    final response =
        await http.get(Uri.parse('${ApiConstants.baseUrl}/events/$eventId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final eventData = data['data'] ?? data;
      return Event.fromJson(eventData, _userId!);
    } else {
      print("🔴 Failed to fetch event details: ${response.body}");
      throw Exception('Error fetching event details');
    }
  }

  String formatDate(String dateString) {
    final dateTime = DateTime.parse(dateString);
    return DateFormat('HH:mm').format(dateTime); // Format as 21:03
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notifications")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(child: Text("No notifications yet"))
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
                          formatDate(notification[
                              'createdAt']), // Format the date to show only time like '21:03'
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
