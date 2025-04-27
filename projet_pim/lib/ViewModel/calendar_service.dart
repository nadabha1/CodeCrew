import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:projet_pim/ViewModel/api_constants.dart';

class CalendarService {
  final DeviceCalendarPlugin _calendarPlugin = DeviceCalendarPlugin();

  Future<List<Event>> getUpcomingEvents() async {
    // Demander la permission
    var status = await Permission.calendar.request();
    if (!status.isGranted) return [];

    // Récupérer les calendriers
    var calendarsResult = await _calendarPlugin.retrieveCalendars();
    var calendarId = calendarsResult.data?.first.id;

    if (calendarId == null) return [];

    // Définir la période de récupération
    var now = DateTime.now();
    var nextWeek = now.add(const Duration(days: 7));

    // Récupérer les événements
    var eventsResult = await _calendarPlugin.retrieveEvents(
      calendarId,
      RetrieveEventsParams(startDate: now, endDate: nextWeek),
    );

    return eventsResult.data ?? [];
  }

  List<Map<String, String>> getFreeSlots(List<Event> events) {
    List<Map<String, String>> freeSlots = [];

    for (var day = 0; day < 7; day++) {
      DateTime dayStart =
          DateTime.now().add(Duration(days: day)).copyWith(hour: 9, minute: 0);
      DateTime dayEnd = dayStart.copyWith(hour: 22, minute: 0);

      var dayEvents = events.where((e) => e.start!.day == dayStart.day).toList()
        ..sort((a, b) => a.start!.compareTo(b.start!));

      DateTime lastEnd = dayStart;
      for (var event in dayEvents) {
        if (event.start!.isAfter(lastEnd)) {
          freeSlots.add({
            'day': dayStart.weekday.toString(),
            'start': lastEnd.toIso8601String(),
            'end': event.start!.toIso8601String()
          });
        }
        lastEnd = event.end!.isAfter(lastEnd) ? event.end! : lastEnd;
      }

      if (lastEnd.isBefore(dayEnd)) {
        freeSlots.add({
          'day': dayStart.weekday.toString(),
          'start': lastEnd.toIso8601String(),
          'end': dayEnd.toIso8601String()
        });
      }
    }

    return freeSlots;
  }

  Future<void> sendFreeSlotsToBackend(
      String userId, String token, List<Map<String, String>> freeSlots) async {
    final url = Uri.parse(
        '${ApiConstants.baseUrl}/free-time'); // Ensure this matches the backend route
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final sanitizedFreeSlots = freeSlots
        .map((slot) {
          try {
            final start = DateTime.parse(slot['start']!).toIso8601String();
            final end = DateTime.parse(slot['end']!).toIso8601String();
            return {'start': start, 'end': end};
          } catch (e) {
            print('Invalid date in slot: $slot');
            return null;
          }
        })
        .where((slot) => slot != null)
        .toList();

    if (sanitizedFreeSlots.isEmpty) {
      print('No valid free slots to send.');
      return;
    }

    final body = jsonEncode({
      'userId': userId,
      'freeSlots': sanitizedFreeSlots,
    });

    print('Sending free slots to backend: $body');

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Backend response: ${response.body}');
        throw Exception(
            'Failed to send free slots to backend: ${response.body}');
      } else {
        print('Backend response: ${response.body}');
      }
    } catch (e) {
      print('Error sending free slots to backend: $e');
    }
  }

  Future<void> sendUserEventsToBackend(
      String userId, String token, List<Map<String, dynamic>> events) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/user-events/$userId');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Include token for authentication
    };

    final body = jsonEncode(events);

    print('Sending user events to backend: $body');

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Événements envoyés avec succès: ${response.body}');
      } else {
        print('Erreur d\'envoi des événements: ${response.statusCode}');
        print('Backend response: ${response.body}');
      }
    } catch (e) {
      print('Error sending user events to backend: $e');
    }
  }

    Future<void> sendUserAvailabilityToBackend(
      String userId, String token, List<Map<String, String>> slots) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/calendar/save-availability');
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "userId": userId,
        "availability": slots,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Erreur lors de l'envoi des créneaux libres");
    }
  }
}
