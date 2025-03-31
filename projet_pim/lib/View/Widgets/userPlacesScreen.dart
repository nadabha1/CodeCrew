import 'package:flutter/material.dart';

class UserPlacesScreen extends StatelessWidget {
  final String userId;
  const UserPlacesScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    // Replace this with real data fetching logic
    final List<Map<String, String>> fakePlaces = [
      {
        'name': 'Café de Flore',
        'image': 'https://images.unsplash.com/photo-1588854337114-1d60c6c6a341'
      },
      {
        'name': 'Louvre Museum',
        'image': 'https://images.unsplash.com/photo-1578926288102-8d9cbed7c0d4'
      }
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Lieux de l’utilisateur'),
        backgroundColor: Color(0xFF6C63FF),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: fakePlaces.length,
        itemBuilder: (context, index) {
          final place = fakePlaces[index];
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    place['image']!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    place['name']!,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
