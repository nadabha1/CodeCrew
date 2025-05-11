import 'package:flutter/material.dart';
import 'package:projet_pim/Providers/UserPreferences.dart';
import 'package:projet_pim/View/CompleteProfile/PreferredEventTime.dart';
import 'package:provider/provider.dart';

import 'FinalConfirmationCompletePage.dart';

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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PreferredEventTimePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 🎨 Formes de fond
          Positioned(
            top: -60,
            left: 300,
            child: Container(
              width: 200,
              height: 300,
              decoration: const BoxDecoration(
                color: Color.fromARGB(225, 243, 199, 249), // Violet clair
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 500,
            right: 350,
            child: Container(
              width: 300,
              height: 400,
              decoration: const BoxDecoration(
                color: Color.fromARGB(94, 254, 121, 50), // Orange doux
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 📜 Contenu principal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),

                const LinearProgressIndicator(
                    value: 0.9, color: Color(0xFFD4F98F)),
                const SizedBox(height: 20),

                // Title
                const Text(
                  "HOW DO YOU LIKE TO SOCIALIZE?",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange),
                ),
                const SizedBox(height: 10),

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

                const Spacer(),

                // Navigation Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 16),
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
                      onPressed: _navigateToNextPage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 70, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: const Color(0xFFEF89FC),
                      ),
                      child: const Text(
                        "Next",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
