import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart' as DeviceCalendar;
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projet_pim/ViewModel/calendar_service.dart';
import 'package:projet_pim/Model/event.dart' as CustomEvent;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarEventsScreen extends StatefulWidget {
  const CalendarEventsScreen({super.key});

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
  List<CustomEvent.Event> _nonConflictingEvents = [];
  final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm'); // Formatter
  DateTime _selectedDay = DateTime.now(); // Jour sélectionné
  DateTime _focusedDay = DateTime.now(); // Jour affiché
  @override
  void initState() {
    super.initState();
    _deviceCalendarPlugin = DeviceCalendar.DeviceCalendarPlugin();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("user_id");
    String? token = prefs.getString("jwt_token");

    if (userId != null && token != null && _isValidUserId(userId)) {
      setState(() {
        userId = userId;
        token = token;
        isLoading = false;
      });
      _eventProvider = EventProvider(userId: userId!);
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
      if (!_isValidUserId(userId!)) return;

      var calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data != null) {
        var calendar = calendarsResult.data!.first;
        var startDate = DateTime.now();
        var endDate = startDate.add(const Duration(days: 30));

        var eventsResult = await _deviceCalendarPlugin.retrieveEvents(
          calendar.id,
          DeviceCalendar.RetrieveEventsParams(
              startDate: startDate, endDate: endDate),
        );

        if (eventsResult.isSuccess && eventsResult.data != null) {
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
            await _calendarService.sendUserAvailabilityToBackend(userId!, token!, _freeSlots);

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
    DateTime endOfDay = DateTime.now().add(const Duration(days: 30));
    _freeSlots = _calendarService.getFreeSlots(_events);

    if (events.isNotEmpty) {
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
        const Text('     📅 Votre calendrier de la semaine ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Container(
          height: 150, // Ajustez la hauteur en fonction de votre besoin
          width: double.infinity,
          padding:
              const EdgeInsets.all(10), // Ajoutez un padding autour du calendrier
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
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay =
                    focusedDay; // Mise à jour de _focusedDay ici aussi
              });
              _showEventDetailsForDay(
                  selectedDay); // Affiche les détails pour le jour sélectionné
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
                      decoration: const BoxDecoration(
                        color: Colors.red, // Point rouge
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
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
            child: SizedBox(
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
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A90E2)),
                          ),
                          const SizedBox(height: 10),

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
                          const SizedBox(height: 15),

                          // Affichage de la localisation si elle est disponible
                          event.location != null
                              ? Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        event.location!,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),

                          const SizedBox(height: 15),

                          // Affichage de la description de l'événement si elle est disponible
                          event.description != null
                              ? Text(
                                  event.description!,
                                  style: const TextStyle(fontSize: 16, height: 1.5),
                                )
                              : const SizedBox.shrink(),

                          const SizedBox(height: 20),
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
            child: SizedBox(
              height: 150, // Hauteur personnalisée pour ce BottomSheet
              child: const Center(
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

  Widget _buildFreeSlotsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🕒 Créneaux libres',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (_freeSlots.isEmpty)
          const Text("Aucun créneau disponible")
        else
          ..._freeSlots.map((slot) => ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(
                    formatter.format(DateTime.parse(slot['start']!).toLocal())),
                subtitle: Text(
                    '→ ${formatter.format(DateTime.parse(slot['end']!).toLocal())}'),
              )),
      ],
    );
  }

  Widget _buildNonConflictingEventList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_nonConflictingEvents.isNotEmpty)
          Text(
              generateFreeSlotMessage(_freeSlots, _nonConflictingEvents.length),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (_nonConflictingEvents.isEmpty)
          const Text("Aucun événement proposé pendant vos créneaux disponibles.")
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  _nonConflictingEvents.map((e) => _buildEventCard(e)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildEventCard(CustomEvent.Event event) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: 280,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title ?? 'Sans titre',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Text(event.description ?? 'Aucune description disponible',
                    style: const TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      formatter
                          .format(event.startDate.toLocal() ?? DateTime.now()),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    await _getCalendarEvents();
    await _fetchNonConflictingEvents();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeviceEventsList(),
                  const SizedBox(height: 20),
                  // _buildFreeSlotsList(),
                  const SizedBox(height: 20),
                  _buildNonConflictingEventList(),
                ],
              ),
            ),
    );
  }
}
