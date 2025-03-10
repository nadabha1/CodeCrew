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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: 0.75, color: Colors.green),
            SizedBox(height: 20),

            // Title
            Text(
              "WHAT KIND OF EVENTS DO YOU LIKE?",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange),
            ),
            SizedBox(height: 10),

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
