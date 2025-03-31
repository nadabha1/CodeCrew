import 'package:flutter/material.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/Model/review.dart';
import 'package:projet_pim/View/carnet&place/add_review_form.dart';
import 'package:projet_pim/ViewModel/review_service.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Place place;

  const PlaceDetailsScreen({required this.place, Key? key}) : super(key: key);

  @override
  _PlaceDetailsScreenState createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  final ReviewService _reviewService = ReviewService();
  final UserService _userService = UserService();
  List<Review> _reviews = [];
  bool _isLoading = true;
  bool _isReviewVisible = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _checkIfFavorite();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await _reviewService.getAllReviews(widget.place.id);
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading reviews: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<String> _getUserName(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("jwt_token");
    if (userId.isEmpty || token == null) return 'Inconnu';
    final user = await _userService.getUserById(userId, token);
    return user['name'];
  }

  Future<void> _checkIfFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("jwt_token");
    String? userId = prefs.getString("user_id");
    if (token == null || userId == null) return;
    try {
      List<String> favorites = await _userService.getUserFavorites(userId, token);
      setState(() {
        _isFavorite = favorites.contains(widget.place.id);
      });
    } catch (e) {
      print("Erreur favoris: $e");
    }
  }

  Future<void> _addToFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("jwt_token");
    String? userId = prefs.getString("user_id");

    if (token == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter.')),
      );
      return;
    }

    try {
      if (_isFavorite) {
        await _userService.removePlaceFromFavorites(userId, widget.place.id, token);
      } else {
        await _userService.addPlaceToFavorites(userId, widget.place.id, token);
      }
      setState(() => _isFavorite = !_isFavorite);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }


void _openInGoogleMaps(double latitude, double longitude) async {
  final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');

  if (await canLaunchUrl(url)) {
    await launchUrl(
      url,
      mode: LaunchMode.externalApplication, // 👈 important !
    );
  } else {
    throw 'Could not launch $url';
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place.name),
        backgroundColor: const Color(0xFFDBD9FE),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : null),
            onPressed: _addToFavorites,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.place.images.isNotEmpty
                ? SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.place.images.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(widget.place.images[index], fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  )
                : Container(
                    height: 250,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.photo, color: Colors.grey)),
                  ),
            const SizedBox(height: 15),
            Text(widget.place.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.place.description, style: const TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 20),
            Container(
              height: 250,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
              ]),
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(widget.place.latitude ?? 0.0, widget.place.longitude ?? 0.0),
                  zoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: LatLng(widget.place.latitude ?? 0.0, widget.place.longitude ?? 0.0),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    )
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (widget.place.latitude != null && widget.place.longitude != null) {
                  _openInGoogleMaps(widget.place.latitude!, widget.place.longitude!);
                }
              },
              child: const Text("Ouvrir dans Google Maps"),
            ),
            const SizedBox(height: 20),

            // Toggle avis
            Row(
              children: [
                IconButton(
                  icon: Icon(_isReviewVisible ? Icons.arrow_drop_up : Icons.arrow_drop_down, size: 30),
                  onPressed: () => setState(() => _isReviewVisible = !_isReviewVisible),
                ),
                Text(
                  _isReviewVisible ? "Masquer les commentaires" : "Afficher les commentaires",
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),

            const SizedBox(height: 10),
            if (_isReviewVisible)
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _reviews.isEmpty
                      ? const Text("Aucun avis disponible.")
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 5,
                              child: ListTile(
                                title: FutureBuilder<String>(
                                  future: _getUserName(review.userId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    }
                                    return Text(snapshot.data ?? "Utilisateur");
                                  },
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: List.generate(
                                        5,
                                        (i) => Icon(
                                          i < review.rating ? Icons.star : Icons.star_border,
                                          color: Colors.amber,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(review.comment),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

            // Formulaire d’ajout
            AddReviewForm(
              placeId: widget.place.id,
              onSubmit: (Review review) async {
                await _reviewService.addReview(widget.place.id, review);
                _loadReviews(); // Recharge les avis après ajout
              },
            ),
          ],
        ),
      ),
    );
  }
}
