import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/View/CalendarEventsScreen.dart';
import 'package:projet_pim/View/carnet&place/AddPlaceScreenStep1.dart';
import 'package:projet_pim/View/carnet&place/PlaceDetailsScreen.dart';
import 'package:projet_pim/View/carnet&place/carnet_dtetails_screen.dart';
import 'package:projet_pim/View/chat/group_chat_screen.dart';
import 'package:projet_pim/View/profile.dart';
import 'package:projet_pim/View/select_location_screen.dart';
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
  final dateFormat = DateFormat('dd MMM yyyy');

  List<dynamic> users = [];
  bool isLoadingUsers = true;
  late Animation<double> _cardFadeAnimation;
  late AnimationController _cardAnimationController;

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

  Future<String> getAddressFromStringCoords(String coords) async {
    try {
      final parts = coords.split(',');
      if (parts.length != 2) return "Coordonnées invalides";

      final lat = double.parse(parts[0]);
      final lng = double.parse(parts[1]);
      return await getAddressFromLatLng(lat, lng);
    } catch (e) {
      print("Erreur lors de la conversion des coordonnées : $e");
      return "Adresse inconnue";
    }
  }

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.locality}, ${place.country}"; // Example: Paris, France
      }
    } catch (e) {
      print("Erreur de conversion: $e");
    }
    return "Localisation inconnue";
  }

  void _showCreateEventDialog() {
    String title = '';
    String description = '';
    DateTime? startDate;
    DateTime? endDate;
    String location =
        ''; // La variable location stockera uniquement les coordonnées
    int joinPrice = 5; // Default join price
    String selectedType = _eventTypes.first; // Default type
    bool _useAutoLocation = false; // Default location usage

    TextEditingController locationController = TextEditingController();

    // Fonction pour obtenir la localisation automatique et l'afficher dans le TextField
    Future<void> _getLocation() async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Utilisation de getAddressFromLatLng pour récupérer l'adresse à partir des coordonnées
        String address =
            await getAddressFromLatLng(position.latitude, position.longitude);

        setState(() {
          location =
              "${position.latitude},${position.longitude}"; // Stocke les coordonnées
          locationController.text =
              address; // Affiche l'adresse dans le TextField
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Impossible de récupérer la localisation!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Fonction pour ouvrir la carte et sélectionner une localisation
    void _openMapToSelectLocation() async {
      LatLng? selectedLocation = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SelectLocationScreen()),
      );

      if (selectedLocation != null) {
        // Utilisation de getAddressFromLatLng pour récupérer l'adresse sélectionnée
        String address = await getAddressFromLatLng(
            selectedLocation.latitude, selectedLocation.longitude);

        setState(() {
          location =
              "${selectedLocation.latitude},${selectedLocation.longitude}"; // Stocke les coordonnées
          locationController.text =
              address; // Affiche l'adresse dans le TextField
        });
      }
    }

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
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Utiliser ma localisation automatique"),
                  Switch(
                    value: _useAutoLocation,
                    onChanged: (value) {
                      setState(() {
                        _useAutoLocation = value;
                        if (value) _getLocation();
                      });
                    },
                  ),
                ],
              ),
              TextField(
                controller: locationController,
                decoration:
                    InputDecoration(labelText: "Localisation (adresse)"),
                readOnly: true,
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                icon: Icon(Icons.map),
                label: Text("Sélectionner sur la carte"),
                onPressed: _openMapToSelectLocation,
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: 'Join Price (coins)'),
                keyboardType: TextInputType.number,
                onChanged: (value) => joinPrice = int.tryParse(value) ?? 5,
              ),
              SizedBox(height: 10),
              // Dropdown pour le type d'événement
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
              // Choisir la date et l'heure de début
              ElevatedButton(
                onPressed: () async {
                  final pickedStartDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedStartDate != null) {
                    final pickedStartTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedStartTime != null) {
                      setState(() {
                        startDate = DateTime(
                          pickedStartDate.year,
                          pickedStartDate.month,
                          pickedStartDate.day,
                          pickedStartTime.hour,
                          pickedStartTime.minute,
                        );
                      });
                    }
                  }
                },
                child: Text('Pick Start Date & Time'),
              ),
              // Choisir la date et l'heure de fin
              ElevatedButton(
                onPressed: () async {
                  final pickedEndDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedEndDate != null) {
                    final pickedEndTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedEndTime != null) {
                      setState(() {
                        endDate = DateTime(
                          pickedEndDate.year,
                          pickedEndDate.month,
                          pickedEndDate.day,
                          pickedEndTime.hour,
                          pickedEndTime.minute,
                        );
                      });
                    }
                  }
                },
                child: Text('Pick End Date & Time'),
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
              if (title.isNotEmpty &&
                  location.isNotEmpty &&
                  startDate != null &&
                  endDate != null &&
                  endDate!.isAfter(startDate!)) {
                eventProvider!.createEvent(
                  widget.userId,
                  title,
                  description,
                  startDate!.toIso8601String(), // Include time
                  endDate!.toIso8601String(), // Include time
                  location, // Envoie uniquement les coordonnées
                  joinPrice,
                  selectedType,
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text("Please select valid start and end dates.")),
                );
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
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
                  'From: ${dateFormat.format(event.startDate)} to ${dateFormat.format(event.endDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: FutureBuilder<String>(
                  future: getAddressFromStringCoords(
                      '${event.location.latitude},${event.location.longitude}'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text(
                        "Chargement de l'adresse...",
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      );
                    }
                    if (snapshot.hasError) {
                      return Text(
                        "Erreur de localisation",
                        style: TextStyle(fontSize: 12, color: Colors.redAccent),
                      );
                    }
                    return Text(
                      "Lieu : ${snapshot.data}",
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    );
                  },
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

  @override
  Widget build(BuildContext context) {
    final carnetProvider = Provider.of<CarnetProvider>(context, listen: true);
    final otherCarnets =
        carnetProvider.carnets.where((c) => c.owner != widget.userId).toList();
    final eventProvider = Provider.of<EventProvider>(context, listen: true);

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
                                                weatherData:
                                                    weatherData ?? {})),
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
                          // Bouton pour accéder à la page RecommendationsScreen
                          SizedBox(height: 20),
                          Center(
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              CalendarEventsScreen()),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(50),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Color.fromARGB(255, 246, 171, 229),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.purple.withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.all(16),
                                    child: Icon(
                                      Icons.calendar_today,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Recommandations',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color.fromARGB(
                                          255, 246, 171, 229)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text("Near Your Location",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    otherCarnets.isEmpty
                        ? Center(child: Text("No other carnets available"))
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
                                  itemCount: otherCarnets.length,
                                  itemBuilder: (context, index) {
                                    final carnet = otherCarnets[index];
                                    return Column(
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
                                                carnet.places.map((place) {
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
