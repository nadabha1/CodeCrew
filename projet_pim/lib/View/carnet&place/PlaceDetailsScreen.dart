import 'package:flutter/material.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/Model/review.dart';
import 'package:projet_pim/Providers/review_provider.dart';
import 'package:projet_pim/View/carnet&place/add_review_form.dart';
import 'package:projet_pim/ViewModel/review_service.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class PlaceDetailsScreen extends StatefulWidget {
  final Place place;

  const PlaceDetailsScreen({required this.place, super.key});

  @override
  _PlaceDetailsScreenState createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  bool _isReviewVisible = false;
  bool _isFavorite = false;
  bool _isLoadingReviews = false;

  final ReviewService _reviewService = ReviewService();
  List<Review> _reviews = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    await _getCurrentUserId(); // On récupère d'abord l'ID
    await _fetchReviews(); // Puis on peut charger les avis
    await _checkIfFavorite(); // Ensuite les favoris
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final reviews = await _reviewService.getAllReviews(widget.place.id);
      setState(() => _reviews = reviews);
    } catch (e) {
      print("Erreur lors du chargement des avis: $e");
    } finally {
      setState(() => _isLoadingReviews = false); // 🔴 manquait ici
    }
  }

  Future<void> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString("user_id");
    });
  }

  Future<String> _getUserName(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("jwt_token");
    if (token == null) throw 'Token manquant';
    final user = await UserService().getUserById(userId, token);
    return user['name'];
  }

  Future<void> _addToFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("jwt_token");
    String? userId = prefs.getString("user_id");

    if (token == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connectez-vous pour gérer les favoris.")),
      );
      return;
    }

    try {
      if (_isFavorite) {
        await UserService()
            .removePlaceFromFavorites(userId, widget.place.id, token);
        setState(() => _isFavorite = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Retiré des favoris")));
      } else {
        await UserService().addPlaceToFavorites(userId, widget.place.id, token);
        setState(() => _isFavorite = true);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ajouté aux favoris !")));
      }
    } catch (e) {
      print("Erreur favoris: $e");
    }
  }

  Future<void> _checkIfFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("jwt_token");
    String? userId = prefs.getString("user_id");
    if (token == null || userId == null) return;

    try {
      final favorites = await UserService().getUserFavorites(userId, token);
      setState(() => _isFavorite = favorites.contains(widget.place.id));
    } catch (e) {
      print("Erreur favoris: $e");
    }
  }

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

  Future<void> _handleAddReview(Review review) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const AlertDialog(content: Text('Ajout de l’avis...')),
      );

      await _reviewService.addReview(widget.place.id, review);
      Navigator.of(context).pop();
      await _fetchReviews();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Succès'),
          content: const Text('Avis ajouté avec succès !'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'))
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Fermer le loading
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erreur'),
          content: const Text('Vous avez déjà ajouté un avis.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'))
          ],
        ),
      );
    }
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

  void _showEditReviewDialog(Review review) {
    final TextEditingController commentController =
        TextEditingController(text: review.comment);
    int updatedRating = review.rating;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Modifier votre avis"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => IconButton(
                    icon: Icon(
                      i < updatedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        updatedRating = i + 1;
                      });
                      // force rebuild
                      Navigator.pop(context);
                      _showEditReviewDialog(
                          review.copyWith(rating: updatedRating));
                    },
                  ),
                ),
              ),
              TextField(
                controller: commentController,
                decoration:
                    const InputDecoration(labelText: "Votre commentaire"),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Annuler"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Enregistrer"),
              onPressed: () async {
                final updatedReview = review.copyWith(
                  rating: updatedRating,
                  comment: commentController.text,
                );

                try {
                  await Provider.of<ReviewProvider>(context, listen: false)
                      .editReview(widget.place.id, updatedReview);
                  Navigator.pop(context);
                } catch (e) {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Erreur"),
                      content: Text("Impossible de modifier l'avis."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("OK"),
                        )
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place.name),
        backgroundColor: const Color(0xFFDBD9FE),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: _addToFavorites,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.place.name,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

            if (widget.place.images.isNotEmpty)
              SizedBox(
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
            else
              Container(
                height: 250,
                color: Colors.grey[200],
                child:
                    Center(child: Icon(Icons.photo, color: Colors.grey[500])),
              ),
            SizedBox(height: 20),

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
            if (widget.place.categories != null &&
                widget.place.categories.isNotEmpty)
              Wrap(
                spacing: 8.0,
                children: widget.place.categories.map((category) {
                  return Chip(
                    label: Text(category),
                    backgroundColor: Colors.deepPurple[100],
                  );
                }).toList(),
              ),

            SizedBox(height: 8),
            Text(
              widget.place.description,
              style: const TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            const SizedBox(height: 15),
            Text(widget.place.name,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.place.description,
                style: const TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 20),
            Container(
              height: 250,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(12)),
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
                      subdomains: const ['a', 'b', 'c']),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(widget.place.latitude ?? 0.0,
                            widget.place.longitude ?? 0.0),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on,
                            color: Colors.red, size: 40),
                      )
                    ],
                  )
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
                    return const Center(child: Text('Aucun avis disponible.'));
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
                              if (_currentUserId == review.userId)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      _showEditReviewDialog(review);
                                    },
                                    child: const Text("Modifier"),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            const SizedBox(height: 20),
            AddReviewForm(
              placeId: widget.place.id,
              onSubmit: (Review review) async {
                try {
                  // Afficher un pop-up de chargement (optionnel)
                  showDialog(
                    context: context,
                    barrierDismissible: false, // Empêche de fermer le dialogue
                    builder: (context) => const AlertDialog(
                      content: Text('Ajout de l’avis en cours...'),
                    ),
                  );

                  // Tentative d'ajout de l'avis (appelle l'API)
                  await Provider.of<ReviewProvider>(context, listen: false)
                      .addReview(widget.place.id,
                          review); // Ensure this line works without returning a value

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
                      content: const Text(
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
            )
          ],
        ),
      ),
    );
  }
}
