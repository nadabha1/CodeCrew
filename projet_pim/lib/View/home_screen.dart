import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/View/CalendarEventsScreen.dart';
import 'package:projet_pim/View/Event/all_events_screen.dart';
import 'package:projet_pim/View/Event/my_events_screen.dart';
import 'package:projet_pim/View/TripPlanningScreen.dart';
import 'package:projet_pim/View/profile.dart';
import 'package:projet_pim/View/weather_screen.dart';
import 'package:projet_pim/ViewModel/activityLoggerService.dart';
import 'package:projet_pim/ViewModel/weather_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Providers/carnet_provider.dart';
import 'package:projet_pim/ViewModel/user_service.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final String token;

  const HomeScreen({required this.userId, required this.token, Key? key})
      : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CarnetProvider? provider;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  EventProvider? eventProvider;
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? weatherData;
  List<dynamic> users = [];
  List<dynamic> allUsers = [];
  bool isLoadingUsers = true;
  String? _userId;
  String? _token;
  List<String> _selectedCategories = [];
  bool isShowingFallbackUsers = false;
  bool showMatches = false; // false = show People, true = show Matches
  List<dynamic> matches = [];
  bool isLoadingMatches = true; // par défaut en cours de chargement
  


  TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.restaurant, 'name': 'Food', 'color': Colors.red},
    {'icon': Icons.shopping_bag, 'name': 'Shopping', 'color': Colors.blue},
    {'icon': Icons.park, 'name': 'Nature', 'color': Colors.green},
    {'icon': Icons.museum, 'name': 'Culture', 'color': Colors.orange},
    {'icon': Icons.fitness_center, 'name': 'Sports', 'color': Colors.purple},
    {'icon': Icons.local_bar, 'name': 'Nightlife', 'color': Colors.pink},
    {'icon': Icons.hotel, 'name': 'Hotels', 'color': Colors.indigo},
    {'icon': Icons.directions_bus, 'name': 'Transport', 'color': Colors.brown},
    {
      'icon': Icons.theater_comedy,
      'name': 'Entertainment',
      'color': Colors.teal
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _loadData();
    _loadWeather();
    _preloadMatches(); 
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFFDBD9FE),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/default_profile.png'),
                ),
                SizedBox(height: 10),
                Text('Bienvenue !',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Mes evenements'),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MyEventsScreen(userId: widget.userId, token: _token!),
                  ));
            },
          ),
          ListTile(
            leading: Icon(Icons.chat),
            title: Text('Events'),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AllEventsScreen(
                          userId: widget.userId, token: _token!)));
            },
          ),
          ListTile(
            leading: Icon(Icons.calendar_month),
            title: Text('Recommandations'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CalendarEventsScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.flight_takeoff),
            title: Text('Plan Your Trip'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        TripPlanningScreen(userId: widget.userId)),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.cloud),
            title: Text('Météo'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => WeatherScreen(
                        userId: widget.userId, weatherData: weatherData ?? {})),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Déconnexion'),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.of(context)
                  .popUntil((route) => route.isFirst); // or navigate to login
            },
          ),
        ],
      ),
    );
  }

 Future<List<dynamic>> _fetchMatches() async {
  try {
    final userService = UserService();
    final matches = await userService.matchUser(widget.userId);
    return matches ?? []; // 👈 return the list
  } catch (e) {
    print('Error fetching matches: $e');
    return [];
  }
 }

   Future<void> _preloadMatches() async {
  try {
    final fetchedMatches = await _fetchMatches();
    matches = fetchedMatches;
  } catch (e) {
    print('Erreur lors du chargement des matches: $e');
  } finally {
    setState(() {
      isLoadingMatches = false;
    });
  }
}



  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id') ?? '';
    _token = prefs.getString('jwt_token') ?? '';
    provider = Provider.of<CarnetProvider>(context, listen: false);
    eventProvider = Provider.of<EventProvider>(context, listen: false);
    await Future.wait([
    provider!.fetchCarnetsExcludingUser(widget.userId),
    provider!.fetchUnlockedPlaces(widget.userId),
    eventProvider!.fetchAllEvents(),
    eventProvider!.fetchSpecificEvents(widget.userId),
    fetchUsers(),
    //_fetchMatches(),
    _preloadMatches(),]);

  }

  void _loadWeather() async {
    try {
      final data = await _weatherService.fetchWeather("Tunis");
      setState(() {
        weatherData = data;
      });
    } catch (_) {}
  }

  Future<void> fetchUsers() async {
    try {
      UserService userService = UserService();
      List<dynamic> fetchedUsers = await userService.getAllUsers(widget.userId);
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString("userId");
      allUsers =
          fetchedUsers.where((user) => user['_id'] != widget.userId).toList();
      _applySmartFilter();
    } catch (_) {
      setState(() => isLoadingUsers = false);
    }
  }

  void _applySmartFilter() {
    final query = _searchController.text.toLowerCase();

    List<dynamic> filtered = allUsers.where((user) {
      final nameMatch = user['name'].toLowerCase().contains(query);
      final List<String> userTags = List<String>.from(user['tags'] ?? [])
          .map((e) => e.toLowerCase())
          .toList();

      bool tagMatch = true;

      if (_selectedCategories.isNotEmpty) {
        String normalize(String input) {
          return input
              .toLowerCase()
              .replaceAll(RegExp(r'\s+'), '') // remove spaces
              .replaceAll(RegExp(r'[éèêë]'), 'e')
              .replaceAll(RegExp(r'[àâä]'), 'a')
              .replaceAll(RegExp(r'[îï]'), 'i')
              .replaceAll(RegExp(r'[ôö]'), 'o')
              .replaceAll(RegExp(r'[ùûü]'), 'u')
              .replaceAll(RegExp(r's$'), ''); // remove trailing "s" for plurals
        }

        final selectedTags =
            _selectedCategories.map((e) => normalize(e)).toList();
        final userTags = List<String>.from(user['tags'] ?? [])
            .map((e) => normalize(e))
            .toList();
        print(" ❤❤❤ $selectedTags");
        print(" ❤❤❤ $userTags");

        // ✅ logique AND stricte
        tagMatch =
            selectedTags.every((selected) => userTags.contains(selected));
      }

      return nameMatch && tagMatch;
    }).toList();
    print(
        "🧠 Résultat filtré (${filtered.length} users) avec: $_selectedCategories");

    setState(() {
      users = filtered;
      isShowingFallbackUsers = false; // (ou inutile à ce stade)
      isLoadingUsers = false;
    });
  }

  Future<String> getAddressFromLatLng(LatLng location) async {
    try {
      print(
          "🌍 Fetching address for coordinates: ${location.latitude}, ${location.longitude}");

      if (location.latitude == 0.0 && location.longitude == 0.0) {
        print(
            "⚠️ Invalid coordinates: ${location.latitude}, ${location.longitude}");
        return "Lieu inconnu";
      }

      List<Placemark> placemarks =
          await placemarkFromCoordinates(location.latitude, location.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // Extraire les informations utiles
        String street = place.thoroughfare ?? place.street ?? "Rue inconnue";
        String city = place.locality ?? place.subLocality ?? "Ville inconnue";
        String region = place.administrativeArea ?? "Région inconnue";
        String country = place.country ?? "Pays inconnu";

        // Construire une adresse détaillée
        String formattedAddress = "$street, $city, $region, $country";
        print("✅ Geocoding successful: $formattedAddress");

        return formattedAddress;
      } else {
        print("⚠️ No placemarks found for the given coordinates.");
      }
    } catch (e) {
      print("❌ Erreur lors du géocodage : $e");
    }

    return "Lieu inconnu";
  }

  LatLng _parseLocation(dynamic location) {
    try {
      if (location is Map<String, dynamic>) {
        print("📍 Parsing location as Map: $location");
        return LatLng(
          location['latitude'] ?? 0.0,
          location['longitude'] ?? 0.0,
        );
      } else if (location is String) {
        print("📍 Parsing location as String: $location");
        // Split the string into latitude and longitude
        List<String> coordinates = location.split(',');
        if (coordinates.length == 2) {
          return LatLng(
            double.parse(coordinates[0].trim()), // Latitude
            double.parse(coordinates[1].trim()), // Longitude
          );
        } else {
          print("⚠️ Invalid string format for location: $location");
        }
      }
    } catch (e) {
      print("❌ Error parsing location: $e");
    }
    print("⚠️ Invalid location format. Returning default coordinates.");
    return LatLng(0, 0); // Default value
  }

  Widget _buildUserCard(dynamic user) {
    // Appel de la fonction asynchrone pour récupérer la localisation
    return FutureBuilder<String>(
      future: _getLocationName(user), // Appeler ta logique asynchrone ici
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Affiche un indicateur de chargement pendant l'attente
        }

        if (snapshot.hasError) {
          return Text('❌ Erreur : ${snapshot.error}');
        }

        // Utiliser la localisation récupérée
        String locationName = snapshot.data ?? "Lieu inconnu";

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TravelerProfileScreen(
                travelerId: user['_id'],
                loggedInUserId: widget.userId,
                token: _token!,
              ),
            ),
          ),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 5,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: user['profileImageUrl'] != null &&
                            user['profileImageUrl'].isNotEmpty
                        ? NetworkImage(user['profileImageUrl'])
                        : AssetImage('assets/default_profile.png')
                            as ImageProvider,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['name'],
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(locationName, // Afficher la localisation récupérée
                            style: TextStyle(color: Colors.grey[600])),
                        SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          children: (user['tags'] ?? []).map<Widget>((tag) {
                            return Chip(
                              label: Text(tag),
                              backgroundColor: Color(0xFFE5E5F7),
                              labelStyle: TextStyle(fontSize: 12),
                            );
                          }).toList(),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.orange, size: 16),
                            SizedBox(width: 4),
                            Text(
                                '${user['rating'] ?? 0} (${user['reviewsCount'] ?? 0} avis)'),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

