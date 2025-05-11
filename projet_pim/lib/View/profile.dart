import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/Providers/carnet_provider.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/Providers/review_provider.dart';
import 'package:projet_pim/View/Event/EventDetailsScreen.dart';
import 'package:projet_pim/View/carnet&place/PlaceDetailsScreen.dart';
import 'package:projet_pim/View/chat/group_chat_screen.dart';
import 'package:projet_pim/View/follow/FollowersScreen.dart';
import 'package:projet_pim/View/follow/FollowingScreen.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:projet_pim/ViewModel/carnet_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class TravelerProfileScreen extends StatefulWidget {
  final String travelerId;
  final String loggedInUserId;
  final String token;

  const TravelerProfileScreen(
      {required this.travelerId,
      required this.loggedInUserId,
      required this.token,
      super.key});

  @override
  _TravelerProfileScreenState createState() => _TravelerProfileScreenState();
}

class _TravelerProfileScreenState extends State<TravelerProfileScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  Map<String, dynamic>? travelerData;
  late Future<List<Carnet>> travelerCarnets =
      Future.value([]); // Initialize as empty list
  bool isLoading = true;
  bool isFollowing = false;
  String? _userId;
  String? _token;
  late EventProvider _eventProvider;
  UserService userService = UserService();
  CarnetProvider? carnetProvider;
  late TabController _tabController;
  List<Event> travelerEvents = [];

  @override
  void initState() {
    super.initState();
    carnetProvider = Provider.of<CarnetProvider>(context, listen: false);
    _tabController = TabController(length: 3, vsync: this); // ← ajouter ça !
    _eventProvider = EventProvider(userId: widget.loggedInUserId);
    fetchTravelerProfile();
    fetchFollowerData();
    fetchTravelerRating();
    fetchTravelerEvents();
    WidgetsBinding.instance.addObserver(this); // Add observer
    WidgetsBinding.instance.addPostFrameCallback((_) => fetchTravelerEvents());
  }

  Future<void> fetchTravelerEvents() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/events/user/${widget.travelerId}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            travelerEvents = data
                .map((e) => Event.fromJson(e, widget.loggedInUserId))
                .toList();
          });
        }
      } else {
        print('Erreur lors du chargement des événements: ${response.body}');
      }
    } catch (e) {
      print('Erreur : $e');
    }
  }

  Widget _buildEventsTab() {
    if (travelerEvents.isEmpty) {
      return const Center(child: Text("Aucun événement trouvé."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: travelerEvents.length,
      itemBuilder: (context, index) {
        final event = travelerEvents[index];
        return _buildStyledEventCard(event);
      },
    );
  }

  Future<String> _getEventLocationName(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.locality}, ${place.country}";
      }
    } catch (e) {
      print("Reverse geocoding error: $e");
    }
    return "Unknown place";
  }

  Widget _buildStyledEventCard(Event event) {
    bool isParticipating = event.isParticipating;

    return FutureBuilder<String>(
      future: _getEventLocationName(event.location),
      builder: (context, snapshot) {
        String locationName = snapshot.data ?? "Fetching location...";

        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF161055), width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF161055),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  event.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF161055)),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: Color(0xFF161055)),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(event.startDate),
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF161055)),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on,
                      size: 14, color: Color(0xFF161055)),
                  const SizedBox(width: 6),
                  Text(
                    locationName,
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF161055)),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (isParticipating) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GroupChatScreen(
                                eventProvider: EventProvider(
                                    userId: widget.loggedInUserId),
                                conversationId: event.conversationId ?? "",
                                groupName: event.title,
                                userId: widget.loggedInUserId,
                              ),
                            ),
                          );
                        } else {
                          // Optionally, show message or dialog
                          _showJoinConfirmationDialog(event);
                          fetchTravelerEvents();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isParticipating
                            ? const Color(0xFF9680D4)
                            : const Color.fromARGB(198, 243, 199, 249),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isParticipating ? "Join Chat" : "Join Event"),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz),
                      onPressed: () async {
                        if (isParticipating) {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailsScreen(
                                event: event,
                                userId: widget.loggedInUserId,
                                token: widget.token,
                                eventProvider: EventProvider(
                                    userId: widget.loggedInUserId),
                              ),
                            ),
                          );

                          // 🔁 Refresh traveler events if something changed
                          await fetchTravelerEvents();
                          if (result != null && result) {
                            fetchTravelerEvents();
                          }
                        } else {
                          showDialog(
                            context: context,
                            builder: (_) => const AlertDialog(
                              title: Text("Access Denied"),
                              content: Text(
                                  "Want the inside scoop? Join the event first!"),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showJoinConfirmationDialog(Event event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Ready to Join?"),
          content:
              Text("It’s just ${event.joinPrice} coins to join the event!"),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("Cancel")),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // close dialog first
                try {
                  await _eventProvider.joinEvent(
                      widget.loggedInUserId, event.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("✅You're part of the event now! 🙌")),
                  );
                  fetchTravelerEvents();
                } catch (e) {
                  final error = e.toString();
                  if (error.contains("Insufficient coins")) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text("Oops, not enough coins to join this event."),
                      ),
                    );
                  }
                }
                fetchTravelerEvents();
              },
              child: const Text("Confirm"),
            )
          ],
        );
      },
    );
  }

  Future<void> fetchFollowerData() async {
    try {
      List<String> followers =
          await userService.getFollowers(widget.travelerId);
      List<String> following =
          await userService.getFollowing(widget.travelerId);
      int followersCount =
          await userService.getFollowersCount(widget.travelerId);
      int followingCount =
          await userService.getFollowingCount(widget.travelerId);

      if (mounted) {
        setState(() {
          travelerData?['followers'] = followers;
          travelerData?['following'] = following;
          travelerData?['followersCount'] = followersCount;
          travelerData?['followingCount'] = followingCount;
        });
      }
    } catch (e) {
      print("❌ Error fetching followers/following: $e");
    }
  }

  Future<void> fetchTravelerProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString("user_id");
      _token = prefs.getString("jwt_token");

      // Récupérer les données de l'utilisateur
      Map<String, dynamic> traveler =
          await userService.getUserById(widget.travelerId, _token!);

      // Assurez-vous que carnetService est bien défini et initialisé
      CarnetService carnetService = CarnetService();

      travelerCarnets = carnetService.getUserCarnet(widget.travelerId);

