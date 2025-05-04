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
  String? userId, token;
  bool isLoading = true;
  Position? _userPosition;
  List<User> users = [];
  List<Place> places = [];
  User? matchedUser;
  Place? matchedPlace;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
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
      setState(() => annotations.addAll(places.map((pl) => pl.toAnnotation())));
    } catch (e) {
      print("❌ Erreur chargement lieux: $e");
    }
  }

  Future<void> _loadUsers() async {
    if (token == null) return;
    try {
      final data = await userService.getAllUsers(token!);
      final users = data.map((u) => User.fromJson(u)).toList();
      setState(() => annotations.addAll(users.map((u) => u.toAnnotation())));
    } catch (e) {
      print("❌ Erreur chargement utilisateurs: $e");
    }
  }

  void _showDetails(CustomAnnotation annotation) {
    matchedUser = users.where((user) => user.id == annotation.uid).isNotEmpty
        ? users.firstWhere((user) => user.id == annotation.uid)
        : null;

    matchedPlace =
        places.where((place) => place.id == annotation.uid).isNotEmpty
            ? places.firstWhere((place) => place.id == annotation.uid)
            : null;
    print("Matched User: $matchedUser");
    print("Matched Place: $matchedPlace");
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5, // Valeur entre 0.0 et 1.0
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Text(annotation.title,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    if (annotation.subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(annotation.subtitle!),
                      ),
                    SizedBox(height: 20),
                    if (matchedUser != null)
                      ElevatedButton.icon(
                        icon: Icon(Icons.person),
                        label: Text("Voir le profil de l'utilisateur"),
                        onPressed: () {
                          Navigator.pop(context); // Fermer le bottom sheet
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
                    if (matchedPlace != null)
                      ElevatedButton.icon(
                        icon: Icon(Icons.place),
                        label: Text("Détails du lieu"),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaceDetailsScreen(
                                place: matchedPlace!,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
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
      // On utilise un Builder pour capturer un contexte "app-level"
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Builder(builder: (scaffoldContext) {
              return ArLocationWidget(
                annotations: annotations,
                onLocationChange: (pos) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() => _userPosition = pos);
                  });
                },
                annotationViewBuilder: (ctx, annotation) {
                  if (annotation is! CustomAnnotation) return SizedBox.shrink();

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
                            if (annotation.imageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  '${ApiConstants.baseUrl}'+annotation.imageUrl!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                      Icons.broken_image,
                                      size: 60,
                                      color: Colors.grey),
                                ),
                              )
                            else
                              Icon(Icons.location_on,
                                  size: 60, color: Colors.blueAccent),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    Padding(padding: EdgeInsets.only(top: 4)),
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
