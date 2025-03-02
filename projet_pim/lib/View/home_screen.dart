import 'package:flutter/material.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/View/carnet&place/AddPlaceScreenStep1.dart';
import 'package:projet_pim/View/carnet&place/PlaceDetailsScreen.dart';
import 'package:projet_pim/View/carnet&place/carnet_dtetails_screen.dart';
import 'package:projet_pim/View/profile.dart';
import 'package:provider/provider.dart';
import '../Providers/carnet_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:projet_pim/providers/review_provider.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CarnetProvider? provider;
  List<dynamic> users = [];
  bool isLoadingUsers = true;

  void _reloadData() async {
    if (provider != null) {
      await provider!.fetchCarnetsExcludingUser(widget.userId);
      await provider!.fetchUnlockedPlaces(widget.userId);
      await fetchUsers(); // Fetch users when data is reloaded
      if (mounted) setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    provider ??= Provider.of<CarnetProvider>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadData());
  }

  @override
  void dispose() {
    provider = null;
    super.dispose();
  }

  Future<void> fetchUsers() async {
    try {
      UserService userService = UserService();
      List<dynamic> fetchedUsers = await userService.getAllUsers(widget.userId);
      setState(() {
        users = fetchedUsers;
        isLoadingUsers = false;
      });
    } catch (e) {
      print("Error fetching users: $e");
      setState(() => isLoadingUsers = false);
    }
  }

  void _showUnlockDialog(String placeName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Success!"),
          content: Text("You have successfully unlocked $placeName!"),
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
          title: Text("Error"),
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
                Navigator.of(context).pop(); // Close the dialog
                try {
                  await provider!.unlockPlace(
                      widget.userId, place.id); // Use the instance method
                  _showUnlockDialog(placeName);
                  _reloadData();
                } catch (e) {
                  _showErrorDialog(e.toString());
                }
              },
              child: Text("Confirm"),
            ),
          ],
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final carnetProvider = Provider.of<CarnetProvider>(context, listen: true);
    final otherCarnets =
        carnetProvider.carnets.where((c) => c.owner != widget.userId).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FC),
      body: SafeArea(
        child: carnetProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(Icons.menu, color: Colors.black, size: 28),
                              CircleAvatar(
                                backgroundImage:
                                    AssetImage('assets/default_profile.png'),
                                radius: 22,
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Text(
                            "Hey User!",
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Where's your next trip going to be?",
                            style: TextStyle(fontSize: 16, color: Colors.brown),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text("Near Your Location",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    otherCarnets.isEmpty
                        ? Center(child: Text("No other carnets available"))
                        : Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Other Carnets",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 10),
                                // Liste des carnets avec places
                                ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: otherCarnets.length,
                                  itemBuilder: (context, index) {
                                    final carnet = otherCarnets[index];
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          carnet.title,
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 10),
                                        // Liste des places de ce carnet en défilement horizontal
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children:
                                                carnet.places.map((place) {
                                              bool isUnlocked = carnetProvider
                                                  .isPlaceUnlocked(place.id);
                                              return Card(
                                                margin: EdgeInsets.symmetric(
                                                    horizontal: 10),
                                                child: Container(
                                                  width: 190, // Card width
                                                  padding: EdgeInsets.all(10),
                                                  child: Column(
                                                    children: [
                                                      place.images.isNotEmpty
                                                          ? Image.network(
                                                              place
                                                                  .images.first,
                                                              width: 140,
                                                              height: 120,
                                                              fit: BoxFit.cover,
                                                            )
                                                          : Icon(
                                                              isUnlocked
                                                                  ? Icons
                                                                      .lock_open
                                                                  : Icons.lock,
                                                              color: isUnlocked
                                                                  ? Colors.green
                                                                  : Colors.red,
                                                            ),
                                                      SizedBox(height: 10),
                                                      Text(
                                                        place.name,
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: isUnlocked
                                                            ? () {
                                                                // Navigate to the PlaceDetailsScreen if the place is unlocked
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder: (context) =>
                                                                        ChangeNotifierProvider<
                                                                            ReviewProvider>(
                                                                      create: (_) =>
                                                                          ReviewProvider(),
                                                                      child: PlaceDetailsScreen(
                                                                          place:
                                                                              place),
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            : () async {
                                                                // Show the unlock confirmation dialog if the place is not unlocked
                                                                _showConfirmUnlockDialog(
                                                                    place.name,
                                                                    place
                                                                        .unlockCost,
                                                                    place);
                                                              },
                                                        child: Text(
                                                          isUnlocked
                                                              ? "View Details"
                                                              : "Unlock (5 coins)",
                                                        ),
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              isUnlocked
                                                                  ? Color(
                                                                      0xFF9E9E9E)
                                                                  : Color(
                                                                      0xFFD4F98F),
                                                        ),
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
                                  },
                                ),
                              ],
                            ),
                          ),
                    // Similar Traveler section
                    SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Find Your Similar Traveler",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    isLoadingUsers
                        ? const Center(child: CircularProgressIndicator())
                        : users.isEmpty
                            ? Center(child: Text("No travelers found"))
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  final user = users[index];
                                  return GestureDetector(
                                    onTap: () {
                                      print(user['_id']);
                                      // ✅ Navigate to user's profile
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TravelerProfileScreen(
                                            travelerId: user['_id'],
                                            loggedInUserId: widget.userId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      title: Text(user['name']),
                                      subtitle: Text(user['email']),
                                      leading: CircleAvatar(
                                        backgroundImage: user[
                                                        'profileImageUrl'] !=
                                                    null &&
                                                user['profileImageUrl']
                                                    .isNotEmpty
                                            ? NetworkImage(
                                                user['profileImageUrl'])
                                            : AssetImage(
                                                    'assets/default_profile.png')
                                                as ImageProvider,
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ],
                ),
              ),
      ),
    );
  }
}
