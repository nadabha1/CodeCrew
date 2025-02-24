import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_pim/View/carnet&place/AddPlaceScreenStep2.dart';

class AddPlaceScreenStep1 extends StatefulWidget {
  final String carnetId;

  AddPlaceScreenStep1({required this.carnetId});

  @override
  _AddPlaceScreenStep1State createState() => _AddPlaceScreenStep1State();
}

class _AddPlaceScreenStep1State extends State<AddPlaceScreenStep1> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];

  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) return;

    final apiKey = "62cc243a16c642daba0b257791a5eec3"; // Geoapify API Key
    final url = Uri.parse(
        "https://api.geoapify.com/v1/geocode/search?text=$query&apiKey=$apiKey");
        final response = await http.get(url);







    if (response.statusCode == 200) {
      setState(() {
        _searchResults = json.decode(response.body)['features'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFCEFEF),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(height: 50),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for a place...",
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onChanged: searchPlaces,
            ),
            SizedBox(height: 20),

            // 📌 Display Search Results
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  var place = _searchResults[index];
                  return ListTile(
                    title: Text(place['properties']['name'] ?? "Unknown Place",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        place['properties']['formatted'] ?? "Unknown Address"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddPlaceScreenStep2(
                            carnetId: widget.carnetId,
                            placeName:
                                place['properties']['name'] ?? "Unknown Place",
                            placeAddress: place['properties']['formatted'] ??
                                "Unknown Address",
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
