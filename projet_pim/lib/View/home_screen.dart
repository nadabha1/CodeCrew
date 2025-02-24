import 'package:flutter/material.dart';
import 'package:projet_pim/View/profile.dart';
import 'package:projet_pim/ViewModel/user_service.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  // ✅ Fetch users excluding the current user
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 HEADER SECTION
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, Traveler! 👋",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text("Find people who share your interests"),
                    ],
                  ),
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/default_profile.png'),
                    radius: 24,
                  ),
                ],
              ),
            ),

            // 🔹 TRAVELER CATEGORIES (Horizontal Scroll)
            Container(
              height: 40,
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _categoryChip("Photographers"),
                  _categoryChip("Hikers"),
                  _categoryChip("Foodies"),
                  _categoryChip("Solo Travelers"),
                  _categoryChip("Backpackers"),
                ],
              ),
            ),
            SizedBox(height: 10),

            // 🔹 DISCOVER TRAVELERS TITLE
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Find Your Similar Traveler",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10),

            // 🔹 USERS LIST (Traveler Cards)
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : users.isEmpty
                      ? Center(child: Text("No travelers found"))
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 15),
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
                                    builder: (context) => TravelerProfileScreen(
                                      travelerId: user['_id']   ,
                                      loggedInUserId: this.widget.userId,                                 ),
                                  ),
                                );
                              },
                              child: _userCard(user),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Traveler Category Chip
  Widget _categoryChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        backgroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
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
}