// Fetch unlocked places for the user
      if (_userId != null) {
        await carnetProvider?.fetchUnlockedPlaces(_userId!);
      }
      // Vérifier si l'utilisateur connecté suit déjà le voyageur
      List<String> followers =
          await userService.getFollowers(widget.travelerId);
      bool isUserFollowing = followers.contains(widget.loggedInUserId);

      if (mounted) {
        setState(() {
          travelerData = traveler;
          travelerCarnets = carnetService.getUserCarnet(widget.travelerId);
          traveler['followers']?.contains(widget.loggedInUserId) ?? false;
          isFollowing = isUserFollowing; // Mise à jour du statut de suivi

          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching traveler profile: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _reloadData() async {
    if (_userId != null) {
      await carnetProvider?.fetchUnlockedPlaces(_userId!);
      setState(() {
        // Force the UI to update based on the latest data
      });
    }
  }

  Future<void> toggleFollow() async {
    try {
      if (isFollowing) {
        await userService.unfollowUser(
            widget.loggedInUserId, widget.travelerId);
      } else {
        await userService.followUser(widget.loggedInUserId, widget.travelerId);
      }

      await fetchFollowerData();

      setState(() {
        isFollowing = !isFollowing;
      });
    } catch (e) {
      print("❌ Error following/unfollowing user: $e");
    }
  }

  Future<void> openMap(double latitude, double longitude) async {
    final url =
        'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude#map=16/$latitude/$longitude';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Impossible d\'ouvrir la carte';
    }
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

  void _showUnlockDialog(String placeName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Unlocked!"),
          content: Text("You’ve unlocked '$placeName' — time to explore! !"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    String displayMessage;
    if (message.contains("Not enough coins")) {
      displayMessage = "You don't have enough coins to unlock this place.";
    } else if (message.contains("Failed to unlock place")) {
      displayMessage = "You don't have enough coins to unlock this place.";
    } else {
      displayMessage = message;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Oops! You're Short on Coins"),
          content: Text(displayMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
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
          title: const Text("Unlock Confirmation"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Are you ready to unlock '$placeName'?"),
              const SizedBox(height: 10),
              Text("It’s just $placePrice coins!"),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                try {
                  // Use the logged-in user ID to unlock the place
                  if (_userId != null) {
                    await carnetProvider?.unlockPlace(_userId!, place.id);
                    _showUnlockDialog(placeName);
                    _reloadData();
                  } else {
                    _showErrorDialog("Utilisateur non connecté.");
                  }
                } catch (e) {
                  _showErrorDialog(e.toString());
                }
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  Future<String> getAddressFromLatLng(LatLng location) async {
    try {
      print(
          "🌍 Fetching address for coordinates: ${location.latitude}, ${location.longitude}");

      if (location.latitude == 0.0 && location.longitude == 0.0) {
        print(
            "⚠️ Invalid coordinates: ${location.latitude}, ${location.longitude}");
        return "Unknown place";
      }

      List<Placemark> placemarks =
          await placemarkFromCoordinates(location.latitude, location.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // Extraire les informations utiles
        String street = place.thoroughfare ?? place.street ?? "Unknown street";
        String city = place.locality ?? place.subLocality ?? "Unknown city";
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

    return "Unknown place";
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
    return const LatLng(0, 0); // Default value
  }

  Future<String> getLocationName() async {
    try {
      if (travelerData?['location'] != null) {
        LatLng parsedLocation = _parseLocation(travelerData!['location']);
        return await getAddressFromLatLng(parsedLocation);
      } else {
        print("⚠️ No location data found in userData.");
      }
    } catch (e) {
      print("❌ Error fetching location name: $e");
    }
    return "Unknown place"; // Default value
  }

  Widget buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (index < rating && rating - index < 1) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 20);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 20);
        }
      }),
    );
  }

  Widget _buildCarnetSection() {
    final carnetProvider = Provider.of<CarnetProvider>(context, listen: true);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<List<Carnet>>(
            future: travelerCarnets,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Error loading address books'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No address book available."));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: snapshot.data!.map((carnet) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        "Address Book : ${carnet.title}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: carnet.places.map((place) {
                            // Automatically unlock the first two places
                            final index = carnet.places.indexOf(place);
                            final isUnlocked = index < 2 ||
                                carnetProvider.isPlaceUnlocked(place.id);

                            return SizedBox(
                              width: 180,
                              height: 300,
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(
                                        height: 120,
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: isUnlocked
                                                  ? Image.network(
                                                      place.images.isNotEmpty
                                                          ? '${ApiConstants.baseUrl}${place.images.first}'
                                                          : '',
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return const Icon(
                                                            Icons.broken_image,
                                                            size: 50,
                                                            color: Colors.grey);
                                                      },
                                                    )
                                                  : ImageFiltered(
                                                      imageFilter:
                                                          ImageFilter.blur(
                                                              sigmaX: 5,
                                                              sigmaY: 5),
                                                      child: Image.network(
                                                        place.images.isNotEmpty
                                                            ? '${ApiConstants.baseUrl}${place.images.first}'
                                                            : '',
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context,
                                                            error, stackTrace) {
                                                          return const Icon(
                                                              Icons
                                                                  .broken_image,
                                                              size: 50,
                                                              color:
                                                                  Colors.grey);
                                                        },
                                                      ),
                                                    ),
                                            ),
                                            if (!isUnlocked)
                                              const Positioned.fill(
                                                child: Center(
                                                  child: Icon(Icons.lock,
                                                      color: Colors.white,
                                                      size: 40),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: Text(
                                          place.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (place.categories.isNotEmpty)
                                        Wrap(
                                          spacing: 6.0,
                                          runSpacing: 4.0,
                                          alignment: WrapAlignment.center,
                                          children:
                                              place.categories.map((category) {
                                            return Chip(
                                              label: Text(
                                                category,
                                                style: const TextStyle(
                                                    fontSize: 10),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 0),
                                              backgroundColor:
                                                  Colors.deepPurple[100],
                                              visualDensity:
                                                  VisualDensity.compact,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            );
                                          }).toList(),
                                        ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          buildStarRating(place.averageRating),
                                          const SizedBox(width: 6),
                                          Text(
                                            place.averageRating
                                                .toStringAsFixed(1),
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                      ElevatedButton(
                                        onPressed: isUnlocked
                                            ? () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        Builder(
                                                      builder: (newContext) =>
                                                          ChangeNotifierProvider<
                                                              ReviewProvider>(
                                                        create: (_) =>
                                                            ReviewProvider(),
                                                        child:
                                                            PlaceDetailsScreen(
                                                                place: place),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                            : () {
                                                _showConfirmUnlockDialog(
                                                    place.name,
                                                    place.unlockCost,
                                                    place);
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isUnlocked
                                              ? const Color(0xFF9E9E9E)
                                              : const Color(0xFFD4F98F),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          textStyle:
                                              const TextStyle(fontSize: 12),
                                        ),
                                        child: Text(isUnlocked
                                            ? "View Details"
                                            : "Unlock (${place.unlockCost} coins)"),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  double? travelerAverageRating;

  Future<void> fetchTravelerRating() async {
    final response = await http.get(
      Uri.parse(
          '${ApiConstants.baseUrl}/carnets/total-rating/${widget.travelerId}'),
      headers: {"Authorization": "Bearer ${widget.token}"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (mounted) {
        setState(() {
          travelerAverageRating = data['averageRating']?.toDouble();
        });
      }
    }
  }

  Future<Map<String, dynamic>> fetchPublicProfile(String userId) async {
    final response = await http
        .get(Uri.parse('${ApiConstants.baseUrl}/users/$userId/public-profile'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load public profile");
    }
  }

  Widget _buildInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ⭐ Note moyenne
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 22),
              const SizedBox(width: 6),
              Text(
                travelerAverageRating != null
                    ? travelerAverageRating!.toStringAsFixed(2)
                    : '0.0',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              const Text("Average Rating"),
            ],
          ),
          const Divider(height: 30),

          // 🧑‍💼 Job
          Row(
            children: [
              const Icon(Icons.work_outline, color: Colors.black54, size: 20),
              const SizedBox(width: 8),
              Text(
                travelerData?['job'] ?? 'Unknown job',
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 📍 Localisation
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.black54, size: 20),
              const SizedBox(width: 8),
              Expanded(
                // 🔥 C'est ce qui empêche le débordement
                child: FutureBuilder<String>(
                  future: getLocationName(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text("Loading...");
                    }
                    if (snapshot.hasError) {
                      return const Text("Unknown location");
                    }
                    return Text(
                      snapshot.data ?? "Unknown location",
                      style: const TextStyle(fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2, // ou 3 si tu veux encore plus de marge
                    );
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 30),

          // ✍️ Bio
          const Text("Bio:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            travelerData?['bio']?.toString().trim().isEmpty == false
                ? travelerData!['bio']
                : "No bio provided.",
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const Divider(height: 30),

          // 🧠 Tags
          if (travelerData?['tags'] != null &&
              (travelerData!['tags'] as List).isNotEmpty) ...[
            const Text("Interests:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List<String>.from(travelerData!['tags']).map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: const Color(0xFFE0E0F8),
                  labelStyle: const TextStyle(
                      color: Color(0xFF3B3B7A), fontWeight: FontWeight.w500),
                );
              }).toList(),
            ),
          ] else
            const Text("No interests shared."),
        ],
      ),
    );
  }

  Widget _buildAvisTab() {
    return Column(
      children: [
        Text('⭐'),
        Text(
          travelerAverageRating != null
              ? travelerAverageRating.toString()
              : '0.0',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text('Rating', style: TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final carnetProvider = Provider.of<CarnetProvider>(context, listen: true);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFDBD9FE),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  // Profil de l'utilisateur
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFDBD9FE),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: travelerData?['profileImage'] !=
                                      null &&
                                  travelerData!['profileImage'].isNotEmpty
                              ? NetworkImage('${ApiConstants.baseUrl}' +
                                  travelerData!['profileImage'])
                              : const AssetImage('assets/default_profile.png')
                                  as ImageProvider,
                        ),
                        travelerData?['name'] != null
                            ? Text(
                                travelerData!['name'],
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              )
                            : const Text("Nom inconnu"),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StatItem(
                              count:
                                  travelerData?['followersCount']?.toString() ??
                                      '0',
                              label: 'Followers',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FollowersScreen(
                                      userIds: List<String>.from(
                                          travelerData?['followers'] ?? []),
                                      token: widget
                                          .token, // Pass the required token
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 20),
                            _StatItem(
                              count:
                                  travelerData?['followingCount']?.toString() ??
                                      '0',
                              label: 'following',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FollowingScreen(
                                      userIds: List<String>.from(
                                          travelerData?['following'] ?? []),

                                      token: widget
                                          .token, // Pass the required token),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing
                                ? const Color(0x0f6f6666)
                                : const Color(0xFFD4F98F),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(isFollowing ? "Unfollow" : "Follow"),
                        ),
                      ],
                    ),
                  ),

                  SingleChildScrollView(
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          labelColor: Colors.black,
                          indicatorColor: Colors.deepPurple,
                          tabs: const [
                            Tab(text: 'Places'),
                            Tab(text: 'Events'),
                            Tab(text: 'Info'),
                          ],
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildCarnetSection(),
                              _buildEventsTab(),
                              _buildInfoTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Section Address Book
                ],
              ),
            ),
    );
  }
}

class PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;

  const PlaceCard({super.key, required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.place,
              color: Colors.blue,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              place.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              place.description ?? 'No description',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class LockedPlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onUnlock;

  const LockedPlaceCard(
      {super.key, required this.place, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock,
            color: Colors.red,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            place.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            place.description ?? 'No description',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onUnlock,
            child: Text("Unlock (${place.unlockCost} coins)"),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  final VoidCallback? onTap; // Added onTap parameter
  const _StatItem({required this.count, required this.label, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Handle onTap
      child: Column(
        children: [
          Text(count,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
