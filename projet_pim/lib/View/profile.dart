import 'package:flutter/material.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:projet_pim/ViewModel/carnet_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TravelerProfileScreen extends StatefulWidget {
  final String travelerId;
  final String loggedInUserId;

  const TravelerProfileScreen({required this.travelerId, required this.loggedInUserId, Key? key})
      : super(key: key);

  @override
  _TravelerProfileScreenState createState() => _TravelerProfileScreenState();
}

class _TravelerProfileScreenState extends State<TravelerProfileScreen> {
  Map<String, dynamic>? travelerData;
  List<Carnet> travelerCarnets = [];
  bool isLoading = true;
  bool isFollowing = false;
  String? _userId;
  String? _token;
  UserService userService = UserService();

  @override
  void initState() {
    super.initState();
    fetchTravelerProfile();
    fetchFollowerData();
  }

  Future<void> fetchFollowerData() async {
    try {
      List<String> followers = await userService.getFollowers(widget.travelerId);
      List<String> following = await userService.getFollowing(widget.travelerId);
      int followersCount = await userService.getFollowersCount(widget.travelerId);
      int followingCount = await userService.getFollowingCount(widget.travelerId);

      setState(() {
        travelerData?['followers'] = followers;
        travelerData?['following'] = following;
        travelerData?['followersCount'] = followersCount;
        travelerData?['followingCount'] = followingCount;
        isFollowing = followers.contains(widget.loggedInUserId);
      });
    } catch (e) {
      print("❌ Error fetching followers/following: $e");
    }
  }

  Future<void> fetchTravelerProfile() async {
    try {
      UserService userService = UserService();
      CarnetService carnetService = CarnetService();
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString("user_id");
      _token = prefs.getString("jwt_token");

      Map<String, dynamic> traveler = await userService.getUserById(widget.travelerId, _token!);
      List<dynamic> carnetList = await carnetService.getUserCarnet(widget.travelerId);
      List<Carnet> carnets = carnetList.map((json) => Carnet.fromJson(json)).toList();

      setState(() {
        travelerData = traveler;
        travelerCarnets = carnets;
        isFollowing = traveler['followers']?.contains(widget.loggedInUserId) ?? false;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching traveler profile: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> toggleFollow() async {
    try {
      if (isFollowing) {
        await userService.unfollowUser(widget.loggedInUserId, widget.travelerId);
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
                          backgroundImage: travelerData?['profileImage'] != null
                              ? NetworkImage(travelerData!['profileImage'])
                              : AssetImage('assets/default_profile.png') as ImageProvider,
                        ),
                        SizedBox(height: 10),
                        Text(
                          travelerData?['name'] ?? 'Unknown Traveler',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(travelerData?['location'] ?? 'Unknown Location'),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing ? Colors.grey : Colors.blue,
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
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Carnet d'Adresses", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        travelerCarnets.isNotEmpty
                            ? Column(
                                children: travelerCarnets.map<Widget>((carnet) {
                                  return Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    child: Column(
                                      children: carnet.places.map<Widget>((place) {
                                        return ListTile(
                                          title: Text(place.name),
                                          subtitle: Text(place.description ?? 'Unknown location'),
                                          leading: Icon(Icons.place, color: Colors.blue),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                }).toList(),
                              )
                            : Center(child: Text("No carnet available")),
                      ],
                    ),
                  ),
                ],
              ),
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
        Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        Text(label, style: TextStyle(color: Colors.black54)),
      ],
    );
  }
}
