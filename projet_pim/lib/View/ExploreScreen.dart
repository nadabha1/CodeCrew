import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:projet_pim/Providers/user_provider.dart';
import 'package:projet_pim/View/ARViewScreen.dart';
import 'package:projet_pim/View/UserProfilePage.dart';
import 'package:projet_pim/View/profile.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// Add map type enum
enum MapType { defaultMap, satellite }

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

  // New state for map type
  MapType _selectedMapType = MapType.defaultMap;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _getUserLocation();
  }

  // Return tile URL depending on map type
  String _getTileUrl() {
    switch (_selectedMapType) {
      case MapType.satellite:
        return 'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapType.defaultMap:
      default:
        return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  // Map type selector bottom sheet
  void _showMapTypePicker() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.map),
              title: Text("Carte par défaut"),
              onTap: () {
                setState(() {
                  _selectedMapType = MapType.defaultMap;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.satellite),
              title: Text("Vue satellite"),
              onTap: () {
                setState(() {
                  _selectedMapType = MapType.satellite;
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
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
        _searchLocation =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<LatLng> _getCoordinatesFromCity(String cityName) async {
    try {
      List<Location> locations = await locationFromAddress(cityName);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      } else {
        return LatLng(36.8065, 10.1815);
      }
    } catch (e) {
      print('Error getting coordinates: $e');
      return LatLng(36.8065, 10.1815);
    }
  }

  Future<List<Marker>> _getMarkers(List<Map<String, dynamic>> users) async {
    Map<String, List<Map<String, dynamic>>> groupedUsers = {};
    List<Marker> markers = [];

    for (var user in users) {
      String location = user['location'] ?? 'Inconnue';

      if (!groupedUsers.containsKey(location)) {
        groupedUsers[location] = [];
      }
      groupedUsers[location]!.add(user);
    }

    for (var entry in groupedUsers.entries) {
      String location = entry.key;
      List<String> latLon = location.split(',');

      if (latLon.length == 2) {
        double userLat = double.parse(latLon[0].trim());
        double userLon = double.parse(latLon[1].trim());

        LatLng userLocation = LatLng(userLat, userLon);
        List<Map<String, dynamic>> usersAtLocation = entry.value;

        for (int i = 0; i < usersAtLocation.length; i++) {
          double offset = 0.0005 * i;
          double angle = (i * 360 / usersAtLocation.length) * (pi / 180);

          LatLng adjustedLocation = LatLng(
            userLocation.latitude + offset * sin(angle),
            userLocation.longitude + offset * cos(angle),
          );

          markers.add(Marker(
            point: adjustedLocation,
            width: 50.0,
            height: 50.0,
            child: GestureDetector(
              onTap: () {
                _showUserListBottomSheet(usersAtLocation);
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
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Utilisateurs à cet emplacement',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      title: Text(user['name'] ?? 'Utilisateur inconnu',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
                              token: _token ?? '',
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

  void _openInGoogleMaps(double latitude, double longitude) async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunch(url.toString())) {
      await launch(url.toString());
    } else {
      throw 'Could not launch $url';
    }
  }

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
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Explorer")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search location',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _searchLocationByName(_searchController.text);
                  },
                ),
              ),
            ),
          ), // Button to navigate to AR View Screen

          _currentLocation == null
              ? Center(child: CircularProgressIndicator())
              : Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    if (userProvider.users.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        userProvider.fetchUsers(_token ?? '');
                      });
                    }

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
                          child: Stack(
                            children: [
                              FlutterMap(
                                options: MapOptions(
                                  center: _searchLocation,
                                  zoom: 12.0,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: _getTileUrl(),
                                    subdomains: ['a', 'b', 'c'],
                                  ),
                                  MarkerLayer(markers: _markers),
                                ],
                              ),
                              Positioned(
                                top: 80,
                                right: 10,
                                child: FloatingActionButton(
                                  mini: true,
                                  backgroundColor: Colors.white,
                                  child:
                                      Icon(Icons.layers, color: Colors.black),
                                  onPressed: _showMapTypePicker,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ARViewScreen()),
                  );
                },
                icon: Icon(Icons.view_in_ar, size: 24),
                label: Text(
                  "Explorer en AR",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 7, horizontal: 7),
                  backgroundColor: const Color.fromARGB(207, 242, 182, 250),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
