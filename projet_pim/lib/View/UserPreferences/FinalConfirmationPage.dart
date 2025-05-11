import 'package:flutter/material.dart';
import 'package:projet_pim/Providers/UserPreferences.dart';
import 'package:projet_pim/Providers/auth_provider.dart';
import 'package:projet_pim/View/login.dart';
import 'package:provider/provider.dart';

class FinalConfirmationPage extends StatelessWidget {
  const FinalConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
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

    if (authProvider.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("User ID not found. Please log in again."),
            backgroundColor: Colors.red),
      );
      return;
    }

    bool success =
        await authProvider.addUserPreferences(userPrefs, authProvider.userId!);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Preferences added successfully!"),
            backgroundColor: Colors.green),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginView(),
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
