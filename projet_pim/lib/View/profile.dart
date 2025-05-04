import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/Providers/carnet_provider.dart';
import 'package:projet_pim/Providers/review_provider.dart';
import 'package:projet_pim/View/carnet&place/PlaceDetailsScreen.dart';
import 'package:projet_pim/View/follow/FollowersScreen.dart';
import 'package:projet_pim/View/follow/FollowingScreen.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:projet_pim/ViewModel/carnet_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? travelerData;
  late Future<List<Carnet>> travelerCarnets =
      Future.value([]); // Initialize as empty list
  bool isLoading = true;
  bool isFollowing = false;
  String? _userId;
  String? _token;
  UserService userService = UserService();
  CarnetProvider? carnetProvider;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    carnetProvider = Provider.of<CarnetProvider>(context, listen: false);
    _tabController = TabController(length: 3, vsync: this); // ← ajouter ça !
    fetchTravelerProfile();
    fetchFollowerData();
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

      setState(() {
        travelerData?['followers'] = followers;
        travelerData?['following'] = following;
        travelerData?['followersCount'] = followersCount;
        travelerData?['followingCount'] = followingCount;
      });
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

      setState(() {
        travelerData = traveler;
        travelerCarnets = carnetService.getUserCarnet(widget.travelerId);
        traveler['followers']?.contains(widget.loggedInUserId) ?? false;
        isFollowing = isUserFollowing; // Mise à jour du statut de suivi

        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching traveler profile: $e");
      setState(() => isLoading = false);
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
          title: const Text("Success! !"),
          content: Text(" '$placeName'  unlocked successfully!!"),
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
          title: const Text("Confirmation du déverrouillage"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Voulez-vous déverrouiller '$placeName' ?"),
              const SizedBox(height: 10),
              Text("Prix pour déverrouiller : $placePrice coins"),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Annuler"),
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
              child: const Text("Confirmer"),
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
    return "Lieu inconnu"; // Default value
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
                return const Center(
                    child: Text('Erreur de chargement des carnets'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("Aucun carnet disponible."));
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: snapshot.data!.map((carnet) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Carnet d'Adresses : ${carnet.title}",
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
                            bool isUnlocked =
                                carnetProvider.isPlaceUnlocked(place.id);

                            return Container(
                              width: 180,
                              margin: const EdgeInsets.only(right: 12),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                                                          ? place.images.first
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
                                                            ? place.images.first
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
                                      Text(
                                        place.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      if (place.categories.isNotEmpty)
                                        Wrap(
                                          spacing: 6.0,
                                          runSpacing: 4.0,
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
                                      const SizedBox(height: 10),
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
                                      const SizedBox(height: 10),
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
                                            : () async {
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
                                            ? "Voir Détails"
                                            : "Déverrouiller (${place.unlockCost} coins)"),
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

  Widget _buildInfoTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Bio: ${travelerData?['bio'] ?? "Pas de bio"}'),
          const SizedBox(height: 10),
          Text('Localisation: ${travelerData?['location'] ?? "Inconnue"}'),
        ],
      ),
    );
  }

  Widget _buildAdressesTab() {
    return FutureBuilder<List<Carnet>>(
      future: travelerCarnets,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Erreur de chargement'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucun carnet trouvé.'));
        }
        return ListView(
          scrollDirection: Axis.vertical,
          children: snapshot.data!.map((carnet) {
            return ListTile(
              title: Text(carnet.title),
              subtitle: Text('${carnet.places.length} lieux'),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAvisTab() {
    return const Center(
      child: Text('Aucun avis pour l\'instant.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final carnetProvider = Provider.of<CarnetProvider>(context, listen: true);

    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profil de l'utilisateur
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDBD9FE),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 50),
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: travelerData?['profileImage'] !=
                                      null &&
                                  travelerData!['profileImage'].isNotEmpty
                              ? NetworkImage(travelerData!['profileImage'])
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
                        travelerData?['job'] != null
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.work_outline,
                                      color: Colors.black54, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    travelerData!['job'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.work_outline,
                                      color: Colors.black54, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    "Métier inconnu",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
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
                            FutureBuilder<String>(
                              future: getLocationName(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Text(
                                    "Chargement...",
                                    style: TextStyle(
                                        color: Colors.black54, fontSize: 14),
                                  );
                                }
                                if (snapshot.hasError) {
                                  print(
                                      "❌ Error in FutureBuilder: ${snapshot.error}");
                                  return const Text(
                                    "Erreur de localisation",
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 14),
                                  );
                                }
                                print(
                                    "📍 Location displayed: ${snapshot.data}");
                                return Text(
                                  snapshot.data ?? "Lieu inconnu",
                                  style: const TextStyle(
                                      color: Colors.black54, fontSize: 14),
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
                            const SizedBox(width: 20),
                            _StatItem(
                              count: travelerData?['likes']?.toString() ?? '0',
                              label: 'Likes',
                            ),
                          ],
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
                            Tab(text: 'Infos'),
                            Tab(text: 'Adresses'),
                            Tab(text: 'Avis'),
                          ],
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildCarnetSection(),
                              _buildAdressesTab(),
                              _buildAvisTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Section Carnet d'Adresses
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
