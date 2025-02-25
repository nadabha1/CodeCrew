import 'package:flutter/material.dart';
import 'package:projet_pim/Providers/UserPreferences.dart';
import 'package:projet_pim/View/login.dart';
import 'package:provider/provider.dart';
import 'activity_selection_page.dart';

class GenderSelectionPage extends StatefulWidget {
  @override
  _GenderSelectionPageState createState() => _GenderSelectionPageState();
}

class _GenderSelectionPageState extends State<GenderSelectionPage> {
  String? _selectedGender;

  void _navigateToNextPage() {
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select your gender!")),
      );
      return;
    }

    Provider.of<UserPreferences>(context, listen: false)
        .setGender(_selectedGender!);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ActivitySelectionPage()),
    );
  }

  void _skipToLogin() {
    // ✅ Navigate directly to Login Page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginView()),
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
            // ✅ Skip button at the top right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(), // Empty widget to balance the row
                TextButton(
                  onPressed: _skipToLogin,
                  child: Text(
                    "Skip",
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              ],
            ),

            LinearProgressIndicator(value: 0.3, color: Colors.green),
            SizedBox(height: 20),

            Text("What is your gender?",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange)),
            Column(
              children: ["Male", "Female", "Other", "Prefer not to declare"]
                  .map((gender) => RadioListTile<String>(
                        title: Text(gender),
                        value: gender,
                        groupValue: _selectedGender,
                        onChanged: (value) =>
                            setState(() => _selectedGender = value),
                      ))
                  .toList(),
            ),

            Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Previous")),
                ElevatedButton(
                    onPressed: _navigateToNextPage, child: Text("Next")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
