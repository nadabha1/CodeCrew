import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart' as DeviceCalendar;
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projet_pim/ViewModel/calendar_service.dart';
import 'package:projet_pim/Model/event.dart' as CustomEvent;

class CalendarEventsScreen extends StatefulWidget {
  @override
  _CalendarEventsScreenState createState() => _CalendarEventsScreenState();
}

class _CalendarEventsScreenState extends State<CalendarEventsScreen> {
  late DeviceCalendar.DeviceCalendarPlugin _deviceCalendarPlugin;
  late EventProvider _eventProvider;
  final CalendarService _calendarService = CalendarService();
  List<DeviceCalendar.Event> _events = [];
  List<Map<String, String>> _freeSlots = [];
  String? userId;
  String? token;
  bool isLoading = true;
  List<dynamic> _eventsDuringFreeTime = [];
  List<CustomEvent.Event> _nonConflictingEvents = [];

  @override
  void initState() {
    super.initState();
    _deviceCalendarPlugin = DeviceCalendar.DeviceCalendarPlugin();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? _userId = prefs.getString("user_id");
    String? _token = prefs.getString("jwt_token");

    if (_userId != null && _token != null && _isValidUserId(_userId)) {
      setState(() {
        userId = _userId;
        token = _token;
        isLoading = false;
      });
      _eventProvider = EventProvider(userId: _userId);
      _requestPermission();
      await _fetchNonConflictingEvents();
    } else {
      print("Invalid userId or Token not available");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    try {
      var hasPermissions = await _deviceCalendarPlugin.hasPermissions();
      if (!hasPermissions.isSuccess || hasPermissions.data == false) {
        var permissionResponse =
            await _deviceCalendarPlugin.requestPermissions();
        if (permissionResponse.isSuccess && permissionResponse.data!) {
          _getCalendarEvents();
        } else {
          print('Permission not granted');
        }
      } else {
        _getCalendarEvents();
      }
    } catch (e) {
      print('Error requesting permission: $e');
    }
  }

  bool _isValidUserId(String userId) {
    final regex = RegExp(r'^[a-fA-F0-9]{24}$');
    return regex.hasMatch(userId);
  }

  Future<void> _getCalendarEvents() async {
    try {
      if (!_isValidUserId(userId!)) {
        print('Invalid userId format');
        return;
      }

      var calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data != null) {
        var calendar = calendarsResult.data!.first;

        var startDate = DateTime.now();
        var endDate = startDate.add(Duration(days: 30));

        var params = DeviceCalendar.RetrieveEventsParams(
            startDate: startDate, endDate: endDate);
        var eventsResult =
            await _deviceCalendarPlugin.retrieveEvents(calendar.id, params);

        if (eventsResult.isSuccess && eventsResult.data != null) {
          setState(() {
            _events = List.from(eventsResult.data!);
          });

          var formattedEvents = _events.map((event) {
            return {
              'title': event.title,
              'start': event.start?.toIso8601String(),
              'end': event.end?.toIso8601String(),
              'location': event.location ?? '',
              'description': event.description ?? ''
            };
          }).toList();

          if (userId != null && token != null) {
            await _calendarService.sendUserEventsToBackend(
                userId!, token!, formattedEvents);
          }
        }
      }
    } catch (e) {
      print('Error retrieving calendar events: $e');
    }
  }

  Future<void> _fetchNonConflictingEvents() async {
    try {
      if (userId != null) {
        await _eventProvider.getNonConflictingEvents(userId!);
        setState(() {
          _nonConflictingEvents = _eventProvider.events
              .cast<CustomEvent.Event>(); // Cast to custom Event type
        });
      }
    } catch (e) {
      print('Error fetching non-conflicting events: $e');
    }
  }

