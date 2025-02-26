import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:projet_pim/Providers/user_provider.dart'; // Updated import for UserProvider
import 'package:projet_pim/View/UserProfilePage.dart';
import 'package:projet_pim/View/profile.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key, required this.userId}) : super(key: key);

  final String userId;

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  loc.LocationData? _currentLocation; // Current user location
  List<Marker> _markers = []; // List to hold markers for the map
  TextEditingController _searchController =
      TextEditingController(); // Controller for the search bar
  LatLng _searchLocation = LatLng(36.8065, 10.1815); // Default to Tunis
  String? _userId;
  String? _token;
  bool _isLoading = true; // To prevent null errors before loading session

  @override
  void initState() {
    super.initState();
    _loadSession(); // Load user session (userId & token)
    _getUserLocation(); // Get user's current location on screen load
  }

  // Function to load user session from SharedPreferences
  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("jwt_token");
    String? userId = prefs.getString("user_id");

    setState(() {
      _userId = userId;
      _token = token;
      _isLoading = false;
    });

    // If token or userId is missing, redirect to login
    if (_userId == null || _token == null) {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  // Function to get the user's current location
  Future<void> _getUserLocation() async {
    loc.Location location = loc.Location();
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          return; // If location service is not enabled, do nothing
        }
      }

      loc.PermissionStatus permission = await location.hasPermission();
      if (permission == loc.PermissionStatus.denied) {
        permission = await location.requestPermission();
        if (permission != loc.PermissionStatus.granted) {
          return; // If permission is not granted, do nothing
        }
      }

      // Fetch current location
      loc.LocationData currentLocation = await location.getLocation();

      setState(() {
        _currentLocation = currentLocation; // Update the location state
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  // Function to get coordinates from city name
  Future<LatLng> _getCoordinatesFromCity(String cityName) async {
    try {
      List<Location> locations = await locationFromAddress(cityName);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      } else {
        return LatLng(36.8065, 10.1815); // Default to Tunis if no result
      }
    } catch (e) {
      print('Error getting coordinates: $e');
      return LatLng(36.8065, 10.1815); // Default to Tunis if error
    }
  }

  // Function to get markers from user data
  Future<List<Marker>> _getMarkers(List<Map<String, dynamic>> users) async {
    List<Marker> markers = [];
    for (var user in users) {
      // Affiche l'utilisateur et sa localisation pour déboguer
      print('User: ${user['location']}');

      LatLng userLocation = await _getCoordinatesFromCity(user['location']);

      markers.add(Marker(
        point: userLocation,
        width: 40.0,
        height: 40.0,
        child: GestureDetector(
          onTap: () {
            // Afficher un Dialog avec les informations du profil
            _showUserProfileDialog(user);
          },
          child: CircleAvatar(
            radius: 20.0,
            backgroundImage:
                user['profileImage'] != null && user['profileImage'].isNotEmpty
                    ? NetworkImage(
                        user['profileImage']) // Afficher l'image depuis l'URL
                    : AssetImage('assets/default_profile.png')
                        as ImageProvider, // Image locale par défaut
            backgroundColor: Colors.transparent,
          ),
        ),
      ));
    }
    print(
        'Markers count: ${markers.length}'); // Vérifiez le nombre de marqueurs
    return markers;
  }

  // Function to open the place in Google Maps
  void _openInGoogleMaps(double latitude, double longitude) async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunch(url.toString())) {
      await launch(url.toString());
    } else {
      throw 'Could not launch $url';
    }
  }

  // Function to search for location by name (city or place)
  Future<void> _searchLocationByName(String placeName) async {
    try {
      List<Location> locations = await locationFromAddress(placeName);
      if (locations.isNotEmpty) {
        setState(() {
          _searchLocation =
              LatLng(locations.first.latitude, locations.first.longitude);
        });
      }
    } catch (e) {
      print('Error getting coordinates: $e');
    }
  }

  // Function to show user profile in a dialog
  void _showUserProfileDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(user['name'] ??
              'Nom de l\'utilisateur'), // Afficher le nom de l'utilisateur
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 50.0,
                backgroundImage: user['profileImage'] != null &&
                        user['profileImage'].isNotEmpty
                    ? NetworkImage(
                        user['profileImage']) // Afficher l'image du profil
                    : AssetImage('assets/default_profile.png')
                        as ImageProvider, // Image locale par défaut
              ),
              SizedBox(height: 10),
              Text('Localisation: ${user['location'] ?? 'Inconnue'}'),
              Text('job: ${user['job'] ?? 'Inconnue'}'),
              Text('Autres détails: ${user['bio'] ?? 'Non disponible'}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                String userId =
                    user['_id'] ?? 'defaultId'; // Get the tapped user's ID
                String token = _token ?? ''; // Pass the token here

                // Navigate to the user's profile page with the ID and token
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TravelerProfileScreen(
                      travelerId: user['_id'], // Pass the tapped user's ID
                      loggedInUserId:
                          widget.userId, // Pass the logged-in user's token
                    ),
                  ),
                );
              },
              child: Text('Voir le Profil'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while the session is being loaded
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Explorer"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher un lieu',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    // Call the search function when search button is pressed
                    _searchLocationByName(_searchController.text);
                  },
                ),
              ),
            ),
          ),
          _currentLocation == null
              ? Center(child: CircularProgressIndicator())
              : Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    // Fetch users if not already loaded
                    if (userProvider.users.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        userProvider
                            .fetchUsers(_token ?? ''); // Use token for API
                      });
                    }

                    // FutureBuilder to load markers from user data
                    return FutureBuilder<List<Marker>>(
                      future: _getMarkers(userProvider.users),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                              child: Text("Error: ${snapshot.error}"));
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(child: Text("No users found"));
                        }

                        _markers = snapshot.data!;

                        return Expanded(
                          child: FlutterMap(
                            options: MapOptions(
                              center:
                                  _searchLocation, // Center map on the searched location
                              zoom: 12.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                subdomains: ['a', 'b', 'c'],
                              ),
                              MarkerLayer(
                                markers: _markers,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }
}
