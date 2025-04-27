import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/View/Event/EventDetailsScreen.dart';
import 'package:projet_pim/View/chat/group_chat_screen.dart';
import 'package:projet_pim/ViewModel/activityLoggerService.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class AllEventsScreen extends StatefulWidget {
  final String userId;
  final String token;

  const AllEventsScreen({super.key, required this.userId, required this.token});

  @override
  _AllEventsScreenState createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  List<Event> _events = [];
  List<Event> _filteredEvents = [];
  bool _isLoading = true;
  late EventProvider _eventProvider;
  final TextEditingController _searchController = TextEditingController();
  final String _selectedSort = 'date';

DateTime _focusedDay = DateTime.now();
DateTime? _selectedDay;
void _resetFilters() {
  setState(() {
    _searchController.clear();
    _selectedDay = null;
    _filteredEvents = _events;
  });
}

Widget _buildHorizontalCalendar() {
  return TableCalendar(
    firstDay: DateTime.utc(2020, 1, 1),
    lastDay: DateTime.utc(2030, 12, 31),
    focusedDay: _focusedDay,
    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
    onDaySelected: (selectedDay, focusedDay) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _filterByDate(selectedDay);
      });
    },
    calendarFormat: CalendarFormat.week,
    startingDayOfWeek: StartingDayOfWeek.monday,
    headerStyle: const HeaderStyle(
      formatButtonVisible: false,
      titleCentered: true,
    ),
    calendarStyle: const CalendarStyle(
      todayDecoration: BoxDecoration(
        color: Colors.deepPurple,
        shape: BoxShape.circle,
      ),
      selectedDecoration: BoxDecoration(
        color: Colors.blueAccent,
        shape: BoxShape.circle,
      ),
    ),
  );
  
}
void _filterByDate(DateTime date) {
  setState(() {
    _filteredEvents = _events.where((event) {
      return event.startDate.year == date.year &&
             event.startDate.month == date.month &&
             event.startDate.day == date.day;
    }).toList();
  });
}

  @override
  void initState() {
    super.initState();
    _eventProvider = EventProvider(userId: widget.userId);
    _fetchAllEvents();
  }

  _filterEvents(String query) async {
    
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredEvents = _events.where((event) {
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
        setState(() {
          _events = data.map((json) => Event.fromJson(json, widget.userId)).toList();
          _filteredEvents = _events;
          _sortEvents();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        print('🔴 Erreur: ${response.body}');
      }
    } catch (e) {
      print('🔴 Exception: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showJoinConfirmationDialog(Event event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Rejoindre l'événement ?"),
          content: Text("Prix de participation : ${event.joinPrice} coins"),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Annuler")),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _eventProvider.joinEvent(widget.userId, event.id);
                await _fetchAllEvents();
              },
              child: const Text("Confirmer"),
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


  Widget _buildStyledEventCard(Event event) {
    bool isParticipating = event.isParticipating;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(event.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.calendar_today, size: 14),
              const SizedBox(width: 6),
              Text(event.startDate.toString().split(" ")[0], style: const TextStyle(fontSize: 12)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on, size: 14),
              const SizedBox(width: 6),
Text(
  '${event.location.latitude.toStringAsFixed(4)}, ${event.location.longitude.toStringAsFixed(4)}',
  style: const TextStyle(fontSize: 12),
),
            ]),
            const SizedBox(height: 10),
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
                                                              eventProvider: EventProvider(userId: widget.userId),

                            conversationId: event.conversationId ?? "",
                            groupName: event.title,
                          ),
                        ),
                      );
                    } else {
                      _showJoinConfirmationDialog(event);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isParticipating ? Colors.green : Colors.deepOrange,
                  ),
                  child: Text(isParticipating ? "Rejoindre le Chat" : "Rejoindre"),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailsScreen(
                          event: event,
                          userId: widget.userId,
                          token: widget.token,
                          eventProvider: _eventProvider,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

 
  

  @override
  Widget build(BuildContext context) {
    List<Event> recentEvents = _filteredEvents.where((e) => e.startDate.isBefore(DateTime.now())).toList();
    List<Event> upcomingEvents = _filteredEvents.where((e) => e.startDate.isAfter(DateTime.now())).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDBD9FE),
        title: const Text("Tous les événements"),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _filterEvents,
                    onSubmitted: onSearch,
                      decoration: InputDecoration(
                      hintText: 'Rechercher par titre ou participant...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                      _buildHorizontalCalendar(), // 👈 Ajoute ce widget
                  if (_selectedDay != null)
  Align(
    alignment: Alignment.centerRight,
    child: TextButton.icon(
      onPressed: _resetFilters,
      icon: const Icon(Icons.refresh, color: Colors.deepPurple),
      label: const Text("Réinitialiser", style: TextStyle(color: Colors.deepPurple)),
    ),
  ),

                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      children: [
                        if (recentEvents.isNotEmpty) ...[
                          Text("\u{1F4C5} Événements récents", style: sectionStyle),
                          ...recentEvents.map(_buildStyledEventCard),
                          const Divider(thickness: 1.5),
                        ],
                        if (upcomingEvents.isNotEmpty) ...[
                          Text("\u{1F680} À venir", style: sectionStyle),
                          ...upcomingEvents.map(_buildStyledEventCard),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  final sectionStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple);
}
