import 'package:flutter/material.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/Providers/review_provider.dart';
import 'package:projet_pim/View/carnet&place/PlaceDetailsScreen.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Place> favorites = [];
  String? userId;
  String? token;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? _userId = prefs.getString("user_id");
    String? _token = prefs.getString("jwt_token");

    if (_userId != null && _token != null) {
      setState(() {
        userId = _userId;
        token = _token;
      });
      fetchFavorites(_userId, _token);
    } else {
      print("User ID or Token is not available");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchFavorites(String userId, String token) async {
    try {
      UserService userService = UserService();
      final response = await userService.getUserFavorites(userId, token);

      if (response is List) {
        List<String> placeIds = response.map((e) => e.toString()).toList();
        List<Place> placesDetails = [];

        for (String placeId in placeIds) {
          try {
            var placeDetails = await userService.getPlaceById(placeId, token);
            Place place = Place.fromJson(placeDetails);
            placesDetails.add(place);
          } catch (e) {
            print("❌ Error retrieving place details for $placeId: $e");
          }
        }

        setState(() {
          favorites = placesDetails;
          isLoading = false;
        });
      } else {
        print("Response is not a list.");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching favorites: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorites"),
        backgroundColor: const Color(0xFFD1C4E9),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFD1C4E9),
              Color(0xFFEDE7F6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : favorites.isEmpty
                ? Center(
                    child: Text(
                      "You don't have any favorites yet",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: favorites.length,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    itemBuilder: (context, index) {
                      Place place = favorites[index];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          title: Text(
                            place.name,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(place.description,
                                  style: TextStyle(color: Colors.grey[600])),
                              SizedBox(height: 8),
                              place.images.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        '${ApiConstants.baseUrl}'+place.images[0],
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(
                                      height: 150,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                          child: Icon(Icons.image,
                                              color: Colors.grey, size: 50)),
                                    ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MultiProvider(
                                  providers: [
                                    ChangeNotifierProvider(
                                      create: (_) => ReviewProvider(),
                                    ),
                                  ],
                                  child: PlaceDetailsScreen(place: place),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
