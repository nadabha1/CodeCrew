import 'package:flutter/material.dart';
import 'package:projet_pim/Providers/UserPreferences.dart';
import 'package:provider/provider.dart';

import 'EventPreferencePage.dart';

class ActivitySelectionPage extends StatefulWidget {
  @override
  _ActivitySelectionPageState createState() => _ActivitySelectionPageState();
}

class _ActivitySelectionPageState extends State<ActivitySelectionPage> {
  List<String> _selectedActivities = [];
  String? _preference;
  String? _socialMediaParticipation;

  final List<String> _activities = [
    "Sport",
    "Watch Movies",
    "Camping",
    "Other"
  ];
  void _navigateToNextPage() {
    if (_selectedActivities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select at least one activity!")),
      );
      return;
    }
    Provider.of<UserPreferences>(context, listen: false)
        .setFavoriteActivities(_selectedActivities);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EventPreferencePage()),
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
            LinearProgressIndicator(value: 0.6, color: Colors.green),
            SizedBox(height: 20),

            // Header Text
            Text(
              "WHAT ACTIVITIES DO YOU ENJOY DURING YOUR FREE TIME?",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange),
            ),
            SizedBox(height: 10),

            // Suggestion Label
            Text("Suggestion:", style: TextStyle(fontWeight: FontWeight.bold)),

            SizedBox(height: 10),

            // Activity Selection (Checkbox List)
            Column(
              children: _activities.map((activity) {
                return CheckboxListTile(
                  title: Text(activity),
                  value: _selectedActivities.contains(activity),
                  onChanged: (isSelected) {
                    setState(() {
                      if (isSelected!) {
                        _selectedActivities.add(activity);
                      } else {
                        _selectedActivities.remove(activity);
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
            ),

            SizedBox(height: 20),

            // Preference: Indoor or Outdoor
            Text("Do you prefer:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: ["In Door", "Out Door"]
                  .map((option) => Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _preference = option;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _preference == option
                                ? Colors.pink
                                : Colors.grey[200],
                          ),
                          child: Text(option,
                              style: TextStyle(
                                  color: _preference == option
                                      ? Colors.white
                                      : Colors.black)),
                        ),
                      ))
                  .toList(),
            ),

            SizedBox(height: 20),

            // Social Media Participation
            Text("How often do you participate in social media?",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              decoration: InputDecoration(
                hintText: "e.g., Daily, Weekly, Rarely",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => _socialMediaParticipation = value,
            ),

            Spacer(),

            // Previous & Next Buttons
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
