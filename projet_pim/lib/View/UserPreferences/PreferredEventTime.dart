import 'package:flutter/material.dart';
import 'package:projet_pim/Providers/UserPreferences.dart';
import 'package:provider/provider.dart';
import 'FinalConfirmationPage.dart';

class PreferredEventTimePage extends StatefulWidget {
  @override
  _PreferredEventTimePageState createState() => _PreferredEventTimePageState();
}

class _PreferredEventTimePageState extends State<PreferredEventTimePage> {
  String? _selectedTime;

  void _navigateToNextPage() {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select your preferred event timing!")),
      );
      return;
    }
    Provider.of<UserPreferences>(context, listen: false)
        .setPreferredEventTime(_selectedTime!);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FinalConfirmationPage()),
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
            // Progress bar
            LinearProgressIndicator(value: 0.8, color: Colors.green),
            SizedBox(height: 20),

            // Title
            Text(
              "WHEN DO YOU PREFER ATTENDING EVENTS?",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 8),
            Text("This helps us suggest events that match your schedule."),

            SizedBox(height: 20),

            // Time selection options
            Column(
              children: ["Morning", "Afternoon", "Evening", "Late Night"]
                  .map((time) => RadioListTile<String>(
                        title: Text(time),
                        value: time,
                        groupValue: _selectedTime,
                        onChanged: (value) {
                          setState(() {
                            _selectedTime = value;
                          });
                        },
                      ))
                  .toList(),
            ),

            Spacer(),

            // Navigation buttons
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
