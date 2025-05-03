import 'package:flutter/material.dart';
import 'package:projet_pim/Providers/UserPreferences.dart';
import 'package:provider/provider.dart';

import 'EventPreferencePage.dart';

class ActivitySelectionPage extends StatefulWidget {
  const ActivitySelectionPage({super.key});

  @override
  _ActivitySelectionPageState createState() => _ActivitySelectionPageState();
}

class _ActivitySelectionPageState extends State<ActivitySelectionPage> {
  final List<String> _selectedActivities = [];
  String? _preference;
  String? _socialMediaParticipation;

  final List<String> _activities = [
    "Sport",
    "Watch Movies",
    "Camping",
    "Other",
    "Randonnée & Exploration",
    "Visite de musées & monuments",
    "Découverte de cafés & bars atypiques",
    "Concerts & Spectacles",
    "Shopping & marchés locaux",
    "Parcs d’attractions & Loisirs",
  ];

  void _navigateToNextPage() {
    if (_selectedActivities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one activity!")),
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
          SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  const LinearProgressIndicator(
                      value: 0.6, color: Color(0xFFD4F98F)),
                  const SizedBox(height: 40),

                  const Text(
                    "WHAT ACTIVITIES DO YOU ENJOY DURING YOUR FREE TIME?",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange),
                  ),
                  const SizedBox(height: 10),

                  const Text("Suggestion:",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),

                  // ✅ Activités
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

                  const SizedBox(height: 20),

                  const Text("Do you prefer:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: ["In Door", "Out Door"]
                        .map((option) => Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _preference = option;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _preference == option
                                        ? const Color.fromARGB(
                                            255, 255, 200, 249)
                                        : Colors.grey[200],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _preference == option
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 20),

                  const Text("How often do you participate in social media?",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "e.g., Daily, Weekly, Rarely",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) => _socialMediaParticipation = value,
                  ),

                  const SizedBox(height: 20),

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
          ),
        ],
      ),
    );
  }
}
