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
  final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm'); // Formatter
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now(); // Jour affiché
  LatLng? _currentLocation;
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

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    if (!mounted) return;
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
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

  Widget _buildDeviceEventsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('     📅 Votre calendrier de la semaine ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Container(
          height: 150, // Ajustez la hauteur en fonction de votre besoin
          width: double.infinity,
          padding:
              EdgeInsets.all(10), // Ajoutez un padding autour du calendrier
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat:
                CalendarFormat.week, // Affiche uniquement la semaine

            eventLoader: (day) {
              // Charger les événements pour une journée donnée
              return _events
                  .where((event) =>
                      event.start!.day == day.day &&
                      event.start!.month == day.month &&
                      event.start!.year == day.year)
                  .map((e) => e.title ?? 'No title')
                  .toList();
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!mounted) return;
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              // _showEventDetailsForDay(selectedDay);

              // Ajoute cette ligne pour afficher les slots libres
              showModalBottomSheet(
                context: context,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height *
                      0.45, // Hauteur max : 45%
                ),
                builder: (BuildContext context) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(top: 16, bottom: 32),
                    child: _buildFreeSlotMessagesForDay(selectedDay),
                  );
                },
              );
            },
            calendarBuilders: CalendarBuilders(
              // Personnaliser l'apparence des jours
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

  void _showEventDetailsForDay(DateTime selectedDay) {
    // Filtrer les événements pour le jour sélectionné
    var eventsForDay = _events
        .where((event) =>
            event.start!.day == selectedDay.day &&
            event.start!.month == selectedDay.month &&
            event.start!.year == selectedDay.year)
        .toList();

    if (eventsForDay.isNotEmpty) {
      // Si des événements existent pour ce jour, afficher le BottomSheet
      showModalBottomSheet(
        context: context,
        isScrollControlled:
            true, // Permet de contrôler la hauteur du BottomSheet
        builder: (BuildContext context) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              height:
                  120, // Hauteur personnalisée du BottomSheet, ajustez selon vos besoins
              child: ListView.builder(
                itemCount: eventsForDay.length,
                itemBuilder: (context, index) {
                  var event = eventsForDay[index];
                  return GestureDetector(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre de l'événement avec un style plus attractif
                          Text(
                            event.title ?? 'Sans titre',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4A90E2)),
                          ),
                          SizedBox(height: 10),

                          // Affichage de la date et heure de l'événement avec un formatage amélioré
                          Text(
                            'start: ${DateFormat('EEEE, d MMMM yyyy, HH:mm').format(event.start?.toLocal() ?? DateTime.now())}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            'end: ${DateFormat('EEEE, d MMMM yyyy, HH:mm').format(event.end?.toLocal() ?? DateTime.now())}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 15),

                          // Affichage de la localisation si elle est disponible
                          event.location != null
                              ? Row(
                                  children: [
                                    Icon(Icons.location_on, color: Colors.red),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        event.location!,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                )
                              : SizedBox.shrink(),

                          SizedBox(height: 15),

                          // Affichage de la description de l'événement si elle est disponible
                          event.description != null
                              ? Text(
                                  event.description!,
                                  style: TextStyle(fontSize: 16, height: 1.5),
                                )
                              : SizedBox.shrink(),

                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    } else {
      // Si aucun événement n'est trouvé pour ce jour, afficher un message
      showModalBottomSheet(
        context: context,
        isScrollControlled:
            true, // Permet de contrôler la hauteur du BottomSheet
        builder: (BuildContext context) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              height: 150, // Hauteur personnalisée pour ce BottomSheet
              child: Center(
                child: Text(
                  'Aucun événement pour cette journée.',
                  textAlign: TextAlign.center, // Centrer le texte
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildEventCard(CustomEvent.Event event) {
    final dateText =
        formatter.format(event.startDate?.toLocal() ?? DateTime.now());
    final duration = event.endDate.difference(event.startDate).inMinutes;

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsScreen(
                event: event,
                userId: userId!,
                token: token!,
                eventProvider: _eventProvider,
              ),
            ),
          );
        },
        child: Card(
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: 400,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 210, 172, 201),
                  Color.fromARGB(204, 150, 128, 212),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title ?? 'Sans titre',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                if (event.description != null && event.description!.isNotEmpty)
                  Text(
                    event.description!,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                    SizedBox(width: 6),
                    Text(
                      dateText,
                      style: TextStyle(color: Colors.white70),
                    ),
                    Spacer(),
                    Icon(Icons.access_time, color: Colors.white70, size: 16),
                    SizedBox(width: 4),
                    Text(
                      "$duration min",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                // Tu peux rajouter l'affichage du lieu ici plus tard
              ],
            ),
          ),
        ),
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
        messagesAndEvents.add(_buildEventCard(event));
      }
    }

    return Column(children: messagesAndEvents);
  }

  Widget _buildFreeSlotMessagesForDay(DateTime day) {
    // Définir une distance maximale (par exemple 1000 mètres)
    const double maxDistance = 1000.0;

    // Filtrer les créneaux libres pour le jour sélectionné
    final slotsForDay = _freeSlots.where((slot) {
      final start = DateTime.parse(slot['start']!).toLocal();
      return start.year == day.year &&
          start.month == day.month &&
          start.day == day.day;
    }).toList();

    // Récupérer les événements qui sont dans ces créneaux libres
    final eventsInSlots = _getEventsInFreeSlots().where((event) {
      // Filtrer par créneaux libres
      bool isInSlot = slotsForDay.any((slot) {
        final start = DateTime.parse(slot['start']!);
        final end = DateTime.parse(slot['end']!);
        return event.startDate.isAfter(start) && event.startDate.isBefore(end);
      });

      // Filtrer par proximité (distance)
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

      return isInSlot &&
          isNearby; // Retourner les événements dans le créneau libre et proches
    }).toList();

    if (eventsInSlots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text("Aucun événement dans vos créneaux libres ce jour-là.",
            style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    List<Widget> messagesAndEvents = [];

    for (var event in eventsInSlots) {
      final slot = slotsForDay.firstWhere(
        (slot) =>
            event.startDate.isAfter(DateTime.parse(slot['start']!)) &&
            event.startDate.isBefore(DateTime.parse(slot['end']!)),
        orElse: () => {'start': '', 'end': ''},
      );

      // Phrase + événement
      messagesAndEvents.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text(
            generateFreeSlotMessage([slot], 1),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );

      messagesAndEvents.add(
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: ListTile(
            title: Text(event.title),
            subtitle: Text(
              "${DateFormat.yMMMMd().add_Hm().format(event.startDate)} - ${DateFormat.Hm().format(event.endDate)}",
            ),
            leading: Icon(Icons.event_available),
          ),
        ),
      );
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
          color: Colors.blueAccent,
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
          title: Text("Rejoindre l'événement ?"),
          content: Text("Prix de participation : ${event.joinPrice} coins"),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("Annuler")),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _eventProvider.joinEvent(widget.userId, event.id);
                await _fetchAllEvents();
              },
              child: Text("Confirmer"),
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
      margin: EdgeInsets.symmetric(vertical: 10),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text(event.description,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            SizedBox(height: 10),
            Row(children: [
              Icon(Icons.calendar_today, size: 14),
              SizedBox(width: 6),
              Text(event.startDate.toString().split(" ")[0],
                  style: TextStyle(fontSize: 12)),
            ]),
            SizedBox(height: 4),
            Row(children: [
              Icon(Icons.location_on, size: 14),
              SizedBox(width: 6),
              Text(
                '${event.location.latitude.toStringAsFixed(4)}, ${event.location.longitude.toStringAsFixed(4)}',
                style: TextStyle(fontSize: 12),
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
                            eventProvider: EventProvider(userId: widget.userId),
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
                    backgroundColor:
                        isParticipating ? Colors.green : Colors.deepOrange,
                  ),
                  child:
                      Text(isParticipating ? "Rejoindre le Chat" : "Rejoindre"),
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz),
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
        title: Text("Tous les événements"),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Calendrier"),
            Tab(text: "Tous les événements"),
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
                  appBar: AppBar(
                    title: Text('Calendar Events'),
                    actions: [
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
                  body: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDeviceEventsList(), // Liste des événements de l'appareil
                              _buildFreeSlotMessages(), // Messages concernant les créneaux horaires libres

                              SizedBox(height: 20),
                              // _buildFreeSlotsList(), // Liste des créneaux horaires libres (optionnel)
                              SizedBox(height: 20),
                              // _buildNonConflictingEventList(), // Liste des événements sans conflits (optionnel)
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
                          hintText: 'Rechercher par titre ou participant...',
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
                            label: Text("Réinitialiser",
                                style: TextStyle(color: Colors.deepPurple)),
                          ),
                        ),
                      SizedBox(height: 10),
                      // Liste des événements filtrés
                      Expanded(
                        child: ListView(
                          children: [
                            if (recentEvents.isNotEmpty) ...[
                              Text("\u{1F4C5} Événements récents",
                                  style: sectionStyle),
                              ...recentEvents.map(_buildStyledEventCard),
                              Divider(thickness: 1.5),
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
              ],
            ),
    );
  }

  final sectionStyle = TextStyle(
      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple);
}