  List<Map<String, String>> _getFreeSlots(List<DeviceCalendar.Event> events) {
    List<Map<String, String>> freeSlots = [];
    DateTime startOfDay = DateTime.now();
    DateTime endOfDay = DateTime.now().add(Duration(days: 30));
    _freeSlots = _calendarService.getFreeSlots(_events);

    if (events.isNotEmpty) {
      events.sort((a, b) => a.start!.compareTo(b.start!));

      // Check time before the first event
      if (events.first.start!.isAfter(startOfDay)) {
        freeSlots.add({
          'start': startOfDay.toIso8601String(),
          'end': events.first.start!.toIso8601String(),
        });
      }

      // Check for gaps between events
      for (int i = 0; i < events.length - 1; i++) {
        DateTime eventEnd = events[i].end!;
        DateTime nextEventStart = events[i + 1].start!;

        if (eventEnd.isBefore(nextEventStart)) {
          freeSlots.add({
            'start': eventEnd.toIso8601String(),
            'end': nextEventStart.toIso8601String(),
          });
        }
      }

      // Check time after the last event
      if (events.last.end!.isBefore(endOfDay)) {
        freeSlots.add({
          'start': events.last.end!.toIso8601String(),
          'end': endOfDay.toIso8601String(),
        });
      }
    }

    return freeSlots;
  }

  String generateFreeSlotMessage(
      List<Map<String, String>> slots, int eventCount) {
    if (slots.isEmpty || eventCount == 0) return '';

    final slot = slots.first;
    final start = DateTime.parse(slot['start']!).toLocal();
    final dayName = _getDayName(start.weekday);
    final partOfDay = _getPartOfDay(start);

    return 'Vous êtes libre le $dayName $partOfDay ? Voici $eventCount événements intéressants à proximité.';
  }

  String _getDayName(int weekday) {
    const days = [
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche'
    ];
    return days[weekday - 1];
  }

  String _getPartOfDay(DateTime time) {
    final hour = time.hour;
    if (hour < 12) return 'matin';
    if (hour < 18) return 'après-midi';
    return 'soir';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Calendar Events')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📅 Upcoming Events',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      return ListTile(
                        leading: Icon(Icons.event),
                        title: Text(event.title ?? 'No title'),
                        subtitle: Text(
                            '${event.start?.toLocal()} - ${event.end?.toLocal()}'),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  Text('🕒 Available Time Slots',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _freeSlots.isEmpty
                      ? Text("No available time slots detected")
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _freeSlots.length,
                          itemBuilder: (context, index) {
                            final slot = _freeSlots[index];
                            return ListTile(
                              leading: Icon(Icons.schedule),
                              title: Text(
                                  '${DateTime.parse(slot['start']!).toLocal()}'),
                              subtitle: Text(
                                  '→ ${DateTime.parse(slot['end']!).toLocal()}'),
                            );
                          },
                        ),
                  SizedBox(height: 20),
                  if (_eventsDuringFreeTime.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          generateFreeSlotMessage(
                              _freeSlots, _eventsDuringFreeTime.length),
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  _eventsDuringFreeTime.isEmpty
                      ? Text("No events during your free time yet")
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _eventsDuringFreeTime.length,
                          itemBuilder: (context, index) {
                            final event = _eventsDuringFreeTime[index];
                            return ListTile(
                              leading: Icon(Icons.event),
                              title: Text(event['title']),
                              subtitle: Text(event['description']),
                            );
                          },
                        ),
                  SizedBox(height: 20),
                  if (_nonConflictingEvents.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎉 Non-conflicting Events',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Ces événements ne sont pas en conflit avec vos événements existants.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  _nonConflictingEvents.isEmpty
                      ? Text("No non-conflicting events found")
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _nonConflictingEvents.length,
                          itemBuilder: (context, index) {
                            final event = _nonConflictingEvents[index];
                            final eventStart = event
                                .startDate; // Assuming `event` has start and end properties
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vous êtes libre le ${eventStart?.toLocal()}  '
                                  'On vous propose de participer à cet événement :',
                                  style: TextStyle(fontSize: 16),
                                ),
                                ListTile(
                                  leading: Icon(Icons.event),
                                  title: Text(event.title ?? 'No title'),
                                  subtitle: Text(
                                      event.description ?? 'No description'),
                                ),
                                SizedBox(height: 10),
                              ],
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
