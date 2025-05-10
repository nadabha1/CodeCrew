import 'dart:convert';

import 'package:device_calendar/device_calendar.dart' as DeviceCalendar;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/View/Event/EventDetailsScreen.dart';
import 'package:projet_pim/View/chat/group_chat_screen.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projet_pim/ViewModel/calendar_service.dart';
import 'package:projet_pim/Model/event.dart' as CustomEvent;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart'; // Add this import
import 'package:projet_pim/ViewModel/activityLoggerService.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart'; // Add this import for reverse geocoding

class CalendarEventsScreen extends StatefulWidget {
  final String userId;
  final String token;
  const CalendarEventsScreen(
      {Key? key, required this.userId, required this.token})
      : super(key: key);
  @override
  _CalendarEventsScreenState createState() => _CalendarEventsScreenState();
}

class _CalendarEventsScreenState extends State<CalendarEventsScreen>
    with TickerProviderStateMixin {
  late DeviceCalendar.DeviceCalendarPlugin _deviceCalendarPlugin;
  late EventProvider _eventProvider;
  final CalendarService _calendarService = CalendarService();
  List<DeviceCalendar.Event> _events = [];
  List<Event> _event = [];
  List<Event> _filteredEvents = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  String _selectedSort = 'date';
  List<Map<String, String>> _freeSlots = [];
  String? userId;
  String? token;
  bool isLoading = true;
  List<CustomEvent.Event> _nonConflictingEvents = [];
  List<CustomEvent.Event> _displayedEvents = [];
  final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm'); // Formatter
  DateTime? _selectedDay;
  List<CustomEvent.Event> _selectedDayEvents = [];
  DateTime _focusedDay = DateTime.now(); // Jour affiché
  LatLng? _currentLocation;
  String? _locationName; // Add this to store the location name
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    initializeDateFormatting('fr_FR'); // Initialize locale data for French
    _deviceCalendarPlugin = DeviceCalendar.DeviceCalendarPlugin();
    _loadUserData();
    _getUserLocation();
    _eventProvider = EventProvider(userId: widget.userId);
    _fetchAllEvents();
    _displayedEvents = []; // Initially empty, will be set after fetching events
  }

  void _resetFilters() {
    if (!mounted) return;
    setState(() {
      _searchController.clear();
      _selectedDay = null;
      _filteredEvents = _event;
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? _userId = prefs.getString("user_id");
    String? _token = prefs.getString("jwt_token");

    if (_userId != null && _token != null && _isValidUserId(_userId)) {
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationName = "Location services are disabled. Please enable them.";
      });
      print("Error: Location services are disabled.");
      return;
    }

    // Check and request location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationName =
              "Location permissions are permanently denied. Please enable them in settings.";
        });
        print("Error: Location permissions are permanently denied.");
        return;
      } else if (permission == LocationPermission.denied) {
        setState(() {
          _locationName =
              "Location permissions are denied. Please allow access.";
        });
        print("Error: Location permissions are denied.");
        return;
      }
    }

    try {
      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocoding to get the location name
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _locationName = "${place.locality}, ${place.country}";
        });
        print("Location fetched successfully: $_locationName");
      } else {
        setState(() {
          _locationName = "Unable to determine location.";
        });
        print("Error: Reverse geocoding returned no results.");
      }
    } catch (e) {
      print("Error in getting location: $e");
      if (e.toString().contains("Failed host lookup")) {
        setState(() {
          _locationName = "No internet connection. Please check your network.";
        });
      } else {
        setState(() {
          _locationName = "Error fetching location.";
        });
      }
    }
  }

  Future<void> _requestPermission() async {
    try {
      // Demander le full access calendrier (Android 14+)
      var status = await Permission.calendarFullAccess.status;
      if (!status.isGranted) {
        status = await Permission.calendarFullAccess.request();
        if (!status.isGranted) {
          print('Permission calendrier non accordée (calendarFullAccess)');
          return;
        }
      }

      // Ensuite, vérifier via device_calendar
      var hasPermissions = await _deviceCalendarPlugin.hasPermissions();
      print(
          "hasPermissions result: ${hasPermissions.isSuccess}, ${hasPermissions.data}");

      if (!hasPermissions.isSuccess || hasPermissions.data == false) {
        var permissionResponse =
            await _deviceCalendarPlugin.requestPermissions();
        print(
            "requestPermissions result: ${permissionResponse.isSuccess}, ${permissionResponse.data}");

        if (permissionResponse.isSuccess && permissionResponse.data!) {
          _getCalendarEvents();
        } else {
          print('Permission non accordée via device_calendar');
        }
      } else {
        _getCalendarEvents();
      }
    } catch (e) {
      print('Erreur lors de la demande de permission: $e');
    }
  }

  bool _isValidUserId(String userId) {
    final regex = RegExp(r'^[a-fA-F0-9]{24}$');
    return regex.hasMatch(userId);
  }

  Future<void> _getCalendarEvents() async {
    try {
      if (!_isValidUserId(userId!)) return;

      var calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data != null) {
        var calendar = calendarsResult.data!.first;
        var startDate = DateTime.now();
        var endDate = startDate.add(Duration(days: 30));

        var eventsResult = await _deviceCalendarPlugin.retrieveEvents(
          calendar.id,
          DeviceCalendar.RetrieveEventsParams(
              startDate: startDate, endDate: endDate),
        );

        if (eventsResult.isSuccess && eventsResult.data != null) {
          if (!mounted) return;
          setState(() {
            _events = List.from(eventsResult.data!);
            _freeSlots = _getFreeSlots(_events);
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
        if (!mounted) return;
        setState(() {
          _nonConflictingEvents =
              _eventProvider.events.cast<CustomEvent.Event>();
          _displayedEvents = _nonConflictingEvents; // Display all initially
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

    // S’il n’y a aucun événement, toute la période est libre
    if (events.isEmpty) {
      freeSlots.add({
        'start': startOfDay.toIso8601String(),
        'end': endOfDay.toIso8601String(),
      });
      return freeSlots;
    }

    // Sinon, calcul des créneaux libres entre les événements
    events.sort((a, b) => a.start!.compareTo(b.start!));

    if (events.first.start!.isAfter(startOfDay)) {
      freeSlots.add({
        'start': startOfDay.toIso8601String(),
        'end': events.first.start!.toIso8601String(),
      });
    }

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

    if (events.last.end!.isBefore(endOfDay)) {
      freeSlots.add({
        'start': events.last.end!.toIso8601String(),
        'end': endOfDay.toIso8601String(),
      });
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
    return 'Are you free on $dayName $partOfDay ?  Here are  $eventCount interesting events nearby.';
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  String _getPartOfDay(DateTime time) {
    final hour = time.hour;
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'evening';
  }

  Widget _buildDeviceEventsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 150, // Ajustez la hauteur en fonction de votre besoin
          width: double.infinity,
          padding: EdgeInsets.all(8), // Ajoutez un padding autour du calendrier
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat:
                CalendarFormat.week, // Affiche uniquement la semaine
            onDaySelected: (selectedDay, focusedDay) {
              if (!mounted) return;
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _displayedEvents = _nonConflictingEvents.where((event) {
                  return event.startDate.year == selectedDay.year &&
                      event.startDate.month == selectedDay.month &&
                      event.startDate.day == selectedDay.day;
                }).toList();
              });
            },
            calendarBuilders: CalendarBuilders(
              selectedBuilder: (context, date, _) {
                return Container(
                  margin: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                        255, 248, 202, 239), // Couleur personnalisée
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(color: Colors.white), // Texte en blanc
                  ),
                );
              },
              markerBuilder: (context, day, events) {
                // Si des événements existent pour ce jour, afficher un point rouge
                if (events.isNotEmpty) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red, // Point rouge
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayedEvents() {
    if (_displayedEvents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "No events match your available time on this day.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16.0), // Add padding to shift right
      child: Column(
        children: _displayedEvents
            .map((event) => _buildStyledEventCard(event))
            .toList(),
      ),
    );
  }

  List<CustomEvent.Event> _getEventsInFreeSlots() {
    List<CustomEvent.Event> matchingEvents = [];

    for (var event in _nonConflictingEvents) {
      for (var slot in _freeSlots) {
        DateTime slotStart = DateTime.parse(slot['start']!);
        DateTime slotEnd = DateTime.parse(slot['end']!);

        if (event.startDate.isAfter(slotStart) &&
            event.startDate.isBefore(slotEnd)) {
          matchingEvents.add(event);
          break; // Pas besoin de continuer à vérifier les autres slots
        }
      }
    }

    return matchingEvents;
  }

  Widget _buildFreeSlotMessages() {
    // Définir une distance maximale (par exemple 1000 mètres)
    const double maxDistance = 1000.0;

    final eventsInFreeSlots = _getEventsInFreeSlots();

    if (eventsInFreeSlots.isEmpty) return SizedBox.shrink();

    List<Widget> messagesAndEvents = [];

    for (var event in eventsInFreeSlots) {
      // Vérifier la proximité de l'événement
      bool isNearby = false;
      if (event.location != null && _currentLocation != null) {
        final distance = Geolocator.distanceBetween(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          event.location.latitude,
          event.location.longitude,
        );
        isNearby = distance <= maxDistance; // Vérifie si l'événement est proche
      }

      // Si l'événement est proche, on l'ajoute à la liste
      if (isNearby) {
        final slot = _freeSlots.firstWhere(
          (slot) =>
              event.startDate.isAfter(DateTime.parse(slot['start']!)) &&
              event.startDate.isBefore(DateTime.parse(slot['end']!)),
          orElse: () => {'start': '', 'end': ''},
        );

        // Phrase générée
        messagesAndEvents.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text(
              generateFreeSlotMessage([slot], 1),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        );

        // Événement associé
        messagesAndEvents.add(_buildStyledEventCard(event));
      }
    }

    return Column(children: messagesAndEvents);
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    await _getCalendarEvents();
    await _fetchNonConflictingEvents();
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Widget _buildHorizontalCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        if (!mounted) return;
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
          _filterByDate(selectedDay);
        });
      },
      calendarFormat: CalendarFormat.week,
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.deepPurple,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: const Color.fromARGB(255, 248, 202, 239),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  void _filterByDate(DateTime date) {
    if (!mounted) return;
    setState(() {
      _filteredEvents = _event.where((event) {
        return event.startDate.year == date.year &&
            event.startDate.month == date.month &&
            event.startDate.day == date.day;
      }).toList();
    });
  }

  _filterEvents(String query) async {
    final lowerQuery = query.toLowerCase();
    if (!mounted) return;
    setState(() {
      _filteredEvents = _event.where((event) {
        final titleMatch = event.title.toLowerCase().contains(lowerQuery);
        final participantMatch = event.participants.any((p) {
          final name = p['name'];
          return name.toLowerCase().contains(lowerQuery);
        });
        return titleMatch || participantMatch;
      }).toList();
      _sortEvents();
    });
  }

  void _sortEvents() {
    if (_selectedSort == 'date') {
      _filteredEvents.sort((a, b) => a.startDate.compareTo(b.startDate));
    }
  }

  Future<void> _fetchAllEvents() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/events/all'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _event =
              data.map((json) => Event.fromJson(json, widget.userId)).toList();
          _filteredEvents = _event;
          _sortEvents();
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        print('🔴 Erreur: ${response.body}');
      }
    } catch (e) {
      print('🔴 Exception: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _showJoinConfirmationDialog(Event event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Ready to Join?"),
          content:
              Text("It’s just ${event.joinPrice} coins to join the event!"),
          actions: [
            TextButton(
              onPressed: () {
                if (!mounted) return; // Ensure widget is still mounted
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (!mounted) return; // Ensure widget is still mounted
                Navigator.of(context).pop(); // Close dialog first
                try {
                  await _eventProvider.joinEvent(widget.userId, event.id);
                  if (!mounted) return; // Ensure widget is still mounted

                  // Show success popup
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("You're In!"),
                        content: const Text("You're part of the event now! 🙌"),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("OK"),
                          ),
                        ],
                      );
                    },
                  );

                  // Refresh the data to update the UI
                  await _fetchNonConflictingEvents();
                  await _fetchAllEvents();
                  setState(() {}); // Trigger UI rebuild
                } catch (e, stackTrace) {
                  // Log the full error and stack trace
                  print("❌ Error joining event: $e");
                  print("Stack trace: $stackTrace");

                  // Handle specific error scenarios
                  final error = e.toString();
                  if (error.contains("Insufficient coins")) {
                    if (!mounted) return; // Ensure widget is still mounted
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("A Little Short on Coins!"),
                          content: const Text(
                              "Oops, not enough coins to join this event."),
                          actions: [
                            TextButton(
                              child: const Text("OK"),
                              onPressed: () {
                                if (!mounted)
                                  return; // Ensure widget is still mounted
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  } else if (error.contains("Network")) {
                    if (!mounted) return; // Ensure widget is still mounted
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "❌ Network error. Please check your connection.")),
                    );
                  } else {
                    // Generic fallback for unknown errors
                    if (!mounted) return; // Ensure widget is still mounted
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("❌ Unknown error: $error")),
                    );
                  }
                }
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  TextEditingController searchController = TextEditingController();

  void onSearch(String keyword) {
    if (keyword.isNotEmpty) {
      ActivityLoggerService.logAction(
        userId: widget.userId,
        type: "search event",
        value: keyword,
      );
    }
  }

  Widget _buildUserLocation() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text(
              _locationName ?? "Fetching your location...",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getEventLocationName(LatLng location) async {
    try {
      // Validate coordinates
      if (location.latitude == 0.0 && location.longitude == 0.0) {
        return "Invalid coordinates";
      }

      // Use reverse geocoding to fetch the location name
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.locality}, ${place.country}"; // Return the locality and country
      } else {
        return "No location found";
      }
    } catch (e) {
      print("Error in reverse geocoding for event: $e");
      if (e.toString().contains("Failed host lookup")) {
        return "No internet connection";
      }
      return "Unknown location"; // Fallback if reverse geocoding fails
    }
  }

  Widget _buildStyledEventCard(Event event) {
    bool isParticipating = event.isParticipating;
    return FutureBuilder<String>(
      future:
          _getEventLocationName(event.location), // Fetch event location name
      builder: (context, snapshot) {
        String locationName = snapshot.data ?? "Fetching location...";
        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Color(0xFF161055), width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: 400,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF161055),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  event.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Color(0xFF161055)),
                ),
                SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: Color(0xFF161055)),
                  SizedBox(width: 6),
                  Text(
                    event.startDate.toString().split(" ")[0],
                    style: TextStyle(fontSize: 12, color: Color(0xFF161055)),
                  ),
                ]),
                SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.location_on, size: 14, color: Color(0xFF161055)),
                  SizedBox(width: 6),
                  Text(
                    locationName, // Display the fetched location name
                    style: TextStyle(fontSize: 12, color: Color(0xFF161055)),
                  ),
                ]),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (isParticipating) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GroupChatScreen(
                                eventProvider:
                                    EventProvider(userId: widget.userId),
                                conversationId: event.conversationId ?? "",
                                groupName: event.title,
                                userId: widget.userId,
                              ),
                            ),
                          );
                        } else {
                          _showJoinConfirmationDialog(event);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isParticipating
                            ? Color(0xFF9680D4)
                            : Color.fromARGB(198, 243, 199, 249),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isParticipating ? "Join Chat" : "Join Event"),
                    ),
                    IconButton(
                      icon: Icon(Icons.more_horiz, color: Color(0xFF161055)),
                      onPressed: () {
                        if (isParticipating) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailsScreen(
                                event: event,
                                userId: widget.userId,
                                token: widget.token,
                                eventProvider:
                                    EventProvider(userId: widget.userId),
                              ),
                            ),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (_) => const AlertDialog(
                              title: Text("Access Denied"),
                              content: Text(
                                  "Want the inside scoop? Join the event first!"),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Event> recentEvents = _filteredEvents
        .where((e) => e.startDate.isBefore(DateTime.now()))
        .toList();
    List<Event> upcomingEvents = _filteredEvents
        .where((e) => e.startDate.isAfter(DateTime.now()))
        .toList();

    return Scaffold(
      backgroundColor: Color(0xFFF7F4FC),
      appBar: AppBar(
        backgroundColor: Color(0xFFDBD9FE),
        title: Text("All Events"),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Calendar"),
            Tab(text: "All Events"),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Affichage du calendrier et des événements dans l'onglet "Calendrier"
                Scaffold(
                  body: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildUserLocation(), // Centered user location
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Your Weekly Schedule', // Texte en haut
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.refresh),
                                    onPressed:
                                        _refreshData, // Fonction de rafraîchissement des données
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.my_location),
                                    onPressed:
                                        _getUserLocation, // Fonction pour obtenir la localisation de l'utilisateur
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Display user location
                        // Affichage du contenu de la page
                        _isLoading
                            ? Center(child: CircularProgressIndicator())
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDeviceEventsList(),
                                  // Liste des événements de l'appareil
                                  SizedBox(height: 20),
                                  _buildDisplayedEvents(), // Display events shifted to the right
                                  // Messages concernant les créneaux horaires libres
                                  SizedBox(height: 20),
                                  // _buildFreeSlotsList(), // Liste des créneaux horaires libres (optionnel)
                                  SizedBox(height: 20),
                                  // _buildNonConflictingEventList(), // Liste des événements sans conflits (optionnel)
                                ],
                              ),
                      ],
                    ),
                  ),
                ),

                // Affichage des événements dans l'onglet "Tous les événements"
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Column(
                    children: [
                      // Champ de recherche pour filtrer les événements
                      TextField(
                        controller: _searchController,
                        onChanged: _filterEvents,
                        onSubmitted: onSearch,
                        decoration: InputDecoration(
                          hintText: 'Search by title or participant...',
                          prefixIcon: Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      // Affichage du calendrier en haut de la liste des événements
                      SizedBox(height: 20),
                      _buildHorizontalCalendar(), // Ajout du calendrier

                      if (_selectedDay != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _resetFilters,
                            icon: Icon(Icons.refresh, color: Colors.deepPurple),
                            label: Text("Reset",
                                style: TextStyle(color: Colors.deepPurple)),
                          ),
                        ),
                      SizedBox(height: 10),
                      // Liste des événements filtrés
                      Expanded(
                        child: ListView(
                          children: [
                            if (recentEvents.isNotEmpty) ...[
                              Text(" Recent events",
                                  style: sectionStyle.copyWith(
                                      color: Color(0xFF161055))),
                              ...recentEvents.map(_buildStyledEventCard),
                              Divider(thickness: 1.5),
                            ],
                            if (upcomingEvents.isNotEmpty) ...[
                              Text("Upcoming",
                                  style: sectionStyle.copyWith(
                                      color: Color(0xFF161055))),
                              ...upcomingEvents.map(_buildStyledEventCard),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  final sectionStyle = TextStyle(
      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple);
}
