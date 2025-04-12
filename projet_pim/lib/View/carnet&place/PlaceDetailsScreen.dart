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
  bool _isReviewVisible = false;
  bool _isFavorite = false;
  bool _isLoadingReviews = false;

  final ReviewService _reviewService = ReviewService();
  List<Review> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchReviews();
    _checkIfFavorite();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final reviews = await _reviewService.getAllReviews(widget.place.id);
      setState(() => _reviews = reviews);
    } catch (e) {
      print("Erreur lors du chargement des avis: $e");
    } finally {
      setState(() => _isLoadingReviews = false);
    }
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
        SnackBar(content: Text("Connectez-vous pour gérer les favoris.")),
      );
      return;
    }

    try {
      if (_isFavorite) {
        await UserService().removePlaceFromFavorites(userId, widget.place.id, token);
        setState(() => _isFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Retiré des favoris")));
      } else {
        await UserService().addPlaceToFavorites(userId, widget.place.id, token);
        setState(() => _isFavorite = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ajouté aux favoris !")));
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
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Impossible d’ouvrir Google Maps';
    }
  }

  Future<void> _handleAddReview(Review review) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(content: Text('Ajout de l’avis...')),
      );

      await _reviewService.addReview(widget.place.id, review);
      Navigator.of(context).pop();
      await _fetchReviews();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Succès'),
          content: Text('Avis ajouté avec succès !'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Fermer le loading
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erreur'),
          content: Text('Vous avez déjà ajouté un avis.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
        ),
      );
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
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: _addToFavorites,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.place.images.isNotEmpty)
              SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.place.images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(right: 10),
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
                child: Center(child: Icon(Icons.photo, color: Colors.grey[500])),
              ),
            SizedBox(height: 15),
            Text(widget.place.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(widget.place.description, style: TextStyle(fontSize: 16, color: Colors.black54)),
            SizedBox(height: 20),
            Container(
              height: 250,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(widget.place.latitude ?? 0.0, widget.place.longitude ?? 0.0),
                  zoom: 15.0,
                ),
                children: [
                  TileLayer(urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", subdomains: ['a', 'b', 'c']),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(widget.place.latitude ?? 0.0, widget.place.longitude ?? 0.0),
                        width: 40,
                        height: 40,
                        child: Icon(Icons.location_on, color: Colors.red, size: 40),
                      )
                    ],
                  )
                ],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (widget.place.latitude != null && widget.place.longitude != null) {
                  _openInGoogleMaps(widget.place.latitude!, widget.place.longitude!);
                }
              },
              child: Text("Ouvrir dans Google Maps"),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                IconButton(
                  icon: Icon(_isReviewVisible ? Icons.arrow_drop_up : Icons.arrow_drop_down, size: 30),
                  onPressed: () => setState(() => _isReviewVisible = !_isReviewVisible),
                ),
                Text(_isReviewVisible ? "Masquer les commentaires" : "Afficher les commentaires", style: TextStyle(fontSize: 18)),
              ],
            ),
            if (_isReviewVisible)
              _isLoadingReviews
                  ? Center(child: CircularProgressIndicator())
                  : _reviews.isEmpty
                      ? Text("Aucun avis disponible.")
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                title: FutureBuilder<String>(
                                  future: _getUserName(review.userId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return CircularProgressIndicator();
                                    }
                                    return Text(snapshot.data ?? 'Utilisateur inconnu');
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
                                    SizedBox(height: 5),
                                    Text(review.comment),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            AddReviewForm(placeId: widget.place.id, onSubmit: _handleAddReview),
          ],
        ),
      ),
    );
  }
}
