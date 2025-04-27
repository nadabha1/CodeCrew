import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:projet_pim/ViewModel/carnet_service.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CarnetProvider with ChangeNotifier {
  final CarnetService _carnetService = CarnetService();
  List<Carnet> _carnets = [];

  List<Map<String, dynamic>> _places = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<Carnet> get carnets => _carnets;
  List<Map<String, dynamic>> get places => _places;

  // Liste des images uploadées
  final List<String> _imageUrls = [];
  List<String> get imageUrls => _imageUrls;

  // Fetch all carnets
  Future<void> fetchCarnets() async {
    _isLoading = true;
    notifyListeners(); // Notify UI to show loading

    try {
      final response =
          await http.get(Uri.parse('${ApiConstants.baseUrl}/carnets'));

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

  // Méthode pour télécharger l'image
  Future<String?> uploadImage(XFile image) async {
    try {
      var uri =
          Uri.parse('${ApiConstants.baseUrl}/upload'); // URL of your backend

      var request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('photo', image.path));

      var response = await request.send();

      if (response.statusCode == 201) {
        // HTTP 201 Created
        final responseBody = await response.stream.bytesToString();
        print('Response body: $responseBody');

        final uploadedImage = jsonDecode(responseBody);

        if (uploadedImage != null &&
            uploadedImage['response'] != null &&
            uploadedImage['response']['url'] is String &&
            uploadedImage['response']['url'].isNotEmpty) {
          _imageUrls.add(uploadedImage['response']['url']); // Add URL to list
          notifyListeners(); // Notify listeners about the change
          return uploadedImage['response']['url']; // Return the image URL
        } else {
          print('Error: The URL is null, empty, or invalid');
        }
      } else {
        print('Failed to upload image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
    return null; // Return null in case of failure
  }

  // Add a new place to an existing carnet
  Future<void> addPlaceToCarnet(
    String carnetId,
    String name,
    String description,
    List<String> categories,
    int cost,
    List<String> imageUrls, // List of image URLs
    double latitude,
    double longitude,
  ) async {
    try {
      // Now, send the place data including the image URLs
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/carnets/$carnetId/places'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'description': description,
          'categories': categories,
          'unlockCost': cost,
          'images': imageUrls, // Save the list of image URLs
          "latitude": latitude,
          "longitude": longitude,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        fetchCarnets(); // Refresh the carnets list
      } else {
        throw Exception("Failed to add place: ${response.body}");
      }
    } catch (e) {
      print("Error in addPlaceToCarnet: $e");
      throw Exception("Failed to add place");
    }
  }

  // Autres méthodes de ton provider (fetchCarnets, addPlaceToCarnet, etc.)

  // Add a new carnet
  Future<void> addCarnet(String title, String description, List places) async {
    await _carnetService.createCarnet(title, description, places);
    fetchCarnets(); // Refresh the list after adding a carnet
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

    final response = await http
        .get(Uri.parse('${ApiConstants.baseUrl}/carnets/user/$userId'));

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
      Uri.parse('${ApiConstants.baseUrl}/carnets/user/$userId'),
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
      Uri.parse('${ApiConstants.baseUrl}/user/$userId/place'),
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
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/carnets/exclude/$userId'));

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

  Future<void> fetchAllPlaces() async {
    _isLoading = true;
    notifyListeners();

    try {
      _places = await _carnetService.getAllPlacesFromCarnets();
      print("Places récupérées : $_places");
    } catch (e) {
      print("Erreur lors de la récupération des places : $e");
    }

    _isLoading = false;
    notifyListeners();
  }

// Update a place in an existing carnet
  Future<void> updatePlace(Place updatedPlace, String carnetId) async {
    try {
      final response = await http.put(
        Uri.parse(
            '${ApiConstants.baseUrl}/carnets/$carnetId/places/${updatedPlace.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': updatedPlace.name,
          'description': updatedPlace.description,
          'categories': updatedPlace.categories,
          'unlockCost': updatedPlace.unlockCost,
          'images': updatedPlace.images,
          "latitude": updatedPlace.latitude,
          "longitude": updatedPlace.longitude,
        }),
      );

      if (response.statusCode == 200) {
        fetchCarnets(); // Refresh the list of carnets after the update
      } else {
        throw Exception("Failed to update place: ${response.body}");
      }
    } catch (e) {
      print("Error in updatePlace: $e");
      throw Exception("Failed to update place");
    }
  }

  Future<String> getCarnetIdByPlaceId(String placeId) async {
    try {
      String? carnetId = await _carnetService.getCarnetIdByPlaceId(placeId);
      return carnetId;
    } catch (e) {
      print("Error fetching carnetId: $e");
      throw Exception('Error fetching carnetId: $e');
    }
  }

  Future<Place> getPlaceById(String placeId) async {
    _isLoading = true;
    notifyListeners(); // Notify the UI to show the loading state

    try {
      // Call the API to get the place details by its ID
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/carnets/place/$placeId'));

      if (response.statusCode == 200) {
        // If the response is successful, decode the data into a Place object
        final placeData = jsonDecode(response.body);
        final place = Place.fromJson(placeData);

        return place; // Return the place object
      } else {
        // If the response fails, throw an exception
        throw Exception('Failed to load place');
      }
    } catch (e) {
      print("Error fetching place by ID: $e");
      throw Exception('Error fetching place by ID');
    } finally {
      _isLoading = false; // Set the loading state to false
      notifyListeners(); // Notify the UI to update after the request
    }
  }

  Future<void> updateCarnet(String carnetId, String title) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/carnets/$carnetId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title}),
      );

      if (response.statusCode == 200) {
        await fetchCarnets(); // Met à jour la liste après modification
        print("Carnet mis à jour avec succès !");
      } else {
        print("Erreur updateCarnet: ${response.body}");
        throw Exception('Échec de la mise à jour du carnet');
      }
    } catch (e) {
      print("Erreur lors de la mise à jour du carnet: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deletePlace(
      String carnetId, String placeId, String jwtToken) async {
    final url =
        Uri.parse('${ApiConstants.baseUrl}/carnets/$carnetId/places/$placeId');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      // Remove the place from the local list if deletion is successful
      final carnet = _carnets.firstWhere((carnet) => carnet.id == carnetId);
      carnet.places.removeWhere((place) => place.id == placeId);
      notifyListeners();
    } else {
      throw Exception('');
    }
  }
}
