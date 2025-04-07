import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/View/carnet&place/AddPlaceScreenStep1.dart';
import 'package:projet_pim/View/carnet&place/PlaceDetailsScreen.dart';
import 'package:projet_pim/View/carnet&place/carnet_dtetails_screen.dart';
import 'package:projet_pim/View/chat/group_chat_screen.dart';
import 'package:projet_pim/View/profile.dart';
import 'package:projet_pim/View/weather_screen.dart';
import 'package:projet_pim/ViewModel/weather_service.dart';
import 'package:provider/provider.dart';
import '../Providers/carnet_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:projet_pim/providers/review_provider.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  CarnetProvider? provider;
  EventProvider? eventProvider;
  List<String> _eventTypes = [
    "Concerts",
    "Workshops",
    "Networking Events",
    "Sports Activities",
    "Cultural Festivals",
    "Tech Meetups",
    "Art Exhibitions",
    "Other"
  ];
  String selectedCategory = 'All';

  List<String> categories = [
    'All', 'Musée', 'Parc', 'Shopping', 'Café', 'Histoire', 'Nature', 'Culture', 'Sport'
  ];
  List<dynamic> users = [];
  bool isLoadingUsers = true;
  late Animation<double> _cardFadeAnimation;
  late AnimationController _cardAnimationController;
  TextEditingController _searchController = TextEditingController();

  InheritedWidget? _ancestor;
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? weatherData;

  void _reloadData() async {
    if (provider != null && eventProvider != null) {
      await provider!.fetchCarnetsExcludingUser(widget.userId);
      await provider!.fetchUnlockedPlaces(widget.userId);
      await fetchUsers(); // Fetch users when data is reloaded

      // Fetch all events
      await eventProvider!.fetchAllEvents();

      // Fetch recommended events for "For You" section
      await eventProvider!.fetchSpecificEvents(widget.userId);

      if (mounted) setState(() {});
    }
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    provider ??= Provider.of<CarnetProvider>(context, listen: false);
    eventProvider ??= Provider.of<EventProvider>(context, listen: false);
    _ancestor = context.dependOnInheritedWidgetOfExactType<InheritedWidget>();
  }

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _cardFadeAnimation = CurvedAnimation(
        parent: _cardAnimationController, curve: Curves.easeInOut);
    _cardAnimationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadData());
    _loadWeather();
  }

  @override
  void dispose() {
    // Use the saved reference to the ancestor
    if (_ancestor != null) {
      // Perform any necessary cleanup with the ancestor reference
    }
    _cardAnimationController.dispose();
    eventProvider = null;
    super.dispose();
  }

  void _loadWeather() async {
    print("Chargement de la météo...");
    try {
      final data = await _weatherService.fetchWeather("Tunis");
      print("Données météo reçues: $data");
      setState(() {
        weatherData = data;
      });
    } catch (e) {
      print("Erreur : $e");
    }
  }

  Future<void> fetchUsers() async {
    try {
      UserService userService = UserService();
      List<dynamic> fetchedUsers = await userService.getAllUsers(widget.userId);
      setState(() {
        users = fetchedUsers;
        isLoadingUsers = false;
      });
    } catch (e) {
      print("Error fetching users: $e");
      setState(() => isLoadingUsers = false);
    }
  }

  void _showCreateEventDialog() {
    String title = '';
    String description = '';
    DateTime date = DateTime.now();
    String location = '';
    int joinPrice = 5; // Default join price
    String selectedType = _eventTypes.first; // Default type

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Title'),
                onChanged: (value) => title = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Description'),
                onChanged: (value) => description = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Location'),
                onChanged: (value) => location = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Join Price (coins)'),
                keyboardType: TextInputType.number,
                onChanged: (value) => joinPrice = int.tryParse(value) ?? 5,
              ),
              SizedBox(height: 10),

              // Dropdown for event type
              DropdownButtonFormField<String>(
                value: selectedType,
                items: _eventTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) selectedType = value;
                },
                decoration: InputDecoration(labelText: "Event Type"),
              ),

              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      ) ??
                      date;
                },
                child: Text('Pick Date'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (title.isNotEmpty && location.isNotEmpty) {
                eventProvider!.createEvent(widget.userId, title, description,
                    date, location, joinPrice, selectedType); // Include type
                Navigator.pop(context);
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinConfirmationDialog(Event event) {
    showDialog(
      context: context, // Now defined within the class
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Join Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Do you want to join "${event.title}"?'),
              SizedBox(height: 10),
              Text(
                  'Join Price: ${event.joinPrice} coins'), // Display join price
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                eventProvider!.joinEvent(
                    widget.userId, event.id); // Now eventProvider is accessible
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showUnlockDialog(String placeName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Success!"),
          content: Text("You have successfully unlocked $placeName!"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmUnlockDialog(String placeName, int placePrice, place) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Payment Confirmation"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Do you want to unlock '$placeName'?"),
              SizedBox(height: 10),
              Text("Price to unlock: $placePrice coins"),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                try {
                  await provider!.unlockPlace(
                      widget.userId, place.id); // Use the instance method
                  _showUnlockDialog(placeName);
                  _reloadData();
                } catch (e) {
                  _showErrorDialog(e.toString());
                }
              },
              child: Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  void _openInGoogleMaps(double latitude, double longitude) async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildEventCard(Event event) {
    return Padding(
      padding: EdgeInsets.only(right: 10),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  event.description,
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Date: ${event.date.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Location: ${event.location}',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Participants: ${event.participants.length}',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ),
              Spacer(),
              Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton(
                  onPressed: () {
                    if (event.isParticipating) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupChatScreen(
                              conversationId: event
                                  .conversationId!, // Assure-toi que 'event' contient 'conversationId'
                              groupName: event.title),
                        ),
                      );
                    } else {
                      _showJoinConfirmationDialog(event);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: event.isParticipating
                        ? Color(0xFF50E3C2)
                        : Color(0xFFF4A261),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    event.isParticipating ? 'Chat' : 'Join',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final carnetProvider = Provider.of<CarnetProvider>(context, listen: true);
    final otherCarnets =
        carnetProvider.carnets.where((c) => c.owner != widget.userId).toList();
    final eventProvider = Provider.of<EventProvider>(context, listen: true);
  final provider = Provider.of<CarnetProvider>(context);
    final searchText = _searchController.text.toLowerCase();

    final filteredCarnets = provider.carnets.where((c) {
      final placesFiltered = c.places.where((p) {
        final matchesSearch = p.name.toLowerCase().contains(searchText);
        final matchesCategory = selectedCategory == 'All' ||
            p.categories.contains(selectedCategory);
        return matchesSearch && matchesCategory;
      }).toList();
      return placesFiltered.isNotEmpty;
    }).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FC),
      body: SafeArea(
        child: carnetProvider.isLoading || eventProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
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
                              Icon(Icons.menu,
                                  color: Colors.black,
                                  size: 28), // Icône du menu

                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => WeatherScreen(
                                                  userId: 'userId',
                                                )),
                                      );
                                    },
                                    child: weatherData != null
                                        ? Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              // Icône météo dans un cercle avec ombre
                                              Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  // Icône dans un cercle avec ombre
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.grey
                                                              .withOpacity(0.3),
                                                          blurRadius: 4,
                                                          spreadRadius: 1,
                                                        ),
                                                      ],
                                                    ),
                                                    child: ClipOval(
                                                      child: Image.network(
                                                        "https://openweathermap.org/img/wn/${weatherData!['weather'][0]['icon']}@2x.png",
                                                        width:
                                                            60, // Taille de l'icône ajustée pour plus de visibilité
                                                        height: 60,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  // Texte superposé sur l'icône
                                                  Positioned(
                                                    bottom:
                                                        15, // Positionne le texte en bas de l'icône
                                                    child: Text(
                                                      "${weatherData!['main']['temp'].toStringAsFixed(1)}°C",
                                                      style: TextStyle(
                                                        fontSize:
                                                            18, // Taille de la police ajustée pour une meilleure visibilité
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .white, // Texte en blanc pour le contraste
                                                        shadows: [
                                                          Shadow(
                                                            blurRadius: 6.0,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.6),
                                                            offset: Offset(
                                                                1.0, 1.0),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                  height:
                                                      6), // Espacement sous l'icône
                                            ],
                                          )
                                        : Text(
                                            "N/A °C",
                                            style: TextStyle(
                                              fontSize:
                                                  16, // Taille de la police réduite
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black54,
                                            ),
                                          ),
                                  ),

                                  SizedBox(width: 10), // Espacement

                                  // Avatar de profil
                                  CircleAvatar(
                                    backgroundImage: AssetImage(
                                        'assets/default_profile.png'),
                                    radius: 22,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Text(
                            "Hey User!",
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Where's your next trip going to be?",
                            style: TextStyle(fontSize: 16, color: Colors.brown),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    //////////////////////////////////////Filterrrrrrr////////////////////////
                    ///
                    ///
                    ///
                    TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Rechercher un lieu...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = cat == selectedCategory;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = cat;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 6),
                      padding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.deepPurple : Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            ///////////////////////////////////////////////////////Fin///////////////
   
//////////////////////////////////////////jdid
///
 filteredCarnets.isEmpty
                      ? Center(child: Text("Aucun lieu trouvé."))
                        : Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Other Carnets",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 10),
                                // Liste des carnets avec places
                                ListView.builder(
                                  shrinkWrap: true,
                          itemCount: filteredCarnets.length,
                                  itemBuilder: (context, index) {
 final carnet = filteredCarnets[index];
                            final places = carnet.places.where((p) {
                              final matchesSearch = p.name
                                  .toLowerCase()
                                  .contains(searchText);
                              final matchesCategory = selectedCategory == 'All' ||
                                  p.categories.any((cat) =>
                                      cat.toLowerCase() ==
                                      selectedCategory.toLowerCase());
                              return matchesSearch && matchesCategory;
                            }).toList();                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          carnet.title,
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 10),
                                        // Liste des places de ce carnet en défilement horizontal
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children:
                                                places.map((place) {
                                              bool isUnlocked = carnetProvider
                                                  .isPlaceUnlocked(place.id);

                                              return Card(
                                                margin: EdgeInsets.symmetric(
                                                    horizontal: 10),
                                                child: Container(
                                                  width:
                                                      190, // Largeur de la carte
                                                  padding: EdgeInsets.all(10),
                                                  child: Column(
                                                    children: [
                                                      if (place
                                                          .images.isNotEmpty)
                                                        Stack(
                                                          children: [
                                                            // Image normale si déverrouillée, floue sinon
                                                            ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              child: isUnlocked
                                                                  ? Image
                                                                      .network(
                                                                      place
                                                                          .images
                                                                          .first, // Image normale
                                                                      width:
                                                                          140,
                                                                      height:
                                                                          120,
                                                                      fit: BoxFit
                                                                          .cover,
                                                                      errorBuilder: (context,
                                                                          error,
                                                                          stackTrace) {
                                                                        return Icon(
                                                                            Icons
                                                                                .broken_image,
                                                                            size:
                                                                                50,
                                                                            color:
                                                                                Colors.grey);
                                                                      },
                                                                    )
                                                                  : ImageFiltered(
                                                                      imageFilter: ImageFilter.blur(
                                                                          sigmaX:
                                                                              5,
                                                                          sigmaY:
                                                                              5), // Flou
                                                                      child: Image
                                                                          .network(
                                                                        place
                                                                            .images
                                                                            .first, // Image floue
                                                                        width:
                                                                            140,
                                                                        height:
                                                                            120,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                        errorBuilder: (context,
                                                                            error,
                                                                            stackTrace) {
                                                                          return Icon(
                                                                              Icons.broken_image,
                                                                              size: 50,
                                                                              color: Colors.grey);
                                                                        },
                                                                      ),
                                                                    ),
                                                            ),

                                                            // Icône de cadenas si verrouillé
                                                            if (!isUnlocked)
                                                              Positioned(
                                                                top: 40,
                                                                left: 55,
                                                                child: Icon(
                                                                  Icons.lock,
                                                                  size: 40,
                                                                  color: Colors
                                                                      .white
                                                                      .withOpacity(
                                                                          0.8),
                                                                ),
                                                              ),
                                                          ],
                                                        )
                                                      else
                                                        Icon(Icons.broken_image,
                                                            size: 50,
                                                            color: Colors.grey),
                                                      SizedBox(height: 10),
                                                      Text(
                                                        place.name,
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: isUnlocked
                                                            ? () {
                                                                // Navigation vers les détails du lieu
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder: (context) =>
                                                                        ChangeNotifierProvider<
                                                                            ReviewProvider>(
                                                                      create: (_) =>
                                                                          ReviewProvider(),
                                                                      child: PlaceDetailsScreen(
                                                                          place:
                                                                              place),
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            : () async {
                                                                // Afficher la boîte de dialogue de confirmation
                                                                _showConfirmUnlockDialog(
                                                                    place.name,
                                                                    place
                                                                        .unlockCost,
                                                                    place);
                                                              },
                                                        child: Text(isUnlocked
                                                            ? "View Details"
                                                            : "Unlock (5 coins)"),
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              isUnlocked
                                                                  ? Color(
                                                                      0xFF9E9E9E)
                                                                  : Color(
                                                                      0xFFD4F98F),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),

                                        SizedBox(height: 20),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                    SizedBox(height: 20),


// 🔹 "Events For You" Section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Events For You",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(Icons.refresh, color: Colors.black54),
                            onPressed:
                                _reloadData, // Refresh events when clicked
                          ),
                        ],
                      ),
                    ),

                    eventProvider!.userEvents.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text("No recommended events",
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        : SizedBox(
                            height: 200, // Fixed height for carousel
                            child: FadeTransition(
                              opacity: _cardFadeAnimation,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                itemCount: eventProvider!.userEvents.length,
                                itemBuilder: (context, index) {
                                  final event =
                                      eventProvider!.userEvents[index];
                                  return _buildEventCard(event);
                                },
                              ),
                            ),
                          ),

// 🔹 "All Events" Section
                    SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("All Events",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.black54),
                            onPressed:
                                _showCreateEventDialog, // Open event creation dialog
                          ),
                        ],
                      ),
                    ),

                    eventProvider!.events.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text("No events available",
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        : SizedBox(
                            height: 200, // Fixed height for carousel
                            child: FadeTransition(
                              opacity: _cardFadeAnimation,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                itemCount: eventProvider!.events.length,
                                itemBuilder: (context, index) {
                                  final event = eventProvider!.events[index];
                                  print(
                                      'Event: ${event.title}, isParticipating: ${event.isParticipating}');
                                  return _buildEventCard(event);
                                },
                              ),
                            ),
                          ),
                    // Similar Traveler section
                    SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Find Your Similar Traveler",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    isLoadingUsers
                        ? const Center(child: CircularProgressIndicator())
                        : users.isEmpty
                            ? Center(child: Text("No travelers found"))
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  final user = users[index];
                                  return GestureDetector(
                                    onTap: () {
                                      print(user['_id']);
                                      // ✅ Navigate to user's profile
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TravelerProfileScreen(
                                            travelerId: user['_id'],
                                            loggedInUserId: widget.userId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      title: Text(user['name']),
                                      subtitle: Text(user['email']),
                                      leading: CircleAvatar(
                                        backgroundImage: user[
                                                        'profileImageUrl'] !=
                                                    null &&
                                                user['profileImageUrl']
                                                    .isNotEmpty
                                            ? NetworkImage(
                                                user['profileImageUrl'])
                                            : AssetImage(
                                                    'assets/default_profile.png')
                                                as ImageProvider,
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ],
                ),
              ),
      ),
    );
  }
}
