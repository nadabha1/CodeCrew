import 'package:flutter/material.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/Model/review.dart';
import 'package:projet_pim/View/carnet&place/add_review_form.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:projet_pim/providers/review_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Place place;

  const PlaceDetailsScreen({required this.place, Key? key}) : super(key: key);

  @override
  _PlaceDetailsScreenState createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  bool _isReviewVisible =
      false; // Variable to control the visibility of reviews

  @override
  void initState() {
    super.initState();
    // Fetch reviews after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);
      reviewProvider
          .fetchReviews(widget.place.id); // Fetch reviews for the place
    });
  }

  Future<String> _getUserName(String userId) async {
    // Retrieve both userId and token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("jwt_token");

    if (userId == null || token == null) {
      throw 'No userId or token found';
    }

    final user = await UserService().getUserById(userId, token);
    return user['name']; // Assuming user['name'] is where the name is located
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.place.name)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.place.images.isNotEmpty
                  ? Image.network(widget.place.images.first,
                      height: 200, fit: BoxFit.cover)
                  : const SizedBox(height: 200),
              const SizedBox(height: 10),
              Text(
                widget.place.name,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(widget.place.description,
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Container(
                height: 300,
                child: FlutterMap(
                  options: MapOptions(
                    center: LatLng(widget.place.latitude ?? 0.0,
                        widget.place.longitude ?? 0.0),
                    zoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(widget.place.latitude ?? 0.0,
                              widget.place.longitude ?? 0.0),
                          width: 40.0,
                          height: 40.0,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (widget.place.latitude != null &&
                      widget.place.longitude != null) {
                    _openInGoogleMaps(
                        widget.place.latitude!, widget.place.longitude!);
                  }
                },
                child: const Text("Ouvrir dans Google Maps"),
              ),
              const SizedBox(height: 20),
              // Texte pour afficher/masquer les commentaires avec flèche
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isReviewVisible
                          ? Icons.arrow_drop_up // Flèche vers le haut
                          : Icons.arrow_drop_down, // Flèche vers le bas
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        _isReviewVisible = !_isReviewVisible;
                      });
                    },
                  ),
                  Text(
                    _isReviewVisible
                        ? "Masquer les commentaires"
                        : "Afficher les commentaires",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Affichage des avis si _isReviewVisible est vrai
              if (_isReviewVisible)
                Consumer<ReviewProvider>(
                  builder: (context, reviewProvider, child) {
                    if (reviewProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (reviewProvider.reviews.isEmpty) {
                      return const Center(
                          child: Text('Aucun avis disponible.'));
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reviewProvider.reviews.length,
                      itemBuilder: (context, index) {
                        final review = reviewProvider.reviews[index];

                        return ListTile(
                          title: FutureBuilder<String>(
                            future: _getUserName(review
                                .userId), // Fetch user name based on userId
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }
                              if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              }
                              if (snapshot.hasData) {
                                return Text(
                                    snapshot.data!); // Display the user's name
                              }
                              return const Text('User not found');
                            },
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < review.rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(review.comment),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              AddReviewForm(
                placeId: widget.place.id, // Pass placeId here
                onSubmit: (Review review) {
                  // Add the review to the provider
                  Provider.of<ReviewProvider>(context, listen: false).addReview(
                      widget.place.id, review); // Pass placeId and the review
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
