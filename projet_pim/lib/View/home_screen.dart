// ✅ Version complète HomeScreen avec UI/UX + User Cards + Navigation vers leurs lieux + filtre et recherche

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/View/Event/all_events_screen.dart';
import 'package:projet_pim/View/Widgets/userPlacesScreen.dart';
import 'package:projet_pim/View/chat/group_chat_screen.dart';
import 'package:projet_pim/View/profile.dart';
import 'package:projet_pim/View/user_profile.dart';
import 'package:projet_pim/View/weather_screen.dart';
import 'package:projet_pim/ViewModel/activityLoggerService.dart';
import 'package:projet_pim/ViewModel/weather_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/carnet.dart';
import '../Providers/carnet_provider.dart';
import 'package:projet_pim/ViewModel/user_service.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({required this.userId});

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
    {'icon': Icons.theater_comedy, 'name': 'Entertainment', 'color': Colors.teal},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _loadData();
    _loadWeather();
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
              Text('Bienvenue !', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
        ),
        ListTile(
          leading: Icon(Icons.person),
          title: Text('Mon profil'),
          onTap: () {
            Navigator.push(context,
              MaterialPageRoute(builder: (_) =>
          UserProfileScreen(userId:widget.userId, token: _token!))
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.chat),
          title: Text('Events'),
          onTap: () {
            Navigator.push(context,
              MaterialPageRoute(builder: (_) =>
          AllEventsScreen(userId: widget.userId!, token: _token!))
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.cloud),
          title: Text('Météo'),
          onTap: () {
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => WeatherScreen(userId: widget.userId)),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.logout),
          title: Text('Déconnexion'),
          onTap: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            Navigator.of(context).popUntil((route) => route.isFirst); // or navigate to login
          },
        ),
      ],
    ),
  );
}

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id') ?? '';
    _token = prefs.getString('jwt_token') ?? '';
    provider = Provider.of<CarnetProvider>(context, listen: false);
    eventProvider = Provider.of<EventProvider>(context, listen: false);
    await provider!.fetchCarnetsExcludingUser(widget.userId);
    await provider!.fetchUnlockedPlaces(widget.userId);
    await eventProvider!.fetchAllEvents();
    await eventProvider!.fetchSpecificEvents(widget.userId);
    await fetchUsers();
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
      List<dynamic> fetchedUsers = await userService.getMatchingUsers(widget.userId);
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString("userId");
      allUsers = fetchedUsers.where((user) => user['_id'] != _userId).toList();
      _applySmartFilter();
    } catch (_) {
      setState(() => isLoadingUsers = false);
    }
  }

  void _applySmartFilter() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      users = allUsers.where((user) {
        final nameMatch = user['name'].toLowerCase().contains(query);
        final List<String> userTags = List<String>.from(user['tags'] ?? []);

        final tagMatch = _selectedCategories.isEmpty ||
            _selectedCategories.every((selected) =>
              userTags.any((tag) => tag.toLowerCase().contains(selected.toLowerCase()) ||
                                      selected.toLowerCase().contains(tag.toLowerCase())));

        return nameMatch && tagMatch;
      }).toList();
      isLoadingUsers = false;
    });
  }

  Widget _buildUserCard(dynamic user) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TravelerProfileScreen(
            travelerId: user['_id'],
            loggedInUserId: widget.userId,
          ),
        ),
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 5,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundImage: user['profileImageUrl'] != null && user['profileImageUrl'].isNotEmpty
                    ? NetworkImage(user['profileImageUrl'])
                    : AssetImage('assets/default_profile.png') as ImageProvider,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(user['location'] ?? "Localisation inconnue", style: TextStyle(color: Colors.grey[600])),
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
                        Text('${user['rating'] ?? 0} (${user['reviewsCount'] ?? 0} avis)'),
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
                            padding: const EdgeInsets.symmetric(horizontal: 5.0),
                            child: ChoiceChip(
                              avatar: Icon(category['icon'],
                                  color: isSelected ? Colors.white : category['color'],
                                  size: 20),
                              label: Text(name),
                              selected: isSelected,
                              selectedColor: category['color'],
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black),
                              onSelected: (selected) {
                                setState(() {
                                  selected
                                      ? {_selectedCategories.add(name),
                                          onPlaceClick(name,"click add")
                                      }
                                      :{
                                        _selectedCategories.remove(name),
                                        onPlaceClick(name,"remove")
                                      } ;
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text("People You May Like",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      itemBuilder: (context, index) => _buildUserCard(users[index]),
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
                      MaterialPageRoute(builder: (context) => WeatherScreen(userId: widget.userId)),
                    ),
                    child: weatherData != null
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 4, spreadRadius: 1),
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
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ],
                          )
                        : Text("N/A °C", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
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
