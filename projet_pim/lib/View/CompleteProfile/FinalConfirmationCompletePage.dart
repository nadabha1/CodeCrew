import 'package:flutter/material.dart';
import 'package:projet_pim/Providers/UserPreferences.dart';
import 'package:projet_pim/Providers/auth_provider.dart';
import 'package:projet_pim/View/settings/settings_screen.dart';
import 'package:projet_pim/View/user_profile.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinalConfirmationCompletePage extends StatefulWidget {
  const FinalConfirmationCompletePage({Key? key}) : super(key: key);

  @override
  _FinalConfirmationCompletePage createState() =>
      _FinalConfirmationCompletePage();
}

class _FinalConfirmationCompletePage
    extends State<FinalConfirmationCompletePage> {
  String? userId;
  String? token;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? _userId = prefs.getString("user_id");
    String? _token = prefs.getString("jwt_token");

    if (_userId != null && _token != null) {
      setState(() {
        userId = _userId;
        token = _token;
        isLoading = false;
      });
    } else {
      print("User ID or Token is not available");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if the data is loaded
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Retrieve the argument to determine source
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool fromSignup =
        args?["fromSignup"] ?? false; // Default: from Profile

    final userPrefs = Provider.of<UserPreferences>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const LinearProgressIndicator(value: 1.0, color: Color(0xFFD4F98F)),
            const SizedBox(height: 20),
            const Text(
              "🎉 Ready to Connect?",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _buildPreferenceCard(Icons.person, "Gender",
                      userPrefs.gender ?? "Not provided"),
                  _buildPreferenceCard(
                      Icons.sports_soccer,
                      "Favorite Activities",
                      userPrefs.favoriteActivities.join(", ") ??
                          "Not provided"),
                  _buildPreferenceCard(Icons.event, "Event Preferences",
                      userPrefs.eventPreferences.join(", ") ?? "Not provided"),
                  _buildPreferenceCard(Icons.groups, "Social Preference",
                      userPrefs.socialPreference ?? "Not provided"),
                  _buildPreferenceCard(
                      Icons.access_time,
                      "Preferred Event Timing",
                      userPrefs.preferredEventTime ?? "Not provided"),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: const Color(0xFFF3C7F9),
                  ),
                  child: const Text(
                    "Previous",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _finishOnboarding(context, fromSignup),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: const Color(0xFFEF89FC),
                  ),
                  child: const Text(
                    "Finish",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _finishOnboarding(BuildContext context, bool fromSignup) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userPrefs = Provider.of<UserPreferences>(context, listen: false);

    if (userId == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("User ID or Token not found. Please log in again."),
            backgroundColor: Colors.red),
      );
      return;
    }

    // Use userId and token in the request
    bool success = await authProvider.addUserPreferences(userPrefs, userId!);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Preferences added successfully!"),
            backgroundColor: Colors.green),
      );

      // Navigate to Login after Signup
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(
            userId: userId!,
            token: token!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Error adding preferences"),
            backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildPreferenceCard(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: Colors.orange, size: 30),
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text(value,
            style: const TextStyle(fontSize: 14, color: Colors.black54)),
      ),
    );
  }
}
