import 'package:flutter/material.dart';
import 'package:projet_pim/Model/user_entity.dart';

class FollowersFollowingListScreen extends StatelessWidget {
  final List<User> users;
  final String title;

  const FollowersFollowingListScreen({
    required this.users,
    required this.title,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: users.isEmpty
          ? const Center(
              child: Text(
                "Aucun utilisateur",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.separated(
              itemCount: users.length,
              separatorBuilder: (context, index) =>
                  Divider(indent: 80, endIndent: 20, color: Colors.grey.shade300),
              itemBuilder: (context, index) {
                final user = users[index];

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // 👇 Replace with your profile screen
                    // Navigator.push(context, MaterialPageRoute(
                    //   builder: (_) => TravelerProfileScreen(travelerId: user.id, loggedInUserId: ...),
                    // ));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Avatar
                        Material(
                          elevation: 2,
                          shape: const CircleBorder(),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundImage: user.profileImage != null
                                ? NetworkImage(user.profileImage!)
                                : const AssetImage('assets/default_profile.png') as ImageProvider,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Name + Email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Button
                        ElevatedButton(
                          onPressed: () {
                            // Optional: Navigate or Follow/Unfollow
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple.shade50,
                            foregroundColor: Colors.deepPurple,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "Voir",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
