import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ar_location_view/ar_location_view.dart';
import 'package:projet_pim/CustomAnnotation.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/Model/user_entity.dart';
import 'package:projet_pim/View/carnet&place/PlaceDetailsScreen.dart';
import 'package:projet_pim/View/profile.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:projet_pim/ViewModel/carnet_service.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ARViewScreen extends StatefulWidget {
  @override
  _ARViewScreenState createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen> {
  List<CustomAnnotation> annotations = [];
  final CarnetService carnetService = CarnetService();
  final UserService userService = UserService();
  CarnetService? carnetProvider; // Define carnetProvider
  String? userId, token;
  bool isLoading = true;
  Position? _userPosition;
  List<User> users = [];
  List<Place> places = [];
  User? matchedUser;
  Place? matchedPlace;
  Timer? _locationTimer;
  Map<String, int> userFollowers =
      {}; // Map to store followers count for each user
  int loggedInUserCoins = 0; // Store the logged-in user's coins

  @override
  void initState() {
    super.initState();
    carnetProvider = CarnetService(); // Initialize carnetProvider
    _initializeData();
    _locationTimer = Timer.periodic(Duration(seconds: 1), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        if (mounted) {
          setState(() {
            _userPosition = pos;
          });
        }
      } catch (e) {
        print("❌ Erreur lors du rafraîchissement de la position : $e");
      }
    });
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("user_id");
    token = prefs.getString("jwt_token");

    // Fetch user coins
    if (userId != null && token != null) {
      try {
        final user = await userService.getUserById(userId!, token!);
        setState(() {
          loggedInUserCoins =
              user['coins'] ?? 0; // Default to 0 if coins is null
        });
        print("Logged-in user's coins: $loggedInUserCoins");
      } catch (e) {
        print("Error fetching user coins: $e");
      }
    }

    // Permissions
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      print("❌ Permission de localisation refusée.");
    } else {
      try {
        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() => _userPosition = pos);
      } catch (e) {
        print("❌ Impossible de récupérer la position: $e");
      }
    }

    await _loadPlaces();
    await _loadUsers();
    setState(() => isLoading = false);
  }

  Future<void> _loadPlaces() async {
    try {
      final data = await carnetService.getAllPlacesFromCarnets();
      final places = data.map((p) => Place.fromJson(p)).toList();
      setState(() {
        this.places = places;
        annotations.addAll(places.map((pl) => pl.toAnnotation()));
      });
      print("Loaded Places: ${places.map((p) => p.id).toList()}");
    } catch (e) {
      print("❌ Erreur chargement lieux: $e");
    }
  }

  Future<void> _loadUsers() async {
    if (token == null) return;
    try {
      final data = await userService.getAllUsers(token!);
      final users = data.map((u) => User.fromJson(u)).toList();

      // Fetch followers for each user and store in the map
      for (var user in users) {
        final followers = await userService.getFollowers(user.id);
        userFollowers[user.id] = followers.length; // Store followers count
      }

      setState(() {
        this.users = users;
        annotations.addAll(users.map((u) => u.toAnnotation()));
      });

      print("Loaded Users: ${users.map((u) => u.id).toList()}");
    } catch (e) {
      print("❌ Erreur chargement utilisateurs: $e");
    }
  }

  void _showDetails(CustomAnnotation annotation) async {
    print("Annotation UID: ${annotation.uid}");

    matchedUser = users.where((user) => user.id == annotation.uid).isNotEmpty
        ? users.firstWhere((user) => user.id == annotation.uid)
        : null;

    matchedPlace =
        places.where((place) => place.id == annotation.uid).isNotEmpty
            ? places.firstWhere((place) => place.id == annotation.uid)
            : null;

    print("Matched User: $matchedUser");
    print("Matched Place: $matchedPlace");

    if (matchedUser == null && matchedPlace == null) {
      print(
          "❌ No matching user or place found for annotation UID: ${annotation.uid}");
      return; // Exit if no match is found
    }

    // Fetch unlocked places
    final unlockedPlaces = await carnetProvider?.fetchUnlockedPlaces(userId!);
    bool isUnlocked = unlockedPlaces?.contains(matchedPlace?.id) ?? false;
    int followersCount = 0;
    bool isLoadingFollowers = true;

    // Fetch followers count
    if (matchedUser != null) {
      try {
        final followers = await userService.getFollowers(matchedUser!.id);
        followersCount = followers.length;
      } catch (e) {
        print("Error fetching followers: $e");
      } finally {
        isLoadingFollowers = false;
      }
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 50,
                            height: 6,
                            margin: EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        // USER CARD
                        if (matchedUser != null) ...[
                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  if (matchedUser!.profileImage != null)
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundImage: NetworkImage(
                                          '${ApiConstants.baseUrl}'+matchedUser!.profileImage!),
                                      onBackgroundImageError: (_, __) =>
                                          const Icon(Icons.person, size: 50),
                                    ),
                                  SizedBox(height: 10),
                                  Text(
                                    matchedUser!.name,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    "$followersCount followers",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w100,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Bio:",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      matchedUser!.bio.isNotEmpty
                                          ? matchedUser!.bio
                                          : "No bio available",
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Job:",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      matchedUser!.job,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Followers:",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: isLoadingFollowers
                                        ? CircularProgressIndicator()
                                        : Text(
                                            "$followersCount followers",
                                            style: TextStyle(fontSize: 14),
                                          ),
                                  ),
                                  SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.person),
                                    label: Text("Voir le profil"),
                                    style: ElevatedButton.styleFrom(
                                        minimumSize: Size(double.infinity, 45),
                                        backgroundColor:
                                            const Color(0xFFDBD9FE)),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TravelerProfileScreen(
                                            travelerId: matchedUser!.id,
                                            loggedInUserId: userId!,
                                            token: token!,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // PLACE CARD
                        if (matchedPlace != null) ...[
                          SizedBox(height: 16),
                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (matchedPlace!.images.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        '${ApiConstants.baseUrl}'+matchedPlace!.images[0],
                                        width: double.infinity,
                                        height: 180,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.broken_image,
                                          size: 100,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  SizedBox(height: 12),
                                  Text(
                                    matchedPlace!.name,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Divider(height: 20, thickness: 1),
                                  Text(
                                    "Description:",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    matchedPlace!.description,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Catégories: ${matchedPlace!.categories.join(", ")}",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Note Moyenne: ${matchedPlace!.averageRating.toStringAsFixed(1)}",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Coût de Déblocage: ${matchedPlace!.unlockCost} coins",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    icon: Icon(
                                        isUnlocked ? Icons.place : Icons.lock),
                                    label: Text(isUnlocked
                                        ? "Voir les détails"
                                        : "Débloquer ce lieu"),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: Size(double.infinity, 45),
                                      backgroundColor: isUnlocked
                                          ? const Color(0xFFDBD9FE)
                                          : const Color(0xFFD4F98F),
                                    ),
                                    onPressed: () async {
                                      if (isUnlocked) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PlaceDetailsScreen(
                                              place: matchedPlace!,
                                            ),
                                          ),
                                        );
                                      } else {
                                        // Debugging: Print logged-in user's coins
                                        print(
                                            "Logged-in User Coins: $loggedInUserCoins");
                                        print(
                                            "Unlock Cost: ${matchedPlace!.unlockCost}");

                                        // Check if the logged-in user has enough coins
                                        if (loggedInUserCoins >=
                                            matchedPlace!.unlockCost) {
                                          // Show confirmation dialog for payment
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text("Confirmer"),
                                                content: Text(
                                                    "Voulez-vous vraiment débloquer ce lieu pour ${matchedPlace!.unlockCost} coins ?"),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop(false); // Cancel
                                                    },
                                                    child: Text("Annuler"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop(true); // Confirm
                                                    },
                                                    child: Text("Confirmer"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          if (confirm == true) {
                                            try {
                                              await carnetProvider?.unlockPlace(
                                                  userId!, matchedPlace!.id);
                                              setState(() {
                                                isUnlocked =
                                                    true; // Update the state
                                                loggedInUserCoins -= matchedPlace!
                                                    .unlockCost; // Deduct coins
                                              });
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      "Place unlocked successfully!"),
                                                ),
                                              );
                                            } catch (e) {
                                              final errorMessage = e
                                                      .toString()
                                                      .contains(
                                                          "Not enough coins")
                                                  ? "Vous n'avez pas assez de coins pour débloquer ce lieu."
                                                  : "Échec du déblocage du lieu.";

                                              // Show error dialog
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    title: Text("Erreur"),
                                                    content: Text(errorMessage),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child: Text("OK"),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            }
                                          }
                                        } else {
                                          // Show dialog for insufficient coins
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text(
                                                    "Oops! You're Short on Coins"),
                                                content: Text(
                                                    "You don't have enough coins to unlock this place."),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: Text("OK"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vue AR')),
      backgroundColor: Colors.transparent,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Builder(builder: (scaffoldContext) {
              return Stack(
                children: [
                  // AR Location Widget
                  Positioned.fill(
                    child: ArLocationWidget(
                      annotations: annotations,
                      onLocationChange: (pos) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() => _userPosition = pos);
                        });
                      },
                      showDebugInfoSensor: false, // Disable debug information
                      annotationWidth: 200,
                      annotationHeight: 150,
                      annotationViewBuilder: (ctx, annotation) {
                        if (annotation is! CustomAnnotation)
                          return SizedBox.shrink();

                        const w = 250.0, h = 120.0;
                        String? dist;
                        if (_userPosition != null) {
                          final d = Geolocator.distanceBetween(
                            _userPosition!.latitude,
                            _userPosition!.longitude,
                            annotation.position.latitude,
                            annotation.position.longitude,
                          );
                          dist = d < 1000
                              ? "${d.toStringAsFixed(0)} m"
                              : "${(d / 1000).toStringAsFixed(1)} km";
                        }

                        // Determine the icon and its color based on whether it's a user or a place
                        final isUser =
                            users.any((user) => user.id == annotation.uid);
                        final icon = isUser ? Icons.person : Icons.location_on;
                        final iconColor = isUser
                            ? const Color.fromARGB(255, 0, 0, 0)
                            : const Color.fromARGB(255, 0, 0, 0);

                        return Transform.translate(
                          offset: Offset(0, -h / 2),
                          child: GestureDetector(
                            onTap: () => _showDetails(annotation),
                            child: Container(
                              width: w,
                              constraints: BoxConstraints(maxHeight: h),
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(2, 2))
                                ],
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      if (annotation.imageUrl != null)
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            '${ApiConstants.baseUrl}'+annotation.imageUrl!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Icon(
                                                Icons.broken_image,
                                                size: 60,
                                                color: Colors.grey),
                                          ),
                                        )
                                      else
                                        Icon(Icons.broken_image,
                                            size: 80, color: Colors.grey),
                                      Positioned(
                                        bottom: 4,
                                        right: 4,
                                        child: Icon(
                                          icon,
                                          size: 24,
                                          color: iconColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          annotation.title,
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (annotation.subtitle != null)
                                          Padding(
                                              padding: EdgeInsets.only(top: 4)),
                                        if (dist != null)
                                          Text(dist,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
    );
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }
}
