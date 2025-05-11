import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/Providers/carnet_provider.dart';
import 'package:projet_pim/View/carnet&place/PlaceDetailsScreen.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:projet_pim/ViewModel/carnet_service.dart';
import 'package:projet_pim/ViewModel/weather_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherScreen extends StatefulWidget {
  final String userId;
  const WeatherScreen({required this.userId});

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  CarnetProvider? provider;

  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? weatherData;
  List<Place> places =
      []; // Liste pour stocker les lieux selon les catégories météo
  String? userId;
  String? token;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _loadUserData();
    if (userId != null) {
      _getCurrentLocation();
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? _userId = prefs.getString("user_id");
    String? _token = prefs.getString("jwt_token");

    if (_userId != null && _token != null) {
      setState(() {
        userId = _userId;
        token = _token;
      });
    } else {
      print("User ID or Token is not available");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifiez si les services de localisation sont activés
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Si les services de localisation ne sont pas activés, afficher une erreur
      print('Les services de localisation ne sont pas activés');
      return;
    }

    // Vérifiez les permissions de localisation
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Si la permission est refusée, demandez-la
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Si l'utilisateur refuse encore la permission
        print('La permission d\'accès à la localisation est refusée');
        return;
      }
    }

    // Si la permission est autorisée, récupérez la position actuelle
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _loadWeather(position.latitude, position.longitude);
  }

  void _loadWeather(double latitude, double longitude) async {
    try {
      final data =
          await _weatherService.fetchWeatherByCoordinates(latitude, longitude);
      setState(() {
        weatherData = data;
        isLoading = false;
      });

      // Extraire la condition météo
      String weatherCondition = weatherData!['weather'][0]['main'];
      _loadPlacesBasedOnWeather(weatherCondition);
    } catch (e) {
      print("Erreur de chargement de la météo : $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fonction pour charger les lieux en fonction de la météo
  void _loadPlacesBasedOnWeather(String weatherCondition) async {
    List<String> categories = [];

    // Décider des catégories selon la condition météorologique
    if (weatherCondition == 'Clear') {
      categories = ['Sports', 'Food', 'Plages', 'Aventure', 'Nature', 'Plages'];
    } else if (weatherCondition == 'Rain') {
      categories = [
        'Shopping',
        'Café',
        'Culture',
        'Food',
        'Musique Live',
        'Art & Expositions'
      ];
    } else if (weatherCondition == 'Clouds') {
      categories = [
        'Indoor',
        'Sports',
        'Café',
        'Food',
        'Yoga & Bien-être',
        'Relaxation'
      ];
    } else {
      categories = ['Food', 'Food', 'Transport', 'Nightlife'];
    }

    // Charger les lieux selon les catégories
    final fetchedPlaces = await _fetchPlacesByCategories(categories);
    setState(() {
      places = fetchedPlaces;
    });
  }

  // Update this method to handle multiple categories.
  Future<List<Place>> _fetchPlacesByCategories(List<String> categories) async {
    List<Place> allPlaces = [];

    for (var category in categories) {
      try {
        final places = await CarnetService().getPlacesByCategory(category);
        print('Fetched places for category $category: $places'); // Debugging
        allPlaces.addAll(places);
      } catch (e) {
        print("Error fetching places for category $category: $e");
      }
    }

    return allPlaces;
  }

  void _reloadData() async {
    if (provider != null) {
      await provider!.fetchCarnetsExcludingUser(widget.userId);
      await provider!.fetchUnlockedPlaces(widget.userId);

      if (mounted) {
        setState(() {
          // Recharger les lieux basés sur la météo
          _loadPlacesBasedOnWeather(weatherData!['weather'][0]['main']);
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    provider ??= Provider.of<CarnetProvider>(context, listen: false);
  }

  void _showConfirmUnlockDialog(String placeName, int placePrice, var place) {
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
                  // Check if provider is null
                  if (provider == null) {
                    _showErrorDialog('Provider is missing.');
                    return;
                  }

                  // Check if place is null
                  if (place == null) {
                    _showErrorDialog('Place information is missing.');
                    return;
                  }

                  // Ensure place.id is valid and use the correct method
                  String placeId = place.id; // Assuming place has an 'id' field
                  print('Unlocking place with ID: $placeId'); // Debugging
                  print('User ID: $userId'); // Debugging
                  await provider!
                      .unlockPlace(userId!, placeId); // Déverrouiller l'endroit

                  // Fetch unlocked places
                  await provider!.fetchUnlockedPlaces(userId!);

                  // Reload the entire page
                  await _initializeScreen();

                  if (mounted) {
                    setState(() {
                      // Trigger a rebuild
                    });
                    _showUnlockDialog(
                        placeName); // Afficher le message de succès après la mise à jour
                  }

                  // Navigate back to HomeScreen
                  Navigator.of(context).pop(); // Close the WeatherScreen
                } catch (e) {
                  // Show error dialog if something goes wrong
                  print('Error: $e'); // Debugging
                  _showErrorDialog(
                      'Unable to unlock. Missing required information.');
                }
              },
              child: Text("Confirm"),
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

  // Widget pour afficher les informations météo
  Widget _weatherInfoTile(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 40),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
      ],
    );
  }

  // Fonction pour formater l'heure (lever et coucher du soleil)
  String _formatTime(int timestamp) {
    DateTime time = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat.Hm().format(time);
  }

  // Widget pour afficher la liste des lieux
  Widget _buildPlacesList(List<Place> places) {
    final carnetProvider = Provider.of<CarnetProvider>(context, listen: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 20,
        ),
        Text(
          "Lieux à visiter selon la météo",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: places.map((place) {
              bool isUnlocked = carnetProvider.isPlaceUnlocked(place.id);

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 5,
                child: Container(
                  width: 200,
                  height: 320, // Hauteur fixe pour toutes les cartes
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color.fromARGB(234, 249, 225, 225),
                  ),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween, // Répartition uniforme
                    children: [
                      // Image avec flou si non débloquée
                      if (place.images.isNotEmpty)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: isUnlocked
                                  ? Image.network(
                                      '${ApiConstants.baseUrl}' +
                                          place.images.first,
                                      width: 160,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Icon(Icons.broken_image,
                                            size: 50, color: Colors.grey);
                                      },
                                    )
                                  : ImageFiltered(
                                      imageFilter: ImageFilter.blur(
                                          sigmaX: 5, sigmaY: 5),
                                      child: Image.network(
                                        '${ApiConstants.baseUrl}' +
                                            place.images.first,
                                        width: 160,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(Icons.broken_image,
                                              size: 50, color: Colors.grey);
                                        },
                                      ),
                                    ),
                            ),
                            if (!isUnlocked)
                              Positioned(
                                top: 40,
                                left: 55,
                                child: Icon(
                                  Icons.lock,
                                  size: 40,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                          ],
                        )
                      else
                        Icon(Icons.broken_image, size: 50, color: Colors.grey),

                      // Nom du lieu
                      Text(
                        place.name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),

                      // Description ou message par défaut
                      Text(
                        place.description ?? 'No description available',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Bouton : voir ou déverrouiller
                      ElevatedButton(
                        onPressed: isUnlocked
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlaceDetailsScreen(
                                      place: place,
                                    ),
                                  ),
                                );
                              }
                            : () async {
                                _showConfirmUnlockDialog(
                                  place.name,
                                  place.unlockCost,
                                  place,
                                );
                              },
                        child:
                            Text(isUnlocked ? "Voir détails" : "Déverrouiller"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isUnlocked
                              ? Color(0xFF9E9E9E)
                              : Color(0xFFD4F98F),
                          padding: EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCEFEF),
      appBar: AppBar(
        title: Text("Météo d'aujourd'hui"),
        backgroundColor: const Color(0xFFDBD9FE),
        elevation: 0,
      ),
      body: weatherData == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Informations sur la météo
                    Column(
                      children: [
                        Text(
                          "${weatherData!['name']}, ${weatherData!['sys']['country']}",
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        SizedBox(height: 10),
                        Image.network(
                          "https://openweathermap.org/img/wn/${weatherData!['weather'][0]['icon']}@2x.png",
                          width: 120,
                          height: 120,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "${weatherData!['weather'][0]['description']}",
                          style:
                              TextStyle(fontSize: 20, color: Colors.grey[700]),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Détails de la météo
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              "${weatherData!['main']['temp']}°C",
                              style: TextStyle(
                                  fontSize: 50,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF161055)),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Température ressentie : ${weatherData!['main']['feels_like']}°C",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey[600]),
                            ),
                            Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text("Min",
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.grey)),
                                    Text(
                                        "${weatherData!['main']['temp_min']}°C",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text("Max",
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.grey)),
                                    Text(
                                        "${weatherData!['main']['temp_max']}°C",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Autres infos météo (Humidité, Vent)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _weatherInfoTile(Icons.water_drop, "Humidité",
                            "${weatherData!['main']['humidity']}%"),
                        _weatherInfoTile(Icons.air, "Vent",
                            "${weatherData!['wind']['speed']} km/h"),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Infos sur le lever et coucher du soleil
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Icon(Icons.wb_sunny,
                                    color: Colors.orange, size: 35),
                                Text("Lever du soleil",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey)),
                                Text(
                                    _formatTime(weatherData!['sys']['sunrise']),
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.nightlight_round,
                                    color: Colors.blueAccent, size: 35),
                                Text("Coucher du soleil",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey)),
                                Text(_formatTime(weatherData!['sys']['sunset']),
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Affichage des lieux selon la météo
                    _buildPlacesList(places),
                  ],
                ),
              ),
            ),
    );
  }
}
