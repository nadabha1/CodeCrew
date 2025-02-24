import 'package:flutter/material.dart';
import 'package:projet_pim/Providers/UserPreferences.dart';
import 'package:provider/provider.dart';

import 'FinalConfirmationPage.dart';

class SocialInteractionPage extends StatefulWidget {
  @override
  _SocialInteractionPageState createState() => _SocialInteractionPageState();
}

class _SocialInteractionPageState extends State<SocialInteractionPage> {
  String? _socialPreference;

  void _navigateToNextPage() {
    if (_socialPreference == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Please select how you prefer to interact socially!")),
      );
      return;
    }
    Provider.of<UserPreferences>(context, listen: false)
        .setSocialPreference(_socialPreference!);
    Navigator.pushReplacementNamed(context, "/preferred-event-time");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: 0.9, color: Colors.green),
            SizedBox(height: 20),

            // Title
            Text(
              "HOW DO YOU LIKE TO SOCIALIZE?",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange),
            ),
            SizedBox(height: 10),

            // Social Preferences (Radio Buttons)
            Column(
              children: [
                "Solo Activities",
                "Small Groups",
                "Large Gatherings",
                "No Preference"
              ]
                  .map((option) => RadioListTile<String>(
                        title: Text(option),
                        value: option,
                        groupValue: _socialPreference,
                        onChanged: (value) {
                          setState(() {
                            _socialPreference = value;
                          });
                        },
                      ))
                  .toList(),
            ),

            Spacer(),

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
                  onPressed: _navigateToNextPage,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                  child: Text("Next"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
