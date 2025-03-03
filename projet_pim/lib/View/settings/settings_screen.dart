import 'package:flutter/material.dart';
import 'package:projet_pim/ViewModel/login.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projet_pim/View/settings/account_settings_screen.dart';
import 'package:projet_pim/View/EditProfileScreen.dart';
import 'package:projet_pim/Providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const SettingsScreen({required this.userData, Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Map<String, dynamic> userData;

  @override
  void initState() {
    super.initState();
    userData = Map<String, dynamic>.from(widget.userData);
  }

  Future<Map<String, String?>> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString('user_id'),
      'token': prefs.getString('jwt_token'),
    };
  }

  Future<void> _navigateToEditProfile() async {
    final session = await _loadUserSession();

    if (session['userId'] == null || session['token'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User session expired. Please log in again.")),
      );
      return;
    }

    final updatedProfileData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          userId: session['userId']!,
          token: session['token']!,
          userData: userData,
          name: userData['name'] ?? 'Unknown Name',
          job: userData['job'] ?? 'No Job Specified',
          location: userData['location'] ?? 'No Location Specified',
          currentProfilePicture: userData['profilePicture'],
        ),
      ),
    );

    if (updatedProfileData != null) {
      setState(() {
        userData['name'] = updatedProfileData['name'];
        userData['job'] = updatedProfileData['job'];
        userData['location'] = updatedProfileData['location'];
        userData['bio'] = updatedProfileData['bio'];
        userData['profilePicture'] = updatedProfileData['profileImage'];
      });
    }
  }

  void _confirmDeleteAccount(BuildContext context) async {
    final session = await _loadUserSession();
    if (session['userId'] == null || session['token'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired. Please log in again.")),
      );
      return;
    }

    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Account"),
        content: Text("Are you sure you want to delete your account? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      final userService = UserService();
      final result = await userService.deleteUserProfile(session['userId']!, session['token']!);

      if (result.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'], style: TextStyle(color: Colors.red))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Account deleted successfully!")),
        );

        final loginViewModel = Provider.of<LoginViewModel>(context, listen: false);
        await loginViewModel.logout(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(219, 217, 254, 1),
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            _buildProfileSection(),
            const SizedBox(height: 20),
            _buildSettingsOptions(themeProvider),
          ],
        ),
      ),
    );
  }

  /// ✅ **Profile Section**
  Widget _buildProfileSection() {
    return GestureDetector(
      onTap: _navigateToEditProfile,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: userData['profilePicture'] != null
                  ? NetworkImage(userData['profilePicture'])
                  : AssetImage('assets/default_profile.png') as ImageProvider,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData['name'] ?? 'Unknown Name',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    userData['bio'] ?? 'Bio not specified',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit, color: Colors.deepPurple, size: 24),
          ],
        ),
      ),
    );
  }

  /// ✅ **Settings Options in Cards**
  Widget _buildSettingsOptions(ThemeProvider themeProvider) {
    return Column(
      children: [
        _buildSettingsCard(
          title: "General",
          children: [
            _buildSettingsTile(Icons.account_circle, "Account Settings", onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AccountSettingsScreen()));
            }),
            _buildSettingsTile(Icons.notifications, "Notifications"),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: "Preferences",
          children: [
            _buildDarkModeSwitch(themeProvider),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          title: "Security",
          children: [
            _buildSettingsTile(Icons.logout, "Logout", iconColor: Colors.blue, onTap: () async {
              final loginViewModel = Provider.of<LoginViewModel>(context, listen: false);
              await loginViewModel.logout(context);
            }),
            _buildSettingsTile(Icons.delete_forever, "Delete Account", iconColor: Colors.red, onTap: () {
              _confirmDeleteAccount(context);
            }),
          ],
        ),
      ],
    );
  }

  /// ✅ **Reusable Card for Settings**
  Widget _buildSettingsCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  /// ✅ **Dark Mode Toggle**
  Widget _buildDarkModeSwitch(ThemeProvider themeProvider) {
    return ListTile(
      leading: Icon(Icons.dark_mode, color: Colors.black),
      title: Text("Dark Mode"),
      trailing: Switch(
        value: themeProvider.themeMode == ThemeMode.dark,
        onChanged: (value) {
          themeProvider.toggleTheme(value);
        },
        activeColor: Colors.deepPurple,
      ),
    );
  }

  /// ✅ **Reusable Settings Tile**
  Widget _buildSettingsTile(IconData icon, String title, {Color iconColor = Colors.black, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: Icon(Icons.arrow_forward_ios, size: 18),
      onTap: onTap,
    );
  }
}
