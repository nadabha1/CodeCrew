import 'package:flutter/material.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/Providers/review_provider.dart';
import 'package:projet_pim/View/carnet&place/EditPlace.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io' show Platform;

class Details extends StatefulWidget {
  final Place place;

  const Details({required this.place, super.key});

  @override
  _DetailsState createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  late Place place;
  bool _isReviewVisible = false;

  @override
  void initState() {
    super.initState();
    place = widget.place;
  }

  /*void _openInGoogleMaps(double latitude, double longitude) async {
    final Uri url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');

    if (await canLaunch(url.toString())) {
      await launch(url.toString());
    } else {
      throw 'Could not launch $url';
    }
  }*/

  /*void _openInGoogleMaps(double latitude, double longitude) async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication); // important !
    } else {
      throw 'Could not launch $url';
    }
  }*/

  void _openInGoogleMaps(double latitude, double longitude) async {
    final url = Platform.isAndroid
        ? Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude')
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<String> _getUserName(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("jwt_token");

    if (token == null) {
      throw 'No userId or token found';
    }

    final user = await UserService().getUserById(userId, token);
    return user['name'];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(place.name),
        backgroundColor: const Color(0xFFDBD9FE),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom du lieu
              Text(
                place.name,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Afficher l'album photo avec un défilement horizontal
              place.images.isNotEmpty
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: place.images.map((imageUrl) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 5.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                '${ApiConstants.baseUrl}' + imageUrl,
                                width: 150, // Set a fixed width for the images
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  : const Placeholder(
                      fallbackHeight: 200,
                      fallbackWidth: double.infinity,
                    ),
              const SizedBox(height: 16),
              Row(
                children: [
                  buildStarRating(widget.place.averageRating),
                  const SizedBox(width: 6),
                  Text(
                    widget.place.averageRating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
              if (widget.place.categories.isNotEmpty)
                Wrap(
                  spacing: 8.0,
                  children: widget.place.categories.map((category) {
                    return Chip(
                      label: Text(category),
                      backgroundColor: Colors.deepPurple[100],
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),

              // Description du lieu
              Text(
                place.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),

              // FlutterMap pour afficher la localisation
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: FlutterMap(
                  options: MapOptions(
                    center:
                        LatLng(place.latitude ?? 0.0, place.longitude ?? 0.0),
                    zoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                              place.latitude ?? 0.0, place.longitude ?? 0.0),
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
              const SizedBox(height: 20),

              // Bouton pour ouvrir la localisation dans Google Maps
              ElevatedButton(
                onPressed: () {
                  if (place.latitude != null && place.longitude != null) {
                    _openInGoogleMaps(place.latitude!, place.longitude!);
                  }
                },
                child: const Text("Open in Google Maps"),
              ),
              const SizedBox(height: 20),
              // Toggle reviews section with a smoother transition
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isReviewVisible
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        _isReviewVisible = !_isReviewVisible;
                      });
                    },
                  ),
                  Text(
                    _isReviewVisible ? "Hide comments" : "Show comments",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_isReviewVisible)
                Consumer<ReviewProvider>(
                  builder: (context, reviewProvider, child) {
                    if (reviewProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (reviewProvider.reviews.isEmpty) {
                      return const Center(child: Text('No reviews available.'));
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reviewProvider.reviews.length,
                      itemBuilder: (context, index) {
                        final review = reviewProvider.reviews[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                          child: ListTile(
                            title: FutureBuilder<String>(
                              future: _getUserName(review.userId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                }
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                }
                                return Text(snapshot.data ?? 'Unknown user');
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
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),

      // Ajout du bouton d'édition
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Ouvrir la page d'édition et attendre la réponse
          final updatedPlace = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditPlace(place: place),
            ),
          );

          // Si la place a été mise à jour, actualiser l'état
          if (updatedPlace != null) {
            setState(() {
              place = updatedPlace;
            });
          }
        },
        backgroundColor: const Color(0xFFD4F98F),
        child: const Icon(Icons.edit),
      ),
    );
  }
}
