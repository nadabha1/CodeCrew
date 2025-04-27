import 'package:flutter/material.dart';
import 'package:projet_pim/View/EditProfileScreen.dart';
import 'package:projet_pim/View/UserPreferences/GenderSelectionPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateChoiceScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UpdateChoiceScreen({required this.userData, Key? key}) : super(key: key);

  Future<Map<String, String?>> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString('user_id'),
      'token': prefs.getString('jwt_token'),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('What do you want to update?'),
        backgroundColor: const Color.fromRGBO(219, 217, 254, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildOption(
              context,
              icon: Icons.person,
              title: 'Update Profile Info',
              onTap: () async {
                final session = await _loadUserSession();
                if (session['userId'] != null && session['token'] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(
                        userId: session['userId']!,
                        token: session['token']!,
                        userData: userData,
                        name: userData['name'] ?? 'Unknown Name',
                        job: userData['job'] ?? 'No Job',
                        location: userData['location'] ?? 'Unknown',
                        currentProfilePicture: userData['profilePicture'],
                      ),
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 20),
            _buildOption(
              context,
              icon: Icons.favorite,
              title: 'Update Preferences',
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GenderSelectionPage(
                      
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple, size: 30),
      title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      trailing: Icon(Icons.arrow_forward_ios),
      tileColor: Colors.grey.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      onTap: onTap,
    );
  }
}
