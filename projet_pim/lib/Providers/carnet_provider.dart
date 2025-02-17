import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/ViewModel/carnet_service.dart';
import 'package:http/http.dart' as http;

class CarnetProvider with ChangeNotifier {
  final CarnetService _carnetService = CarnetService();
  List<Carnet> _carnets = [];
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Carnet> get carnets => _carnets;
  final String baseUrl = 'http://localhost:3000'; // Backend URL

  // Fetch all carnets
  Future<void> fetchCarnets() async {
    _isLoading = true;
    notifyListeners(); // Notify UI to show loading

    try {
      final response = await http.get(Uri.parse('$baseUrl/carnets'));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        _carnets = data.map((json) => Carnet.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load carnets');
      }
    } catch (e) {
      print("Error fetching carnets: $e");
    }

    _isLoading = false;
    notifyListeners(); // Notify UI to update
  }

  // Add a new carnet
  Future<void> addCarnet(String title, String description, List places) async {
    await _carnetService.createCarnet(title, description, places);
    fetchCarnets(); // Refresh the list after adding a carnet
  }

  // Add a new place to an existing carnet
  Future<void> addPlaceToCarnet(
    String carnetId,
    String name,
    String description,
    List<String> categories,
    int cost,
    List<String> images,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/carnets/$carnetId/places'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'description': description,
          'categories': categories,
          'unlockCost': cost,
          'images': images,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        fetchCarnets(); // Refresh the list
      } else {
        throw Exception("Failed to add place: ${response.body}");
      }
    } catch (e) {
      print("Error in addPlaceToCarnet: $e");
      throw Exception("Failed to add place");
    }
  }

  // Store the user's carnet data
  Map<String, dynamic>? _userCarnet;
  Map<String, dynamic>? get userCarnet => _userCarnet;
  String? _userCarnetId; // Store user's carnet ID
  String? get userCarnetId => _userCarnetId;

  // Check if user has a carnet
  Future<void> checkUserCarnet(String userId) async {
    _isLoading = true;
    notifyListeners();

    final response = await http.get(Uri.parse('$baseUrl/carnets/user/$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data != null && data.isNotEmpty) {
        _userCarnet = {
          'hasCarnet': true,
          'carnet': data, // Store full carnet data
        };
      } else {
        _userCarnet = {'hasCarnet': false};
      }
    } else {
      _userCarnet = {'hasCarnet': false}; // If error, assume no carnet
    }

    _isLoading = false;
    notifyListeners();
  }

  // Create a carnet for the user
  Future<void> createCarnet(String userId, String title) async {
    final response = await http.post(
      Uri.parse('$baseUrl/carnets/user/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      await checkUserCarnet(userId); // Refresh after creation
    } else {
      throw Exception("Failed to create carnet: ${response.body}");
    }
  }

  // Add a place to the user's carnet
  Future<void> addPlace(String userId, Map<String, dynamic> placeData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/$userId/place'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(placeData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      checkUserCarnet(userId); // Refresh carnet data
    }
  }

  // Unlock a place for the user
  Future<void> unlockPlace(String userId, String placeId) async {
    _isLoading = true;
    notifyListeners(); // Notify listeners to show loading

    try {
      await _carnetService.unlockPlace(userId, placeId);
      await checkUserCarnet(userId); // Refresh carnet data
    } catch (e) {
      print("Error unlocking place: $e");
      throw Exception('Failed to unlock place: $e');
    }

    _isLoading = false;
    notifyListeners(); // Notify listeners to update
  }

  List<String> _unlockedPlaces = [];
  List<String> get unlockedPlaces => _unlockedPlaces;

  Future<void> fetchUnlockedPlaces(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _unlockedPlaces = await _carnetService.getUnlockedPlaces(userId);
      print("Places débloquées récupérées : $_unlockedPlaces");
    } catch (e) {
      print("Error fetching unlocked places: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

// Vérifier si une place est débloquée
  bool isPlaceUnlocked(String placeId) {
    return _unlockedPlaces.contains(placeId);
  }

  // Fetch all carnets excluding the user's carnet
  Future<void> fetchCarnetsExcludingUser(String userId) async {
    _isLoading = true;
    notifyListeners(); // Notify UI to show loading

    try {
      final response =
          await http.get(Uri.parse('$baseUrl/carnets/exclude/$userId'));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        _carnets = data.map((json) => Carnet.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load carnets');
      }
    } catch (e) {
      print("Error fetching carnets excluding user: $e");
    }

    _isLoading = false;
    notifyListeners(); // Notify UI to update
  }
}
