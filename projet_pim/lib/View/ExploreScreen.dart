import 'dart:convert';
import 'dart:math';
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
          return;
        }
      }

      loc.PermissionStatus permission = await location.hasPermission();
      if (permission == loc.PermissionStatus.denied) {
        permission = await location.requestPermission();
        if (permission != loc.PermissionStatus.granted) {
          return;
        }
      }

      loc.LocationData currentLocation = await location.getLocation();

      setState(() {
        _currentLocation = currentLocation;
        _searchLocation =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
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

  Future<List<Marker>> _getMarkers(List<Map<String, dynamic>> users) async {
    Map<String, List<Map<String, dynamic>>> groupedUsers = {};
    List<Marker> markers = [];

    // Group users by their location
    for (var user in users) {
      String location = user['location'] ??
          'Inconnue'; // Get location string like "Latitude,Longitude"

      if (!groupedUsers.containsKey(location)) {
        groupedUsers[location] = [];
      }
      groupedUsers[location]!.add(user);
    }

    // Loop through each group of users (grouped by location)
    for (var entry in groupedUsers.entries) {
      // Parse the location string into latitude and longitude
      String location = entry.key;
      List<String> latLon = location.split(',');

      if (latLon.length == 2) {
        double userLat = double.parse(latLon[0].trim());
        double userLon = double.parse(latLon[1].trim());

        LatLng userLocation =
            LatLng(userLat, userLon); // Use parsed latitude and longitude
        List<Map<String, dynamic>> usersAtLocation = entry.value;

        // Loop through users at the same location and create markers
        for (int i = 0; i < usersAtLocation.length; i++) {
          double offset = 0.0005 * i; // Offset to avoid marker overlap
          double angle = (i * 360 / usersAtLocation.length) *
              (3.14159265359 / 180); // Convert to radians

          LatLng adjustedLocation = LatLng(
            userLocation.latitude + offset * sin(angle),
            userLocation.longitude + offset * cos(angle),
          );

          markers.add(Marker(
            point: adjustedLocation, // Use the adjusted position
            width: 50.0,
            height: 50.0,
            child: GestureDetector(
              onTap: () {
                _showUserListBottomSheet(
                    usersAtLocation); // Show the list of users at the location
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 20.0,
                    backgroundImage:
                        usersAtLocation[i]['profileImage'] != null &&
                                usersAtLocation[i]['profileImage'].isNotEmpty
                            ? NetworkImage(usersAtLocation[i]['profileImage'])
                            : AssetImage('assets/default_profile.png')
                                as ImageProvider,
                    backgroundColor: Colors.transparent,
                  ),
                  if (usersAtLocation.length > 1)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          usersAtLocation.length.toString(),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ));
        }
      }
    }

    return markers;
  }

  void _showUserListBottomSheet(List<Map<String, dynamic>> users) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.5, // Ajuste la hauteur
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Utilisateurs à cet emplacement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['profileImage'] != null &&
                                user['profileImage'].isNotEmpty
                            ? NetworkImage(user['profileImage'])
                            : AssetImage('assets/default_profile.png')
                                as ImageProvider,
                      ),
                      title: Text(
                        user['name'] ?? 'Utilisateur inconnu',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(user['job'] ?? 'Métier inconnu'),
                      trailing: user['likes'] != null
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.favorite,
                                    color: Colors.red, size: 18),
                                SizedBox(width: 4),
                                Text('${user['likes']}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            )
                          : null,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TravelerProfileScreen(
                              travelerId: user['_id'],
                              loggedInUserId: widget.userId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
                                  _searchLocation, // Utilise la localisation de l'appareil
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
