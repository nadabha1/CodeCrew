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
  bool _isReviewVisible = false;
  bool _isFavorite = false; // Ajouté pour suivre l'état des favoris

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<ReviewProvider>(context, listen: false);
        if (provider.reviews.isEmpty) {
          provider.fetchReviews(widget.place.id);
        }
        _checkIfFavorite(); // Vérifier si le lieu est en favori
      }
    });
  }

  Future<String> _getUserName(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("jwt_token");

    if (userId == null || token == null) {
      throw 'No userId or token found';
    }

    final user = await UserService().getUserById(userId, token);
    return user['name'];
  }

// Fonction pour ajouter un lieu aux favoris
  Future<void> _addToFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("jwt_token");
    String? userId = prefs.getString("user_id");

    if (token == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez vous connecter pour gérer vos favoris.')),
      );
      return;
    }

    try {
      if (_isFavorite) {
        await UserService()
            .removePlaceFromFavorites(userId, widget.place.id, token);
        setState(() {
          _isFavorite = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lieu retiré des favoris.')),
        );
      } else {
        await UserService().addPlaceToFavorites(userId, widget.place.id, token);
        setState(() {
          _isFavorite = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lieu ajouté aux favoris !')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
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

  Future<void> _checkIfFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("jwt_token");
    String? userId = prefs.getString("user_id");

    if (token == null || userId == null) {
      return;
    }

    try {
      List<String> favorites =
          await UserService().getUserFavorites(userId, token);
      setState(() {
        _isFavorite = favorites.contains(widget.place.id);
      });
    } catch (e) {
      print('Erreur lors de la récupération des favoris: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place.name),
        backgroundColor: const Color(0xFFDBD9FE),
        actions: [
          /* IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implement share functionality
            },
          ),*/
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed:
                _addToFavorites, // Ajout de la méthode pour ajouter aux favoris
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo album display with horizontal scrolling
              widget.place.images.isNotEmpty
                  ? Container(
                      height: 250,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.place.images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                widget.place.images[index],
                                height: 250,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      height: 250,
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(Icons.photo, color: Colors.grey[500]),
                      ),
                    ),
              const SizedBox(height: 15),
              Text(
                widget.place.name,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.place.description,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              // FlutterMap for displaying location with a custom map style
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
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
              const SizedBox(height: 20),
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
                    _isReviewVisible
                        ? "Masquer les commentaires"
                        : "Afficher les commentaires",
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
                      return const Center(
                          child: Text('Aucun avis disponible.'));
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
                                  return Text('Erreur: ${snapshot.error}');
                                }
                                return Text(
                                    snapshot.data ?? 'Utilisateur inconnu');
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
              AddReviewForm(
                placeId: widget.place.id,
                onSubmit: (Review review) async {
                  try {
                    // Afficher un pop-up de chargement (optionnel)
                    showDialog(
                      context: context,
                      barrierDismissible:
                          false, // Empêche de fermer le dialogue
                      builder: (context) => const AlertDialog(
                        content: Text('Ajout de l’avis en cours...'),
                      ),
                    );

                    // Tentative d'ajout de l'avis (appelle l'API)
                    await Provider.of<ReviewProvider>(context, listen: false)
                        .addReview(widget.place.id, review);

                    // Fermer le pop-up de chargement
                    Navigator.of(context).pop();

                    // Afficher un pop-up de succès uniquement après un succès
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Succès'),
                        content: const Text('Avis ajouté avec succès !'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Fermer le pop-up
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  } catch (e) {
                    // Fermer le pop-up de chargement en cas d'erreur
                    Navigator.of(context).pop();

                    // Vérifier l'exception et afficher un pop-up d'erreur
                    final errorMessage =
                        e.toString().replaceFirst('Exception: ', '');

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Avis déjà ajouté'),
                        content: Text(
                            'Vous avez déjà ajouté un avis pour ce lieu. Vous ne pouvez pas en ajouter un autre.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Fermer le pop-up
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
