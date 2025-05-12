import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/Model/trip.dart';
import 'package:projet_pim/Providers/carnet_provider.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/Providers/review_provider.dart';
import 'package:projet_pim/View/Event/CalendarEventsScreen.dart';
import 'package:projet_pim/View/Event/my_events_screen.dart';
import 'package:projet_pim/View/ExploreScreen.dart';
import 'package:projet_pim/View/MyTripsScreen.dart';
import 'package:projet_pim/View/TripPlanningScreen.dart';
import 'package:projet_pim/View/Widgets/custom_bottom_nav.dart';
import 'package:projet_pim/View/carnet&place/CarnetDetailsScreen.dart';
import 'package:projet_pim/View/EditProfileScreen.dart';
import 'package:projet_pim/View/Event/EventDetailsScreen.dart';
import 'package:projet_pim/View/FavoritesScreen.dart';
import 'package:projet_pim/View/carnet&place/AddPlaceScreenStep1.dart';
import 'package:projet_pim/View/carnet&place/Details.dart';
import 'package:projet_pim/View/carnet&place/PlaceDetailsScreen.dart';
import 'package:projet_pim/View/carnet&place/carnet_dtetails_screen.dart';
import 'package:projet_pim/View/chat/conversation_list_screen.dart';
import 'package:projet_pim/View/follow/FollowersScreen.dart';
import 'package:projet_pim/View/follow/FollowingScreen.dart';
import 'package:projet_pim/View/home_screen.dart';
import 'package:projet_pim/View/main_screen.dart';
import 'package:projet_pim/View/settings/settings_screen.dart';
import 'package:projet_pim/ViewModel/TripService.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:projet_pim/ViewModel/carnet_service.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/ViewModel/login.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String token;

  const UserProfileScreen(
      {required this.userId, required this.token, super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  List<Carnet> userCarnet = [];
  Map<String, dynamic>? travelerData;
  List<Trip> acceptedTrips = [];
  int _selectedIndex = 0; // 4 = Messages/Profile selon ta logique

  @override
  void initState() {
    super.initState();
    fetchUser();
    fetchFollowerData();
    fetchAcceptedTrips();
  }

  Future<void> fetchFollowerData() async {
    try {
      UserService userService = UserService();
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString("user_id");

      if (userId == null) return;

      // Fetch followers and following lists
      List<String> followers = await userService.getFollowers(userId);
      List<String> following = await userService.getFollowing(userId);

      // Fetch follower and following counts
      int followersCount = await userService.getFollowersCount(userId);
      int followingCount = await userService.getFollowingCount(userId);

      print(
          'Followers count: $followersCount, Following count: $followingCount');

      setState(() {
        // Update userData instead of travelerData
        userData?['followers'] = followers;
        userData?['following'] = following;
        userData?['followersCount'] =
            followersCount.toString(); // Convert to string
        userData?['followingCount'] = followingCount.toString();
      });
    } catch (e) {
      print("❌ Error fetching followers/following: $e");
    }
  }

  Future<void> fetchUser() async {
    try {
      // Appel pour récupérer les données utilisateur
      UserService userService = UserService();
      Map<String, dynamic> user =
          await userService.getUserById(widget.userId, widget.token);
      print('sayeeeeeeeee');
      print(user);
      userData = user;

      // Appel pour récupérer le carnet de l'utilisateur
      CarnetService carnetService = CarnetService();
      List<Carnet> carnet = await carnetService.getUserCarnet(widget.userId);

      // Fetch events
      EventProvider eventProvider =
          Provider.of<EventProvider>(context, listen: false);
      await eventProvider
          .fetchEventsCreatedByUser(widget.userId); // Remplacez par fetchEvents

      // Ensure 'location' is parsed correctly
      if (userData?['location'] != null) {
        try {
          LatLng userLocation = _parseLocation(userData!['location']);
          String address = await getAddressFromLatLng(userLocation);
          userData?['locationName'] = address;
        } catch (e) {
          print("❌ Error parsing user location: $e");
          userData?['locationName'] = "Lieu inconnu"; // Default value
        }
      }

      setState(() {
        userData = user;
        userCarnet = carnet; // Ensure userCarnet is updated correctly
        isLoading = false;
      });

      await fetchFollowerData(); // Fetch follower data after user data
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Erreur : $e');
    }
  }

  Future<void> fetchAcceptedTrips() async {
    try {
      final tripService = TripService();
      final trips = await tripService.getAcceptedTrips(widget.userId);
      setState(() {
        acceptedTrips = trips;
      });
    } catch (e) {
      print('❌ Failed to load accepted trips: $e');
    }
  }

  void _confirmerSuppression(
      BuildContext context, String carnetId, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete notebook'),
          content: const Text('Do you really want to delete this notebook?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await CarnetService().deleteCarnet(
                      carnetId, userId); // 🔥 Appel avec 2 paramètres
                  Navigator.of(context).pop(); // Fermer la boîte de dialogue
                  print("✅Notebook successfully deleted!");
                  fetchUser(); // 🔥 Rafraîchir les données après suppression
                } catch (e) {
                  print("❌ Error while deleting: $e");
                }
              },
              child: const Text('DELETE', style: TextStyle(color: Colors.red)),
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
        return "Unknown Location";
      }

      List<Placemark> placemarks =
          await placemarkFromCoordinates(location.latitude, location.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        // Extraire les informations utiles
        String street = place.thoroughfare ?? place.street ?? "Unknown street";
        String city = place.locality ?? place.subLocality ?? "Unknown city";
        String region = place.administrativeArea ?? "Unknown region";
        String country = place.country ?? "Unknown country";

        // Construire une adresse détaillée
        String formattedAddress = "$street, $city, $region, $country";
        print("✅ Geocoding successful: $formattedAddress");

        return formattedAddress;
      } else {
        print("⚠️ No placemarks found for the given coordinates.");
      }
    } catch (e) {
      print("❌ Error while geocoding : $e");
    }

    return "Unknown Location ";
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
      if (userData?['location'] != null) {
        LatLng parsedLocation = _parseLocation(userData!['location']);
        return await getAddressFromLatLng(parsedLocation);
      } else {
        print("⚠️ No location data found in userData.");
      }
    } catch (e) {
      print("❌ Error fetching location name: $e");
    }
    return "Unknown Location"; // Default value
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

  String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return ''; // Ou retourne un placeholder
    }
    if (path.startsWith('http')) {
      return path; // C’est déjà une URL
    }
    return '${ApiConstants.baseUrl}$path'; // Ex: http://localhost:3000/uploads/...
  }

  @override
  Widget build(BuildContext context) {
    final carnetProvider = Provider.of<CarnetProvider>(context, listen: true);
    final eventProvider = Provider.of<EventProvider>(context);
    final List<Widget> _pages = [
      HomeScreen(userId: widget.userId!, token: widget.token!), // index 0
      ExploreScreen(userId: widget.userId!), // index 1
      TripPlanningScreen(userId: widget.userId!), // index 2
      CalendarEventsScreen(
          userId: widget.userId!, token: widget.token!), // index 3
      ConversationListScreen(), // index 4
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(250),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          child: AppBar(
            backgroundColor: const Color(0xFFDBD9FE),
            elevation: 0,
            flexibleSpace: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Transform.translate(
                    offset: const Offset(0, 20),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: userData?['profileImage'] != null &&
                              userData!['profileImage'].isNotEmpty
                          ? NetworkImage('${ApiConstants.baseUrl}' +
                              userData!['profileImage'])
                          : const AssetImage('assets/default_profile.png')
                              as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    userData?['name'] ?? 'Unknown Name',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userData?['bio'] ?? 'bio not specified',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.work, // Icône représentant un métier
                        size: 20, // Taille de l'icône
                        color: Colors.black54, // Couleur de l'icône
                      ),
                      const SizedBox(
                          width: 4), // Espace entre l'icône et le texte
                      Text(
                        userData?['job'] ??
                            'Job not specified', // Texte du métier
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.black54,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        // ou Expanded si tu veux qu'il prenne toute la place dispo
                        child: FutureBuilder<String>(
                          future: getLocationName(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text(
                                "Loading...",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            }
                            if (snapshot.hasError) {
                              print(
                                  "❌ Error in FutureBuilder: ${snapshot.error}");
                              return const Text(
                                "Erreur de localisation",
                                style:
                                    TextStyle(color: Colors.red, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            }
                            print("📍 Location displayed: ${snapshot.data}");
                            return Text(
                              snapshot.data ?? "Unknown Location",
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 20),

                  // Container pour le fond
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 5), // Ajoute du padding autour du contenu
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                          255, 250, 195, 166), // Couleur de fond orange
                      borderRadius: BorderRadius.circular(
                          8), // Optionnel : arrondir les coins
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '💰', // Emoji de coin
                          style: TextStyle(
                            fontSize: 20, // Taille de l'emoji
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 0.1),
                        // Affichage du nombre de coins
                        Text(
                          '${userData?['coins'] ?? 0}', // Nombre de coins
                          style: const TextStyle(
                            fontSize: 20, // Taille du texte
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4F98F), // Couleur verte des coins
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 150),
                  // Bouton pour consulter les favoris
                  IconButton(
                    icon:
                        const Icon(Icons.favorite_border), // Icône des favoris
                    onPressed: () {
                      // Naviguer vers la page des favoris
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FavoritesScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.flight_takeoff), // Icon for "My Trips"
                    onPressed: () {
                      // Navigate to the "My Trips" page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyTripsScreen(
                              trips:
                                  acceptedTrips), // Passing acceptedTrips to the new screen
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () async {
                      final updatedUserData = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SettingsScreen(userData: userData),
                        ),
                      );

                      // ✅ Update UI if user data is updated
                      if (updatedUserData != null) {
                        setState(() {
                          userData = updatedUserData;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatItem(
                          count: userData?['followersCount']?.toString() ?? '0',
                          label: 'Followers',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FollowersScreen(
                                  userIds: List<String>.from(
                                      userData?['followers'] ?? []),
                                  token:
                                      widget.token, // Pass the required token
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        _StatItem(
                          count: userData?['followingCount']?.toString() ?? '0',
                          label: 'following',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FollowingScreen(
                                  userIds: List<String>.from(
                                      userData?['following'] ?? []),

                                  token:
                                      widget.token, // Pass the required token),
                                ),
                              ),
                            );
                          },
                        ),
                        /* const SizedBox(width: 20),
                        _StatItem(
                          count: userData?['likes']?.toString() ?? '0',
                          label: 'Likes',
                        ),*/
                      ],
                    ),

                    const SizedBox(height: 32),
                    userCarnet.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Column(
                              children: [
                                Text(
                                  "You haven't created an address book yet.",
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Create your first carnet now and earn 10 coins! 🎉",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          Color.fromARGB(255, 130, 130, 130)),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        // Your other widget

                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Address book',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  String carnetId = userCarnet.isNotEmpty
                                      ? userCarnet[0].id
                                      : '';
                                  switch (value) {
                                    case 'details':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CarnetDetailsPage(
                                            carnet: userCarnet[0],
                                          ),
                                        ),
                                      ).then((_) {
                                        fetchUser(); // Refresh data after return
                                      });
                                      break;

                                    case 'supprimer':
                                      _confirmerSuppression(
                                          context, carnetId, widget.userId);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'details',
                                    child: Text('View address book details'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'supprimer',
                                    child: Text('Delete address book'),
                                  ),
                                ],
                              ),
                            ],
                          ),

                    const SizedBox(height: 16),

                    // 📌 Section Carnet d’Adresses avec les données du carnet
                    SizedBox(
                      height: 30,
                      child: userCarnet.isNotEmpty
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  userCarnet[0].title ?? "Title not specified",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    buildStarRating(
                                        userCarnet[0].globalAverageRating),
                                    const SizedBox(width: 6),
                                    Text(
                                      userCarnet[0]
                                          .globalAverageRating
                                          .toStringAsFixed(1),
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : const SizedBox(),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: userCarnet.isNotEmpty &&
                              userCarnet[0].places.isNotEmpty
                          ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: userCarnet[0].places.length,
                              itemBuilder: (context, index) {
                                return AddressCard(
                                  place: userCarnet[0].places[index],
                                  fetchUser: fetchUser,
                                );
                              },
                            )
                          : userCarnet.isNotEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "No places available",
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.grey),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Add a new place and earn 5 coins! 🎉",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Color.fromARGB(
                                              255, 125, 127, 125),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox(),
// Do not display anything if no carnet exists
                    ),
                    // ✅ Floating Action Button ici
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 32),
                      child: FloatingActionButton(
                        heroTag: 'add_place_fab',
                        backgroundColor:
                            const Color.fromARGB(255, 248, 214, 253),
                        child: const Icon(Icons.add),
                        onPressed: () async {
                          await carnetProvider.checkUserCarnet(widget.userId);
                          if (carnetProvider.userCarnet == null ||
                              !carnetProvider.userCarnet!['hasCarnet']) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CreateCarnetScreen(userId: widget.userId),
                              ),
                            ).then((_) {
                              fetchUser(); // 🔥 Rafraîchir les données après la création d'un carnet
                            });
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddPlaceScreenStep1(
                                  carnetId: carnetProvider.userCarnet!['carnet']
                                      ['_id'],
                                ),
                              ),
                            ).then((_) {
                              fetchUser(); // Rafraîchir les données après l'ajout d'une place
                            });
                          }
                        },
                      ),
                    ),
                    // 📌 Section Événements
                    const SizedBox(height: 32),
                    const Text(
                      'Events',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    const SizedBox(height: 16),

                    eventProvider.events.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "No events available",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 16.0, bottom: 32),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FloatingActionButton(
                                      heroTag: 'add_event_fab',
                                      backgroundColor: const Color.fromARGB(
                                          255, 248, 214, 253),
                                      child: const Icon(Icons.add),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                MyEventsScreen(
                                              userId: widget.userId,
                                              token: widget.token,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              ...eventProvider.events
                                  .take(3)
                                  .map((event) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Card(
                                          elevation: 10,
                                          shadowColor: Colors.deepPurpleAccent
                                              .withOpacity(0.3),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Color(
                                                    0xFF161055), // 🟣 bordure violet foncé
                                                width:
                                                    2, // épaisseur du contour
                                              ),
                                            ),
                                            child: ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: const CircleAvatar(
                                                radius: 24,
                                                backgroundColor: Color.fromARGB(
                                                    255, 212, 196, 255),
                                                child: Icon(Icons.diversity_1,
                                                    color: Colors.white),
                                              ),
                                              title: Text(
                                                event.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Color(0xFF161055),
                                                ),
                                              ),
                                              subtitle: Text(
                                                event.description,
                                                style: const TextStyle(
                                                  color: Color(0xFF161055),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              trailing: const Icon(
                                                Icons.arrow_forward_ios,
                                                size: 16,
                                                color: Color(0xFF161055),
                                              ),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        EventDetailsScreen(
                                                      event: event,
                                                      userId: widget.userId,
                                                      eventProvider:
                                                          eventProvider,
                                                      token: widget.token,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList(),

                              const SizedBox(height: 16),

                              // 🔽 Bouton View all stylé
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    backgroundColor: const Color.fromARGB(
                                        255, 248, 214, 253),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 6,
                                    shadowColor: const Color(0xFFC599CD)
                                        .withOpacity(0.3),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MyEventsScreen(
                                          userId: widget.userId,
                                          token: widget.token,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.arrow_forward,
                                      color: Color.fromARGB(255, 78, 1, 96)),
                                  label: const Text(
                                    "View all",
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 78, 1, 96),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        userId: widget.userId,
        unreadNotifications: 0, // Mets ici la valeur réelle si dispo
        onItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
          });
          // Navigation en fonction de l’index
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainScreen(
                    initialIndex: 0,
                  ),
                ),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainScreen(
                    initialIndex: 1,
                  ),
                ),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainScreen(
                    initialIndex: 2,
                  ),
                ),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainScreen(
                    initialIndex: 3,
                  ),
                ),
              );
              break;
            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainScreen(
                    initialIndex: 4,
                  ),
                ),
              );
              break;
          }
        },
      ),
    );
  }
}

