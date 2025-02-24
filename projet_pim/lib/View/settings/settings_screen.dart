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
    userData = Map<String, dynamic>.from(widget.userData); // ✅ Clone userData
  }

  /// ✅ **Load User Session from SharedPreferences**
  Future<Map<String, String?>> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString('user_id'),
      'token': prefs.getString('jwt_token'),
    };
  }

  /// ✅ **Navigate to Edit Profile & Update UI on Return**
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

    // ✅ Update UI if user changed profile details
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

  /// ✅ **Confirm and Delete User Account**
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
        // ✅ Log out the user and redirect to login page
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ **Profile Section with Edit Option**
              GestureDetector(
                onTap: _navigateToEditProfile,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: userData['profilePicture'] != null
                          ? NetworkImage(userData['profilePicture'])
                          : const AssetImage('assets/default_profile.png') as ImageProvider,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['name'] ?? 'Unknown Name',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            userData['bio'] ?? 'Bio not specified',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.edit, color: Theme.of(context).iconTheme.color, size: 20),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              
              // ✅ **Dark Mode Toggle**
              _buildToggleThemeSwitch(themeProvider),

              const SizedBox(height: 30),

              // ✅ **General Settings Header**
              Text(
                "GENERAL",
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 10),

              // ✅ **Settings Options**
              _buildSettingsTile(
                context,
                icon: Icons.account_circle,
                title: "Account Settings",
                subtitle: "Manage Privacy, Terms, Help",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AccountSettingsScreen()),
                ),
              ),
              _buildSettingsTile(
                context,
                icon: Icons.notifications,
                title: "Notifications",
                subtitle: "Newsletter, App Updates",
              ),
              _buildSettingsTile(
                context,
                icon: Icons.logout,
                title: "Logout",
                iconColor: Colors.blue,
                onTap: () async {
                   final loginViewModel = Provider.of<LoginViewModel>(context, listen: false);
                   await loginViewModel.logout(context);
                },
              ),
              _buildSettingsTile(
                context,
                icon: Icons.delete_forever,
                title: "Delete Account",
                iconColor: Colors.red,
                onTap: () => _confirmDeleteAccount(context),
              ),
            ],
          ),
        ),
      ),
    );
  }


  /// ✅ **Dark Mode Toggle**
  Widget _buildToggleThemeSwitch(ThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.themeMode == ThemeMode.dark ? Colors.grey[800] : Colors.black12,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.dark_mode, color: Theme.of(context).iconTheme.color, size: 24),
              const SizedBox(width: 12),
              Text(
                "Dark Mode",
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          Switch(
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
            activeColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  /// ✅ **Reusable Settings Tile**
  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String subtitle = "",
    Color iconColor = Colors.white,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.black26,
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70,
                fontSize: 13,
              ),
            )
          : null,
      trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).iconTheme.color ?? Colors.black, size: 18),
      onTap: onTap,
    );
  }
  
}
