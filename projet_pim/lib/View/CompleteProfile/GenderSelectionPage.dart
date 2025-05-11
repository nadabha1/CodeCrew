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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 🎨 Formes de fond
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                color: Color.fromARGB(225, 243, 199, 249), // Violet clair
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 500,
            right: -100,
            child: Container(
              width: 300,
              height: 400,
              decoration: const BoxDecoration(
                color: Color.fromARGB(94, 254, 121, 50), // Rose clair
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 🧩 Contenu principal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Skip button en haut à droite
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(), // Pour équilibrer la ligne
                  ],
                ),
                const SizedBox(height: 20),

                const LinearProgressIndicator(
                    value: 0.3, color: Color(0xFFD4F98F)),
                const SizedBox(height: 70),

                const Text(
                  "What is your gender?",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 10),

                const Text("This helps us personalize your journey to you. "),
                const SizedBox(height: 30),

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

                const Spacer(),

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
