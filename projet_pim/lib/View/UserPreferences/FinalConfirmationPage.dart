import 'package:flutter/material.dart';
import 'package:projet_pim/Providers/UserPreferences.dart';
import 'package:provider/provider.dart';

class FinalConfirmationPage extends StatelessWidget {
  void _finishOnboarding(BuildContext context) {
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    final userPrefs = Provider.of<UserPreferences>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bar
            LinearProgressIndicator(value: 1.0, color: Colors.green),
            SizedBox(height: 20),

            // Title
            Text(
              "🎉 Ready to Connect?",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange),
            ),
            SizedBox(height: 10),

            // User Preferences Section
            Expanded(
              child: ListView(
                children: [
                  _buildPreferenceCard(Icons.person, "Gender",
                      userPrefs.gender ?? "Not provided"),
                  _buildPreferenceCard(
                      Icons.sports_soccer,
                      "Favorite Activities",
                      userPrefs.favoriteActivities?.join(", ") ??
                          "Not provided"),
                  _buildPreferenceCard(Icons.event, "Event Preferences",
                      userPrefs.eventPreferences?.join(", ") ?? "Not provided"),
                  _buildPreferenceCard(Icons.groups, "Social Preference",
                      userPrefs.socialPreference ?? "Not provided"),
                  _buildPreferenceCard(
                      Icons.access_time,
                      "Preferred Event Timing",
                      userPrefs.preferredEventTime ?? "Not provided"),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[100]),
                  child: Text("Previous"),
                ),
                ElevatedButton(
                  onPressed: () => _finishOnboarding(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                  child: Text("Finish"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for Preference Cards
  Widget _buildPreferenceCard(IconData icon, String title, String value) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: Colors.orange, size: 30),
        title: Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle:
            Text(value, style: TextStyle(fontSize: 14, color: Colors.black54)),
      ),
    );
  }
}