// 📌 Widget pour afficher les adresses
class AddressCard extends StatelessWidget {
  final Place place; // Accepting a Place object
  final VoidCallback fetchUser; // Callback to fetch user data

  const AddressCard({required this.place, required this.fetchUser, super.key});

  Future<String> getPlaceAddress() async {
    try {
      if (place.latitude != null && place.longitude != null) {
        LatLng placeLocation = LatLng(place.latitude!, place.longitude!);
        return await placemarkFromCoordinates(
                placeLocation.latitude, placeLocation.longitude)
            .then((placemarks) {
          if (placemarks.isNotEmpty) {
            return "${placemarks.first.locality}, ${placemarks.first.country}";
          }
          return "Location unknown";
        });
      }
    } catch (e) {
      print("❌ Error fetching place address: $e");
    }
    return "Location unknown"; // Default value
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to Place Details screen on tap
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Details(place: place),
          ),
        ).then((_) {
          // This will refresh the data after navigating back from Details screen
          fetchUser();
        });
      },
      child: SizedBox(
        width: 300,
        height: 300,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
              image: place.images.isNotEmpty
                  ? NetworkImage('${ApiConstants.baseUrl}' + place.images.first)
                  : const AssetImage('assets/default_image.jpg')
                      as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(63, 0, 0, 0).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        FutureBuilder<String>(
                          future: getPlaceAddress(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text(
                                "Loading...",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              );
                            }
                            if (snapshot.hasError) {
                              return const Text(
                                "Location error",
                                style:
                                    TextStyle(color: Colors.red, fontSize: 14),
                              );
                            }
                            return Text(
                              snapshot.data ?? "Unknown Location",
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  final VoidCallback? onTap;

  const _StatItem({
    required this.count,
    required this.label,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}
