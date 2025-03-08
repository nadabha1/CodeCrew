import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';

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

  EventProvider({required this.userId});

  Future<void> fetchEvents(String userId) async {
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

  Future<void> createEvent(String userId, String title, String description,
      DateTime date, String location, int joinPrice) async {
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
          'date': date.toIso8601String(),
          'location': location,
          'joinPrice': joinPrice,
          'participants': [userId], // Creator is the only default participant
        }),
      );
      if (response.statusCode == 201) {
        await fetchEvents(userId); // Refresh events for the current user
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
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/events/$eventId/join'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId}),
      );
      if (response.statusCode == 200) {
        await fetchEvents(userId); // Refresh events after joining
      } else {
        throw Exception('Failed to join event: Status ${response.statusCode}');
      }
    } catch (e) {
      print('Error joining event: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<List<Event>> fetchUserEvents(String userId, String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/events/user/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => Event.fromJson(e, userId))
          .toList(); // Ajout de userId
    } else {
      throw Exception('Erreur lors du chargement des événements');
    }
  }
}
