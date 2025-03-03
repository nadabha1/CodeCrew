import 'package:flutter/material.dart';
import 'package:projet_pim/Providers/carnet_provider.dart';
import 'package:projet_pim/ViewModel/carnet_service.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String token;

  UserProfilePage({required this.userId, required this.token});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late UserService userService;
  late CarnetService carnetService;
  late CarnetProvider carnetProvider;
  late Future<Map<String, dynamic>> user;
  late Future<List<Carnet>> userCarnet;
  String? _userId;
  String? _token;
  bool _isLoading = true;
  Map<String, dynamic>? travelerData;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
    fetchFollowerData();

    userService = UserService();
    carnetService = CarnetService();
    carnetProvider = CarnetProvider();
    user = userService.getUserById(widget.userId, widget.token);
    userCarnet = carnetService.getUserCarnet(widget.userId);
  }

  Future<void> fetchFollowerData() async {
    try {
      List<String> followers = await userService.getFollowers(widget.userId);
      List<String> following = await userService.getFollowing(widget.userId);
      int followersCount = await userService.getFollowersCount(widget.userId);
      int followingCount = await userService.getFollowingCount(widget.userId);

      setState(() {
        travelerData?['followers'] = followers;
        travelerData?['following'] = following;
        travelerData?['followersCount'] =
            followersCount; // ✅ Correct count update
        travelerData?['followingCount'] =
            followingCount; // ✅ Correct count update
      });
    } catch (e) {
      print("❌ Error fetching followers/following: $e");
    }
  }

  Future<void> toggleFollow() async {
    try {
      if (_userId == null) {
        print("❌ Error: User not logged in");
        return;
      }

      if (isFollowing) {
        await userService.unfollowUser(_userId!, widget.userId);
      } else {
        await userService.followUser(_userId!, widget.userId);
      }

      // ✅ Fetch updated follower count from backend
      await fetchFollowerData();

      setState(() {
        isFollowing = !isFollowing;
      });
    } catch (e) {
      print("❌ Error following/unfollowing user: $e");
    }
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("jwt_token");
    String? userId = prefs.getString("user_id");

    setState(() {
      _userId = userId;
      _token = token;
      _isLoading = false;
    });

    if (_userId == null || _token == null) {
      Navigator.pushReplacementNamed(context, "/login");
    } else {
      carnetProvider.fetchUnlockedPlaces(_userId!);
    }
  }

  void _reloadData() {
    setState(() {
      user = userService.getUserById(widget.userId, widget.token);
      userCarnet = carnetService.getUserCarnet(widget.userId);
    });

    if (_userId != null) {
      carnetProvider.fetchUnlockedPlaces(_userId!);
    }
  }

  void openMap(double latitude, double longitude) async {
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
      appBar: AppBar(title: Text('Profil de l\'Utilisateur')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: user,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (userSnapshot.hasError || !userSnapshot.hasData) {
            return Center(
              child: Text(
                  'Erreur lors du chargement du profil: ${userSnapshot.error}'),
            );
          }

          final userData =
              userSnapshot.data?['user'] ?? userSnapshot.data ?? {};

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: userData['profileImage'] != null &&
                            userData['profileImage'].isNotEmpty
                        ? NetworkImage(userData['profileImage'])
                        : AssetImage('assets/default_profile.png')
                            as ImageProvider,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Nom: ${userData['name'] ?? 'Non spécifié'}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('Métier: ${userData['job'] ?? 'Non spécifié'}'),
                SizedBox(height: 10),
                Text('Lieu: ${userData['location'] ?? 'Non spécifié'}'),
                SizedBox(height: 10),
                Text('Bio: ${userData['bio'] ?? 'Non spécifié'}'),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: toggleFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing ? Colors.grey : Colors.blue,
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
                      count: travelerData?['followersCount']?.toString() ?? '0',
                      label: 'Followers',
                    ),
                    SizedBox(width: 20),
                    _StatItem(
                      count: travelerData?['followingCount']?.toString() ?? '0',
                      label: 'Following',
                    ),
                    SizedBox(width: 20),
                    _StatItem(
                      count: travelerData?['likes']?.toString() ?? '0',
                      label: 'Likes',
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Carnets de ${userData['name'] ?? 'cet utilisateur'}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                FutureBuilder<List<Carnet>>(
                  future: userCarnet,
                  builder: (context, carnetSnapshot) {
                    if (carnetSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (carnetSnapshot.hasError ||
                        !carnetSnapshot.hasData ||
                        carnetSnapshot.data!.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Cet utilisateur n\'a pas de carnet.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }

                    final carnets = carnetSnapshot.data!;
                    return Column(
                      children: carnets.map((carnet) {
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 10),
                          child: ExpansionTile(
                            title: Text(
                              carnet.title,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            children: carnet.places.map((place) {
                              bool isUnlocked =
                                  carnetProvider.isPlaceUnlocked(place.id);

                              return ListTile(
                                title: Text(place.name),
                                trailing: Icon(
                                  isUnlocked ? Icons.lock_open : Icons.lock,
                                  color: isUnlocked ? Colors.green : Colors.red,
                                ),
                                tileColor: isUnlocked
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                onTap: isUnlocked
                                    ? () => openMap(
                                        place.latitude!, place.longitude!)
                                    : null,
                                onLongPress: () {
                                  // Open place in Google Maps on long press
                                  if (place.latitude != null &&
                                      place.longitude != null) {
                                    _openInGoogleMaps(
                                        place.latitude!, place.longitude!);
                                  }
                                },
                                subtitle: isUnlocked
                                    ? null
                                    : ElevatedButton(
                                        onPressed: () async {
                                          if (_userId != null) {
                                            _showConfirmUnlockDialog(
                                              place.name,
                                              place.unlockCost,
                                              place,
                                            );
                                          } else {
                                            _showErrorDialog(
                                                "Utilisateur non connecté.");
                                          }
                                        },
                                        child: Text(
                                            "Déverrouiller (${place.unlockCost} coins)"),
                                      ),
                              );
                            }).toList(),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
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
