import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_pim/View/AddPlaceScreenStep2.dart';

class AddPlaceScreenStep1 extends StatefulWidget {
  final String carnetId;

  AddPlaceScreenStep1({required this.carnetId});

  @override
  _AddPlaceScreenStep1State createState() => _AddPlaceScreenStep1State();
}

class _AddPlaceScreenStep1State extends State<AddPlaceScreenStep1> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];

  // ✅ Replace with your actual Geoapify API Key
  final String apiKey = "62cc243a16c642daba0b257791a5eec3"; 

  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) return;

    final url = Uri.parse("https://api.geoapify.com/v1/geocode/search?text=$query&apiKey=$apiKey");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        _searchResults = json.decode(response.body)['features'];
      });
    } else {
      print("API Error: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFCEFEF),
      appBar: AppBar(title: Text('Search for a Place')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for an address...",
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onChanged: searchPlaces, // ✅ API request when typing
            ),
            SizedBox(height: 20),

            // 📌 Results List
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(child: Text("No results found."))
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        var place = _searchResults[index]['properties'];
                        return ListTile(
                          title: Text(place['formatted']), // ✅ Correct field
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddPlaceScreenStep2(
                                  carnetId: widget.carnetId,
                                  placeName: place['formatted'],
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
