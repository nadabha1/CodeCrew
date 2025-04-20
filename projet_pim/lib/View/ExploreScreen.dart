import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:projet_pim/Providers/user_provider.dart';
import 'package:projet_pim/View/UserProfilePage.dart';
import 'package:projet_pim/View/ar_view_screen.dart';
import 'package:projet_pim/View/profile.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:projet_pim/Model/carnet.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key, required this.userId}) : super(key: key);

  final String userId;

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  loc.LocationData? _currentLocation;
  List<Marker> _markers = [];
  TextEditingController _searchController = TextEditingController();
  LatLng _searchLocation = LatLng(36.8065, 10.1815);
  String? _userId;
  String? _token;
  bool _isLoading = true;
  bool _showARView = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _getUserLocation();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("jwt_token");
    String? userId = prefs.getString("user_id");

    setState(() {
      _userId = userId;
      _token = token;
      _isLoading = false;
    });

    if (_userId == null || _token == null) {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  Future<void> _getUserLocation() async {
    loc.Location location = loc.Location();
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return;
      }

      loc.PermissionStatus permission = await location.hasPermission();
      if (permission == loc.PermissionStatus.denied) {
        permission = await location.requestPermission();
        if (permission != loc.PermissionStatus.granted) return;
      }

      loc.LocationData currentLocation = await location.getLocation();
      setState(() {
        _currentLocation = currentLocation;
      });
    } catch (e) {
      print("Error getting location: $e");
      setState(() {
        _currentLocation = loc.LocationData.fromMap({
          'latitude': 36.8065,
          'longitude': 10.1815,
          'accuracy': 0.0
        });
      });
    }
  }

  Future<LatLng> _getCoordinatesFromCity(String cityName) async {
    try {
      List<Location> locations = await locationFromAddress(cityName);
      return locations.isNotEmpty
          ? LatLng(locations.first.latitude, locations.first.longitude)
          : LatLng(36.8065, 10.1815);
    } catch (e) {
      print('Error getting coordinates: $e');
      return LatLng(36.8065, 10.1815);
    }
  }

  Future<List<Marker>> _getMarkers(List<Map<String, dynamic>> users) async {
    List<Marker> markers = [];
    for (var user in users) {
      try {
        LatLng userLocation = await _getCoordinatesFromCity(user['location']);
        markers.add(Marker(
          point: userLocation,
          width: 40.0,
          height: 40.0,
          child: GestureDetector(
            onTap: () => _showUserProfileDialog(user),
            child: CircleAvatar(
              radius: 20.0,
              backgroundImage: user['profileImage'] != null && user['profileImage'].isNotEmpty
                  ? NetworkImage(user['profileImage'])
                  : AssetImage('assets/default_profile.png') as ImageProvider,
            ),
          ),
        ));
      } catch (e) {
        print('Error creating marker for user ${user['_id']}: $e');
      }
    }
    if (_currentLocation != null) {
      markers.add(_getUserLocationMarker());
    }
    return markers;
  }

  Marker _getUserLocationMarker() {
    return Marker(
      point: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
      width: 40.0,
      height: 40.0,
      child: Icon(Icons.location_on, color: Colors.blue, size: 40.0),
    );
  }

void _toggleARView() {
  if (_currentLocation == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Waiting for location...')),
    );
    return;
  }
  setState(() {
    _showARView = !_showARView;
  });
}
  void _showUserProfileDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(user['name'] ?? 'User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 50.0,
                backgroundImage: user['profileImage'] != null && user['profileImage'].isNotEmpty
                    ? NetworkImage(user['profileImage'])
                    : AssetImage('assets/default_profile.png') as ImageProvider,
              ),
              SizedBox(height: 10),
              Text('Location: ${user['location'] ?? 'Unknown'}'),
              Text('Job: ${user['job'] ?? 'Unknown'}'),
              Text('Bio: ${user['bio'] ?? 'Not available'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
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
              child: Text('View Profile'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Place _createUserPlace(Map<String, dynamic> user) {
    return Place(
      id: user['_id'] ?? 'unknown',
      name: user['name'] ?? 'Unknown User',
      latitude: user['coordinates']?['lat']?.toDouble(),
      longitude: user['coordinates']?['lng']?.toDouble(),
      description: user['bio'] ?? '',
      categories: [user['job'] ?? 'user'],
      unlockCost: 0,
      images: user['profileImage'] != null 
          ? [user['profileImage']] 
          : ['assets/default_profile.png'],
      reviews: [],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_showARView ? 'AR Explorer' : 'Map Explorer'),
        actions: [
          IconButton(
            icon: Icon(_showARView ? Icons.map : Icons.camera_alt),
            onPressed: _toggleARView,
            tooltip: _showARView ? 'Switch to Map' : 'Switch to AR',
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_showARView)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search location',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () => _searchLocationByName(_searchController.text),
                  ),
                ),
              ),
            ),
          Expanded(
            child: _showARView
                ? _buildARView(context)
                : _buildMapView(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.users.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            userProvider.fetchUsers(_token ?? '');
          });
          return Center(child: CircularProgressIndicator());
        }

        return FutureBuilder<List<Marker>>(
          future: _getMarkers(userProvider.users),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No users found'));
            }

            return FlutterMap(
              options: MapOptions(
                center: _currentLocation != null
                    ? LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!)
                    : _searchLocation,
                zoom: 12.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(markers: snapshot.data!),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildARView(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (_currentLocation == null) {
      return Center(child: CircularProgressIndicator());
    }

    final userPlace = Place(
      id: _userId ?? 'current_user',
      name: 'Your Location',
      latitude: _currentLocation!.latitude,
      longitude: _currentLocation!.longitude,
      description: 'Current user location',
      categories: ['user'],
      unlockCost: 0,
      images: ['assets/default_profile.png'],
      reviews: [],
    );

    final nearbyPlaces = userProvider.users
        .where((user) => user['coordinates'] != null)
        .map(_createUserPlace)
        .toList();

    return ARViewScreen(
      userPlace: userPlace,
      nearbyPlaces: nearbyPlaces,
    );
  }

  Future<void> _searchLocationByName(String placeName) async {
    if (placeName.isEmpty) return;
    
    try {
      List<Location> locations = await locationFromAddress(placeName);
      if (locations.isNotEmpty) {
        setState(() {
          _searchLocation = LatLng(
            locations.first.latitude,
            locations.first.longitude,
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not find location: $placeName')),
      );
    }
  }
}