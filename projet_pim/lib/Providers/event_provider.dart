import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/ViewModel/agora_service.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:projet_pim/ViewModel/calendar_service.dart';

class EventProvider with ChangeNotifier {
  List<Event> _events = [];
  List<Event> _userEvents = []; // or whatever the type of userEvents should be
  List<Event> get userEvents {
    return _userEvents;
  }

  bool _isLoading = false;
  final String userId;
  List<Event> get events => _events;
  bool get isLoading => _isLoading;

  final CalendarService calendarService = CalendarService();

  EventProvider({required this.userId});

  bool _isValidUserId(String userId) {
    final regex = RegExp(r'^[a-fA-F0-9]{24}$');
    return regex.hasMatch(userId);
  }

  Future<Event> getEventById(String eventId) async {
    final response =
        await http.get(Uri.parse('${ApiConstants.baseUrl}/events/$eventId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Event.fromJson(data, userId);
    } else {
      throw Exception('Erreur lors du chargement de l’événement');
    }
  }

  Future<void> fetchEvents(String userId) async {
    if (!_isValidUserId(userId)) {
      print('Invalid userId format');
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/events?userId=$userId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _events = data.map((json) => Event.fromJson(json, userId)).toList();
      } else {
        throw Exception('Failed to load events: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching events: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllEvents() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse(
          '${ApiConstants.baseUrl}/events/all')); // Match backend findAllEvents
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _events = data.map((json) => Event.fromJson(json, userId)).toList();
      } else {
        throw Exception(
            'Failed to load all events: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching all events: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchSpecificEvents(String userId) async {
    if (!_isValidUserId(userId)) {
      print('Invalid userId format');
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse(
          '${ApiConstants.baseUrl}/events/specific/$userId')); // Fetch specific events
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _userEvents = data.map((json) => Event.fromJson(json, userId)).toList();
      } else {
        throw Exception(
            'Failed to load specific events: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching specific events: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createEvent(
      String userId,
      String title,
      String description,
      String startDate,
      String endDate,
      String location,
      int joinPrice,
      String type,
      {String? imagePath} // Accept imagePath as an optional parameter

      ) async {
    if (!_isValidUserId(userId)) {
      print('Invalid userId format');
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/events'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'creatorId': userId,
          'title': title,
          'description': description,
          'startDate': startDate, // Already in ISO format with time
          'endDate': endDate, // Already in ISO format with time
          'location': location,
          'joinPrice': joinPrice,
          'type': type,
          'participants': [userId],
          'imagePath': imagePath,
        }),
      );
      if (response.statusCode == 201) {
        await fetchEvents(userId); // Refresh events
      } else {
        throw Exception(
            'Failed to create event: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating event: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> joinEvent(String userId, String eventId) async {
    try {
      // Correct endpoint with event ID in the URL
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/events/$eventId/join'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'userId': userId}), // Send userId in the request body
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Successfully joined the event.");
        print(
            "Response body: ${response.body}"); // Log the response for debugging
      } else {
        // Log the response body for debugging
        print("❌ Failed to join event. Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
        throw Exception("Failed to join event: ${response.body}");
      }
    } catch (e) {
      print("❌ Error in joinEvent: $e");
      rethrow; // Re-throw the exception to be handled by the caller
    }
  }

  Future<List<Event>> fetchUserEvents(String userId, String token) async {
    if (!_isValidUserId(userId)) {
      print('Invalid userId format');
      return [];
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/events/user/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print("Réponse brute : ${response.body}"); // ← ICI, juste après la réponse

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => Event.fromJson(e, userId))
          .toList(); // Ajout de userId
    } else {
      throw Exception('Erreur lors du chargement des événements');
    }
  }

  Future<void> updateEvent(Event updatedEvent) async {
    if (!_isValidUserId(updatedEvent.creatorId)) {
      print('Invalid userId format');
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      // Convert LatLng to String in the format "latitude,longitude"
      String locationString =
          "${updatedEvent.location.latitude},${updatedEvent.location.longitude}";

      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/events/${updatedEvent.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': updatedEvent.title,
          'description': updatedEvent.description,
          'startDate': updatedEvent.startDate.toIso8601String(),
          'endDate': updatedEvent.endDate.toIso8601String(),
          'location': locationString, // Send location as a String
          'joinPrice': updatedEvent.joinPrice,
        }),
      );
      if (response.statusCode == 200) {
        await fetchEvents(updatedEvent
            .creatorId); // Refresh the list of events after the update
      } else {
        throw Exception(
            'Failed to update event: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating event: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteEvent(String eventId) async {
    if (!_isValidUserId(userId)) {
      print('Invalid userId format');
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        await fetchEvents(userId); // Refresh events after deletion
      } else {
        throw Exception(
            'Failed to delete event: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting event: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<List<Event>> fetchEventsDuringFreeTime(String userId) async {
    if (!_isValidUserId(userId)) {
      print('Invalid userId format');
      return [];
    }
    try {
      final response = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/events/during-free-time/$userId'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Event.fromJson(json, userId)).toList();
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print(
          'Erreur lors du chargement des événements pendant les créneaux libres: $e');
      return [];
    }
  }

  /* Future<void> saveFreeSlotsToBackend(String freeSlotsJson) async {
    final url = Uri.parse('https://your-backend-url.com/free-time');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'userId': userId, 'freeSlots': freeSlotsJson});

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode != 200) {
        throw Exception('Failed to save free slots to backend: ${response.body}');
      }
    } catch (e) {
      print('Error saving free slots to backend: $e');
    }
  }*/
  Future<void> getNonConflictingEvents(String userId) async {
    if (!_isValidUserId(userId)) {
      print('Invalid userId format');
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/events/non-conflicting/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _events = data.map((json) => Event.fromJson(json, userId)).toList();
      } else {
        throw Exception(
            'Failed to load non-conflicting events: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching non-conflicting events: $e');
    }
    _isLoading = false;
    notifyListeners();
  }
}
