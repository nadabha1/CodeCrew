import 'package:flutter/material.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/Providers/carnet_provider.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:projet_pim/ViewModel/carnet_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class TravelerProfileScreen extends StatefulWidget {
  final String travelerId;
  final String loggedInUserId;

  const TravelerProfileScreen(
      {required this.travelerId, required this.loggedInUserId, Key? key})
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
  late CarnetProvider carnetProvider;

  @override
  void initState() {
    super.initState();
    fetchTravelerProfile();
    fetchFollowerData();
    carnetProvider = CarnetProvider();
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
        await carnetProvider.fetchUnlockedPlaces(_userId!);
      }

      setState(() {
        travelerData = traveler;
        travelerCarnets = carnetService.getUserCarnet(widget.travelerId);
        traveler['followers']?.contains(widget.loggedInUserId) ?? false;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching traveler profile: $e");
      setState(() => isLoading = false);
    }
  }

  void _reloadData() async {
    if (_userId != null) {
      await carnetProvider.fetchUnlockedPlaces(_userId!);
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
                    await carnetProvider.unlockPlace(_userId!, place.id);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
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
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: travelerData?['profilePicture'] !=
                                  null
                              ? NetworkImage(travelerData!['profilePicture'])
                              : const AssetImage('assets/default_profile.png')
                                  as ImageProvider,
                        ),
                        SizedBox(height: 10),
                        Text(
                          travelerData?['name'] ?? 'Unknown Traveler',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(travelerData?['location'] ?? 'Unknown Location'),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing
                                ? const Color(0xF6F6666)
                                : const Color(0xFFD4F98F),
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
                            ),
                            SizedBox(width: 20),
                            _StatItem(
                              count:
                                  travelerData?['followingCount']?.toString() ??
                                      '0',
                              label: 'Following',
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
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Carnet d'Adresses",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
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
                              children: snapshot.data!
                                  .map<Widget>((carnet) => Card(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Column(
                                          children: [
                                            Text(
                                              carnet.title,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18),
                                            ),
                                            SizedBox(height: 10),
                                            // PageView for swiping through places
                                            Container(
                                              height:
                                                  250, // Adjust height as needed
                                              child: PageView(
                                                children: carnet.places
                                                    .map<Widget>((place) {
                                                  bool isUnlocked =
                                                      carnetProvider
                                                          .isPlaceUnlocked(
                                                              place.id);
                                                  // Afficher la carte verrouillée ou déverrouillée en fonction de l'état
                                                  return isUnlocked
                                                      ? PlaceCard(
                                                          place: place,
                                                          onTap: () => openMap(
                                                              place.latitude!,
                                                              place.longitude!),
                                                        )
                                                      : LockedPlaceCard(
                                                          place: place,
                                                          onUnlock: () {
                                                            if (_userId !=
                                                                null) {
                                                              _showConfirmUnlockDialog(
                                                                place.name,
                                                                place
                                                                    .unlockCost,
                                                                place,
                                                              );
                                                            } else {
                                                              _showErrorDialog(
                                                                  "Utilisateur non connecté.");
                                                            }
                                                          },
                                                        );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
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
  const _StatItem({required this.count, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(count,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        Text(label, style: TextStyle(color: Colors.black54)),
      ],
    );
  }
}
