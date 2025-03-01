import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projet_pim/View/profile.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import '../Providers/carnet_provider.dart';
import 'package:projet_pim/View/carnet&place/AddPlaceScreenStep1.dart';
import 'package:projet_pim/View/carnet&place/PlaceDetailsScreen.dart';
import 'package:projet_pim/View/carnet&place/carnet_dtetails_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> users = [];
  bool isLoading = true;
  CarnetProvider? provider;

  @override
  void initState() {
    super.initState();
    fetchUsers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadData());
  }

  void _reloadData() async {
    if (provider != null) {
      await provider!.fetchCarnetsExcludingUser(widget.userId);
      await provider!.fetchUnlockedPlaces(widget.userId);
      if (mounted) setState(() {});
    }
  }

  Future<void> fetchUsers() async {
    try {
      UserService userService = UserService();
      List<dynamic> fetchedUsers = await userService.getAllUsers(widget.userId);
      setState(() {
        users = fetchedUsers;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching users: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    provider ??= Provider.of<CarnetProvider>(context, listen: true);
    final otherCarnets =
        provider!.carnets.where((c) => c.owner != widget.userId).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FC),
      body: SafeArea(
        child: ListView(
          children: [
            _buildHeader(),
            _buildTravelerSection(),
            _buildCarnetSection(otherCarnets),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD4F98F),
        child: Icon(Icons.add),
        onPressed: _handleFloatingButton,
      ),
    );
  }

  Widget _buildCarnetSection(List<dynamic> otherCarnets) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Explore Nearby Carnets", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          otherCarnets.isEmpty
              ? Center(child: Text("No carnets available"))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: otherCarnets.length,
                  itemBuilder: (context, index) {
                    final carnet = otherCarnets[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 10),
                      child: ExpansionTile(
                        title: Text(carnet.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        children: carnet.places.map<Widget>((place) {
                          bool isUnlocked = provider!.isPlaceUnlocked(place.id);
                          return ListTile(
                            title: Text(place.name),
                            subtitle: Text(place.description),
                            leading: Icon(
                              isUnlocked ? Icons.lock_open : Icons.lock,
                              color: isUnlocked ? Colors.green : Colors.red,
                            ),
                            trailing: isUnlocked
                                ? null
                                : ElevatedButton(
                                    onPressed: () => _showConfirmUnlockDialog(place.name, place.unlockCost, place),
                                    child: Text("Unlock (5 coins)", style: TextStyle(color: Colors.black)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD4F98F),
                                      foregroundColor: Colors.black,
                                    ),
                                  ),
                            onTap: isUnlocked
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PlaceDetailsScreen(place: place),
                                      ),
                                    );
                                  }
                                : null,
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  void _showConfirmUnlockDialog(String placeName, int placePrice, place) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Payment Confirmation"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Do you want to unlock '$placeName'?"),
              SizedBox(height: 10),
              Text("Price to unlock: $placePrice coins"),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await provider!.unlockPlace(widget.userId, place.id);
                  _reloadData();
                } catch (e) {
                  print("Error unlocking place: $e");
                }
              },
              child: Text("Confirm"),
            ),
          ],
        );
      },
    );
  }
    Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFDBD9FE),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hello, Traveler! 👋", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text("Find people & explore new places!"),
            ],
          ),
          CircleAvatar(
            backgroundImage: AssetImage('assets/default_profile.png'),
            radius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildTravelerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(20),
          child: Text("Find Your Similar Traveler", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        isLoading
            ? Center(child: CircularProgressIndicator())
            : users.isEmpty
                ? Center(child: Text("No travelers found"))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TravelerProfileScreen(
                                travelerId: user['_id'],
                                loggedInUserId: widget.userId,
                              ),
                            ),
                          );
                        },
                        child: _userCard(user),
                      );
                    },
                  ),
      ],
    );
  }

  // 🔹 User Traveler Card (Styled like TripGlide)
  Widget _userCard(Map<String, dynamic> user) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      margin: EdgeInsets.only(bottom: 15),
      child: Stack(
        children: [
          // Traveler Image
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: DecorationImage(
                image: user['profileImage'] != null
                    ? NetworkImage(user['profileImage'])
                    : AssetImage('assets/default_profile.png') as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Dark Gradient Overlay
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),

          // Traveler Info (Name & Location)
          Positioned(
            left: 15,
            bottom: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      user['location'] ?? 'Unknown Location',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Favorite (Heart) Icon
          Positioned(
            right: 15,
            top: 15,
            child: Icon(
              Icons.favorite_border,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
   void _handleFloatingButton() async {
    await provider!.checkUserCarnet(widget.userId);
    if (provider!.userCarnet == null || !provider!.userCarnet!['hasCarnet']) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateCarnetScreen(userId: widget.userId),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddPlaceScreenStep1(
            carnetId: provider!.userCarnet!['carnet']['_id'],
          ),
        ),
      );
    }
  }
}
