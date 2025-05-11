import 'package:flutter/material.dart';
import 'package:projet_pim/View/profile.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FollowersScreen extends StatefulWidget {
  final List<String> userIds;
  final String token;

  const FollowersScreen(
      {required this.userIds, required this.token, super.key});

  @override
  _FollowersScreenState createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  String? userId;
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  final UserService userService = UserService();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserData();
    await loadUsers();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString("user_id");

    if (storedUserId != null) {
      setState(() {
        userId = storedUserId;
      });
    } else {
      print("User ID is not available");
    }
  }

  Future<void> loadUsers() async {
    UserService userService = UserService();
    List<Map<String, dynamic>> loadedUsers = [];

    for (String id in widget.userIds) {
      try {
        final data = await userService.getUserById(id, widget.token);

        if (data is Map<String, dynamic>) {
          // Ajouter un champ 'isFollowing' pour chaque utilisateur
          data['isFollowing'] =
              false; // Par défaut, les utilisateurs ne sont pas suivis
          loadedUsers.add(data);
        } else {
          print("⚠️ L'utilisateur avec l'ID $id est nul ou mal formé.");
        }
      } catch (e) {
        print("❌ Erreur lors du chargement de l'utilisateur $id : $e");
      }
    }

    setState(() {
      users = loadedUsers;
      isLoading = false;
    });
  }

  // Fonction pour suivre/désabonner un utilisateur
  Future<void> toggleFollow(int index) async {
    try {
      final user = users[index];
      if (user['isFollowing']) {
        await userService.unfollowUser(userId!, user['_id']);
      } else {
        await userService.followUser(userId!, user['_id']);
      }

      setState(() {
        user['isFollowing'] = !user['isFollowing'];
      });
    } catch (e) {
      print("❌ Erreur lors du suivi/désabonnement: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Followers')),
      body: isLoading || userId == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];

                return ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: user['profileImage'] != null &&
                            user['profileImage'].toString().isNotEmpty
                        ? NetworkImage(user['profileImage'])
                        : const AssetImage('assets/default_profile.png')
                            as ImageProvider,
                  ),
                  title: Text(user['name'] ?? 'Nom inconnu'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      toggleFollow(index); // Toggle follow/unfollow
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: user['isFollowing']
                          ? const Color(0x0f6f6666)
                          : const Color(0xFFD4F98F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(user['isFollowing'] ? "Unfollow" : "Follow"),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TravelerProfileScreen(
                          travelerId: user['_id'],
                          loggedInUserId: userId!,
                          token: widget.token,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
