import 'package:flutter/material.dart';
import 'package:projet_pim/Providers/UserPreferences.dart';
import 'package:provider/provider.dart';

import 'SocialInteractionPage.dart';

class EventPreferencePage extends StatefulWidget {
  @override
  _EventPreferencePageState createState() => _EventPreferencePageState();
}

class _EventPreferencePageState extends State<EventPreferencePage> {
  List<String> _selectedEvents = [];

  final List<String> _eventTypes = [
    "Concerts",
    "Workshops",
    "Networking Events",
    "Sports Activities",
    "Cultural Festivals",
    "Tech Meetups",
    "Art Exhibitions",
    "Other"
  ];

  void _navigateToNextPage() {
    if (_selectedEvents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select at least one event type!")),
      );
      return;
    }
    Provider.of<UserPreferences>(context, listen: false)
        .setEventPreferences(_selectedEvents);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SocialInteractionPage()),
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

          // 📜 Contenu principal avec défilement
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),

                const LinearProgressIndicator(
                    value: 0.75, color: Color(0xFFD4F98F)),
                const SizedBox(height: 30),

                // Title
                const Text(
                  "WHAT KIND OF EVENTS DO YOU LIKE?",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange),
                ),
                const SizedBox(height: 20),

                // Event Preferences (Checkbox List)
                Column(
                  children: _eventTypes.map((event) {
                    return CheckboxListTile(
                      title: Text(event),
                      value: _selectedEvents.contains(event),
                      onChanged: (isSelected) {
                        setState(() {
                          if (isSelected!) {
                            _selectedEvents.add(event);
                          } else {
                            _selectedEvents.remove(event);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }).toList(),
                ),

                const Spacer(),

                // 🔁 Navigation buttons
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
