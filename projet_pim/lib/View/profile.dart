// ✅ TravelerProfileScreen améliorée avec onglets et présentation stylée

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/Model/user_entity.dart';
import 'package:projet_pim/Providers/carnet_provider.dart';
import 'package:projet_pim/Providers/review_provider.dart';
import 'package:projet_pim/View/carnet&place/PlaceDetailsProviderScreen.dart';
import 'package:projet_pim/View/carnet&place/PlaceDetailsScreen.dart';
import 'package:projet_pim/View/follow/FollowersFollowingListScreen.dart';
import 'package:projet_pim/ViewModel/activityLoggerService.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:projet_pim/ViewModel/carnet_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TravelerProfileScreen extends StatefulWidget {
  final String travelerId;
  final String loggedInUserId;

  const TravelerProfileScreen({required this.travelerId, required this.loggedInUserId, Key? key}) : super(key: key);

  @override
  _TravelerProfileScreenState createState() => _TravelerProfileScreenState();
}

class _TravelerProfileScreenState extends State<TravelerProfileScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? travelerData;
  CarnetService carnetService = CarnetService();
  late Future<List<Carnet>> travelerCarnets = Future.value([]);
  bool isLoading = true;
  bool isFollowing = false;
  String? _userId;
  String? _token;
  late TabController _tabController;

  UserService userService = UserService();
  CarnetProvider? carnetProvider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    carnetProvider = Provider.of<CarnetProvider>(context, listen: false);
    fetchTravelerProfile();
    fetchFollowerData();
  }
void onPlaceClick(String name) {
  ActivityLoggerService.logAction(
    userId: widget.loggedInUserId,
    type: "click",
    value: name,
  );
}

  Future<void> fetchFollowerData() async {
    try {
      List<User> followers = await userService.getFollowers(widget.travelerId);
      List<User> following = await userService.getFollowing(widget.travelerId);
      int followersCount = await userService.getFollowersCount(widget.travelerId);
      int followingCount = await userService.getFollowingCount(widget.travelerId);

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

      Map<String, dynamic> traveler = await userService.getUserById(widget.travelerId, _token!);
      travelerCarnets = carnetService.getUserCarnet(widget.travelerId);

      if (_userId != null) {
        await carnetProvider?.fetchUnlockedPlaces(_userId!);
      }

      List<User> followers = await userService.getFollowers(widget.travelerId);
      bool isUserFollowing = followers.contains(widget.loggedInUserId);

      setState(() {
        travelerData = traveler;
        isFollowing = isUserFollowing;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching traveler profile: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _reloadUnlockedPlaces() async {
    if (_userId != null) {
      await carnetProvider?.fetchUnlockedPlaces(_userId!);
      setState(() {});
    }
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
                Navigator.of(context).pop();
                try {
                  if (_userId != null) {
                    await carnetProvider?.unlockPlace(_userId!, place.id);
                    _showUnlockDialog(placeName);
                    await _reloadUnlockedPlaces();
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReviewProvider>(
      create: (_) => ReviewProvider(),
      builder: (context, _) {
        final carnetProvider = Provider.of<CarnetProvider>(context);

        return Scaffold(
          backgroundColor: Colors.white,
          body: isLoading
  ? Center(child: CircularProgressIndicator())
  : Column(
      children: [
        // ... Header (Avatar, name, follow button, etc)
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
                backgroundImage: travelerData?['profilePicture'] != null
                    ? NetworkImage(travelerData!['profilePicture'])
                    : AssetImage('assets/default_profile.png') as ImageProvider,
              ),
              SizedBox(height: 10),
              Text(travelerData?['name'] ?? 'Unknown Traveler',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(travelerData?['location'] ?? 'Unknown Location'),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  if (isFollowing) {
                    await userService.unfollowUser(widget.loggedInUserId, widget.travelerId);
                  } else {
                    await userService.followUser(widget.loggedInUserId, widget.travelerId);
                  }
                  fetchFollowerData();
                  setState(() {
                    isFollowing = !isFollowing;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing ? Colors.grey : Color(0xFFD4F98F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      onTap: () {
        final List<User> followers = List<User>.from(travelerData?['followers'] ?? []);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FollowersFollowingListScreen(
              users: followers,
              title: 'Followers',
            ),
          ),
        );
      },
    ),
    SizedBox(width: 20),
    _StatItem(
      count: travelerData?['followingCount']?.toString() ?? '0',
      label: 'Following',
      onTap: () {
        final List<User> following = List<User>.from(travelerData?['following'] ?? []);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FollowersFollowingListScreen(
              users: following,
              title: 'Following',
            ),
          ),
        );
      },
    ),
    SizedBox(width: 20),
    _StatItem(count: travelerData?['likes']?.toString() ?? '0', label: 'Likes'),
  ],
),

            ],
          ),
        ),

        TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          indicatorColor: Colors.deepPurple,
          tabs: [
            Tab(text: "Adresses"),
            Tab(text: "Avis"),
            Tab(text: "Infos"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 🔓 Carnet Adresses avec déverrouillage auto
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder<List<Carnet>>(
                  future: travelerCarnets,
                  builder: (context, snapshot) {
                    final carnetProvider = Provider.of<CarnetProvider>(context);
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text("Aucune adresse disponible"));
                    }
                    return ListView(
                      children: snapshot.data!.map((carnet) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(carnet.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: carnet.places.map((place) {
                                  bool isUnlocked = carnetProvider.isPlaceUnlocked(place.id);
                                  return Card(
                                    margin: EdgeInsets.symmetric(horizontal: 10),
                                    child: Container(
                                      width: 190,
                                      padding: EdgeInsets.all(10),
                                      child: Column(
                                        children: [
                                          Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: isUnlocked
                                                    ? Image.network(
                                                        place.images.first,
                                                        width: 140,
                                                        height: 120,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : ImageFiltered(
                                                        imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                                        child: Image.network(
                                                          place.images.first,
                                                          width: 140,
                                                          height: 120,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                              ),
                                              if (!isUnlocked)
                                                Positioned(
                                                  top: 40,
                                                  left: 55,
                                                  child: Icon(Icons.lock, size: 40, color: Colors.white),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          Text(place.name, style: TextStyle(fontWeight: FontWeight.bold)),
                                          ElevatedButton(
                                            onPressed: isUnlocked
                                                ? () {
                                                    Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PlaceDetailsScreen(place: place),
  ),
);
                                                  }
                                                : () =>{ _showConfirmUnlockDialog(
                                          place.name, place.unlockCost, place),
                                          onPlaceClick(place.name
                                          )
                                          },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isUnlocked ? Colors.grey : Color(0xFFD4F98F),
                                            ),
                                            child: Text(isUnlocked ? "View Details" : "Unlock (${place.unlockCost} coins)"),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            SizedBox(height: 20),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
              ),

              // Onglet Avis (à venir)
              Center(child: Text("Avis à venir...")),
              // Onglet Infos utilisateur
              Center(child: Text("Informations utilisateur à venir...")),
            ],
          ),
        ),
      ],
    )

        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  final VoidCallback? onTap;

  const _StatItem({required this.count, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          Text(label, style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