// Fonction asynchrone pour récupérer la localisation
  Future<String> _getLocationName(dynamic userData) async {
    try {
      if (userData?['location'] != null) {
        LatLng parsedLocation = _parseLocation(userData['location']);
        return await getAddressFromLatLng(parsedLocation);
      } else {
        print("⚠️ No location data found in userData.");
      }
    } catch (e) {
      print("❌ Error fetching location name: $e");
    }
    return "Lieu inconnu"; // Valeur par défaut
  }

  void onSearch(String keyword) {
    if (keyword.isNotEmpty) {
      ActivityLoggerService.logAction(
        userId: widget.userId,
        type: "search users",
        value: keyword,
      );
    }
  }

  void onPlaceClick(String name, String type) {
    ActivityLoggerService.logAction(
      userId: widget.userId,
      type: type,
      value: name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);

    return Scaffold(
      key: _scaffoldKey, // Ajout ici
      backgroundColor: Color(0xFFF7F4FC),
      drawer: _buildDrawer(), // Ajout ici
      body: SafeArea(
        child: eventProvider.isLoading || isLoadingUsers
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: onSearch,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un utilisateur...',
                          prefixIcon: Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) => _applySmartFilter(),
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.only(left: 12),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((category) {
                          final name = category['name'];
                          final isSelected = _selectedCategories.contains(name);
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 5.0),
                            child: ChoiceChip(
                              avatar: Icon(category['icon'],
                                  color: isSelected
                                      ? Colors.white
                                      : category['color'],
                                  size: 20),
                              label: Text(name),
                              selected: isSelected,
                              selectedColor: category['color'],
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black),
                              onSelected: (selected) {
                                setState(() {
                                  selected
                                      ? {
                                          _selectedCategories.add(name),
                                          onPlaceClick(name, "click add")
                                        }
                                      : {
                                          _selectedCategories.remove(name),
                                          onPlaceClick(name, "remove")
                                        };
                                  _applySmartFilter();
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (_selectedCategories.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedCategories.clear();
                              _searchController.clear();
                              _applySmartFilter();
                            });
                          },
                          icon: Icon(Icons.refresh, color: Colors.black87),
                          label: Text("Réinitialiser les filtres",
                              style: TextStyle(color: Colors.black87)),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 6,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    showMatches = true;
                                   
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !showMatches
                                        ? Color(0xFFDBD9FE)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'People You May Like',
                                      style: TextStyle(
                                        color: !showMatches
                                            ? Colors.black
                                            : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    showMatches = true;
                                   
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: showMatches
                                        ? Color(0xFFDBD9FE)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Matches You May Like',
                                      style: TextStyle(
                                        color: showMatches
                                            ? Colors.black
                                            : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (showMatches)
  isLoadingMatches
      ? Center(child: CircularProgressIndicator())
      : matches.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  "Aucun match trouvé.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage('assets/default_profile.png'),
                    ),
                    title: Text(match['name']),
                    subtitle: Text('Score: ${match['score'].toStringAsFixed(2)} ⭐'),
                  ),
                );
              },
            )

                    else
                      users.isEmpty && !isLoadingUsers
                          ? Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Center(
                                child: Text(
                                  "Aucun utilisateur trouvé.",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: users.length,
                              itemBuilder: (context, index) =>
                                  _buildUserCard(users[index]),
                            ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFDBD9FE),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.menu, color: Colors.white, size: 28),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => WeatherScreen(
                              userId: widget.userId,
                              weatherData: weatherData ?? {})),
                    ),
                    child: weatherData != null
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        blurRadius: 4,
                                        spreadRadius: 1),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    "https://openweathermap.org/img/wn/${weatherData!['weather'][0]['icon']}@2x.png",
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 15,
                                child: Text(
                                  "${weatherData!['main']['temp'].toStringAsFixed(1)}°C",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          )
                        : Text("N/A °C",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
