import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/carnet_provider.dart';

class AddPlaceScreenStep2 extends StatefulWidget {
  final String carnetId;
  final String placeName;
  final String placeAddress;

  AddPlaceScreenStep2({
    required this.carnetId,
    required this.placeName,
    required this.placeAddress,
  });

  @override
  _AddPlaceScreenStep2State createState() => _AddPlaceScreenStep2State();
}

class _AddPlaceScreenStep2State extends State<AddPlaceScreenStep2> {
  final TextEditingController _descriptionController = TextEditingController();
  int _cost = 5;
  List<String> _selectedCategories = [];
  List<String> _images = []; 

  // Categories with Icons & Custom Colors
  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.restaurant, 'name': 'Food', 'color': Colors.red},
    {'icon': Icons.shopping_bag, 'name': 'Shopping', 'color': Colors.blue},
    {'icon': Icons.park, 'name': 'Nature', 'color': Colors.green},
    {'icon': Icons.museum, 'name': 'Culture', 'color': Colors.orange},
    {'icon': Icons.fitness_center, 'name': 'Sports', 'color': Colors.purple},
    {'icon': Icons.local_bar, 'name': 'Nightlife', 'color': Colors.pink},
    {'icon': Icons.hotel, 'name': 'Hotels', 'color': Colors.indigo},
    {'icon': Icons.directions_bus, 'name': 'Transport', 'color': Colors.brown},
    {'icon': Icons.theater_comedy, 'name': 'Entertainment', 'color': Colors.teal},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFCEFEF),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40),

            // 📌 Display Selected Place
            Text(
              widget.placeName,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
            ),
            Text(
              widget.placeAddress,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 20),

            // 📌 Categories Section
            Text(
              "Categories of the address",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // 🏷 Scrollable Categories Selection with Icons & Custom Colors
            Container(
              height: 80, // Increased height for better spacing
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((category) {
                    bool isSelected = _selectedCategories.contains(category['name']);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: ChoiceChip(
                        avatar: Icon(category['icon'], 
                          color: isSelected ? Colors.white : category['color'], 
                          size: 20),
                        label: Text(category['name']),
                        selected: isSelected,
                        selectedColor: category['color'], // Custom category color
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category['name']);
                            } else {
                              _selectedCategories.remove(category['name']);
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            SizedBox(height: 20),

            // 📝 Description Input
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: "Enter a description...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                fillColor: Colors.white,
                filled: true,
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),

            // 💰 Unlock Cost
            Text(
              "Price to unlock: $_cost Coins",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _cost.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: Colors.purple[400],
              label: "$_cost Coins",
              onChanged: (value) {
                setState(() {
                  _cost = value.toInt();
                });
              },
            ),
            SizedBox(height: 20),

            // 📷 Image Upload Section
            Text("Add photos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Icon(Icons.add, size: 30, color: Colors.grey),
                ),
                SizedBox(width: 10),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // 🔙 Previous Button | ✅ Finish Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text("Previous", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final carnetProvider = Provider.of<CarnetProvider>(context, listen: false);
                    await carnetProvider.addPlaceToCarnet(
                      widget.carnetId,
                      widget.placeName,
                      _descriptionController.text,
                      _selectedCategories,
                      _cost,
                      _images,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text("Finish", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
