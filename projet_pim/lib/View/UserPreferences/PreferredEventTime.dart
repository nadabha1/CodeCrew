import 'package:flutter/material.dart';
import 'package:projet_pim/Providers/UserPreferences.dart';
import 'package:provider/provider.dart';
import 'FinalConfirmationPage.dart';

class PreferredEventTimePage extends StatefulWidget {
  const PreferredEventTimePage({super.key});

  @override
  _PreferredEventTimePageState createState() => _PreferredEventTimePageState();
}

class _PreferredEventTimePageState extends State<PreferredEventTimePage> {
  String? _selectedTime;

  void _navigateToNextPage() {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select your preferred event timing!")),
      );
      return;
    }
    Provider.of<UserPreferences>(context, listen: false)
        .setPreferredEventTime(_selectedTime!);

    // ✅ Navigate to FinalConfirmationPage and indicate it's from Signup
    Navigator.pushNamed(
      context,
      "/final-confirmation",
       // Comes from Signup
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

                // Progress bar
                const LinearProgressIndicator(
                    value: 0.8, color: Color(0xFFD4F98F)),
                const SizedBox(height: 30),

                // Title
                const Text(
                  "WHEN DO YOU PREFER ATTENDING EVENTS?",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "This helps us suggest events that match your schedule.",
                  style: TextStyle(
                      color: Colors.grey), // Appliquer la couleur grise
                ),

                const SizedBox(height: 20),

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

                const Spacer(),

                // Navigation buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8), // Coins un peu arrondis
                        ),
                        backgroundColor: const Color(
                            0xFFF3C7F9), // Optionnel : couleur personnalisée
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
                        backgroundColor: const Color(0xFFEF89FC), // Optionnel
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
