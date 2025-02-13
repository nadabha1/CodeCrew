import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:projet_pim/ViewModel/carnet_service.dart';
import 'package:http/http.dart' as http;

class CarnetProvider with ChangeNotifier {
  final CarnetService _carnetService = CarnetService();
  List _carnets = [];
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List get carnets => _carnets;
  final String baseUrl = 'http://10.0.2.2:3000'; // Use your backend URL

    Future<void> fetchCarnets() async {
    _isLoading = true;
    notifyListeners(); // ✅ Notify UI to show loading

    try {
      final response = await http.get(Uri.parse('$baseUrl/carnets'));

      if (response.statusCode == 200) {
        _carnets = jsonDecode(response.body);
      } else {
        throw Exception('Failed to load carnets');
      }
    } catch (e) {
      print("Error fetching carnets: $e");
    }

    _isLoading = false;
    notifyListeners(); // ✅ Notify UI to update
  }

  Future<void> unlockPlace(String carnetId, int placeIndex, String userId) async {
    await _carnetService.unlockPlace(carnetId, placeIndex, userId);
    fetchCarnets(); // ✅ Refresh the list after unlocking
  }
  Future<void> addCarnet(String title, String description, List places) async {
    await _carnetService.createCarnet(title, description, places);
    fetchCarnets();
  }
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

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

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


  Map<String, dynamic>? _userCarnet;
  Map<String, dynamic>? get userCarnet => _userCarnet;
String? _userCarnetId; // Stocker l'ID du carnet de l'utilisateur
  String? get userCarnetId => _userCarnetId;
 /// Check if user has a carnet
  Future<void> checkUserCarnet(String userId) async {
  _isLoading = true;
  notifyListeners();

  final response = await http.get(Uri.parse('$baseUrl/carnets/user/$userId'));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print("🔍 API Response: $data"); // ✅ Check if carnet contains _id

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


  /// Create a carnet for a user
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
  Future<void> addPlace(String userId, Map<String, dynamic> placeData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/$userId/place'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(placeData),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      checkUserCarnet(userId);
    }
  }
}
