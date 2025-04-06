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
      Key? key})
      : super(key: key);

  @override
  _TravelerProfileScreenState createState() => _TravelerProfileScreenState();
}

class _TravelerProfileScreenState extends State<TravelerProfileScreen> {
  Map<String, dynamic>? travelerData;
  late Future<List<Carnet>> travelerCarnets =
      Future.value([]); // Initialize as empty list
  bool isLoading = true;
  bool isFollowing = false;
  String? _userId;
  String? _token;
  UserService userService = UserService();
  CarnetProvider? carnetProvider;

  @override
  void initState() {
    super.initState();
    carnetProvider = Provider.of<CarnetProvider>(context, listen: false);

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
          title: Text("Succès !"),
          content: Text("Vous avez déverrouillé '$placeName' !"),
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
          title: Text("Erreur"),
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
          title: Text("Confirmation du déverrouillage"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Voulez-vous déverrouiller '$placeName' ?"),
              SizedBox(height: 10),
              Text("Prix pour déverrouiller : $placePrice coins"),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Annuler"),
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
              child: Text("Confirmer"),
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
    return LatLng(0, 0); // Default value
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

  @override
  Widget build(BuildContext context) {
    final carnetProvider = Provider.of<CarnetProvider>(context, listen: true);

    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profil de l'utilisateur
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
                      children: [
                        SizedBox(height: 50),
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
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              )
                            : Text("Nom inconnu"),
                        travelerData?['job'] != null
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.work_outline,
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
                        SizedBox(height: 10),
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
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing
                                ? Color(0xF6F6666)
                                : Color(0xFFD4F98F),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(isFollowing ? "Unfollow" : "Follow"),
                        ),
                        SizedBox(height: 10),
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
                            SizedBox(width: 20),
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
                            SizedBox(width: 20),
                            _StatItem(
                              count: travelerData?['likes']?.toString() ?? '0',
                              label: 'Likes',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Section Carnet d'Adresses
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Carnet d'Adresses",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        FutureBuilder<List<Carnet>>(
                          future: travelerCarnets,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error loading carnets'));
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(child: Text("No carnet available"));
                            }

                            return Column(
                              children: snapshot.data!.map((carnet) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      carnet.title,
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 10),

                                    // Liste des places affichées horizontalement
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: carnet.places.map((place) {
                                          bool isUnlocked = carnetProvider
                                              .isPlaceUnlocked(place.id);

                                          return Card(
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 10),
                                            child: Container(
                                              width: 190, // Largeur de la carte
                                              padding: EdgeInsets.all(10),
                                              child: Column(
                                                children: [
                                                  if (place.images.isNotEmpty)
                                                    Stack(
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          child: isUnlocked
                                                              ? Image.network(
                                                                  place.images
                                                                      .first,
                                                                  width: 140,
                                                                  height: 120,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  errorBuilder:
                                                                      (context,
                                                                          error,
                                                                          stackTrace) {
                                                                    return Icon(
                                                                        Icons
                                                                            .broken_image,
                                                                        size:
                                                                            50,
                                                                        color: Colors
                                                                            .grey);
                                                                  },
                                                                )
                                                              : ImageFiltered(
                                                                  imageFilter:
                                                                      ImageFilter.blur(
                                                                          sigmaX:
                                                                              5,
                                                                          sigmaY:
                                                                              5),
                                                                  child: Image
                                                                      .network(
                                                                    place.images
                                                                        .first,
                                                                    width: 140,
                                                                    height: 120,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                    errorBuilder:
                                                                        (context,
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
                                                            FontWeight.bold),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: isUnlocked
                                                        ? () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        Builder(
                                                                  builder: (newContext) =>
                                                                      ChangeNotifierProvider<
                                                                          ReviewProvider>(
                                                                    create: (_) =>
                                                                        ReviewProvider(),
                                                                    child:
                                                                        PlaceDetailsScreen(
                                                                      place:
                                                                          place,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        : () async {
                                                            _showConfirmUnlockDialog(
                                                                place.name,
                                                                place
                                                                    .unlockCost,
                                                                place);
                                                          },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          isUnlocked
                                                              ? Color(
                                                                  0xFF9E9E9E)
                                                              : Color(
                                                                  0xFFD4F98F),
                                                    ),
                                                    child: Text(isUnlocked
                                                        ? "View Details"
                                                        : "Unlock (5 coins)"),
                                                  )
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
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;

  const PlaceCard({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.place,
              color: Colors.blue,
              size: 40,
            ),
            SizedBox(height: 10),
            Text(
              place.name,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              place.description ?? 'No description',
              style: TextStyle(fontSize: 12, color: Colors.black54),
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

  const LockedPlaceCard({required this.place, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.lock,
            color: Colors.red,
            size: 40,
          ),
          SizedBox(height: 10),
          Text(
            place.name,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            place.description ?? 'No description',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          SizedBox(height: 10),
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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          Text(label, style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
