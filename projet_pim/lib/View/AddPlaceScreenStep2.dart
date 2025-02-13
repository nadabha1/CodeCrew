import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/carnet_provider.dart';

class AddPlaceScreenStep2 extends StatefulWidget {
  final String carnetId;
  final String placeName;

  AddPlaceScreenStep2({required this.carnetId, required this.placeName});

  @override
  _AddPlaceScreenStep2State createState() => _AddPlaceScreenStep2State();
}

class _AddPlaceScreenStep2State extends State<AddPlaceScreenStep2> {
  final TextEditingController _descriptionController = TextEditingController();
  int _cost = 5; // Default cost in Coins
  List<String> _selectedCategories = [];
  List<String> _images = []; // Store image URLs

  // 🎨 Define Categories with Icons
  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.restaurant, 'name': 'Food'},
    {'icon': Icons.shopping_bag, 'name': 'Shopping'},
    {'icon': Icons.park, 'name': 'Nature'},
    {'icon': Icons.museum, 'name': 'Culture'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFCEFEF), // Light pastel background
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40),

            // 📌 Display Selected Place Name (Styled)
            Text(
              "Adding place: ${widget.placeName}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 15),

            // 📌 Categories Section (with Icons)
            Text(
              "Categories of the address",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // 🏷 Categories Selection with Icons
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: categories.map((category) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedCategories.contains(category['name'])) {
                        _selectedCategories.remove(category['name']);
                      } else {
                        _selectedCategories.add(category['name']);
                      }
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _selectedCategories.contains(category['name'])
                          ? Colors.purple[200]
                          : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(category['icon'], size: 30, color: Colors.purple),
                        SizedBox(height: 5),
                        Text(category['name']),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20),

            // 📝 Description Input
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: "Enter a description...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                fillColor: Colors.white,
                filled: true,
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),

            // 💰 Unlock Cost Slider
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
                _buildImagePicker(),
                SizedBox(width: 10),
                _buildImagePicker(),
                SizedBox(width: 10),
                _buildImagePicker(),
              ],
            ),
            SizedBox(height: 20),

            // 🔙 Previous Button | ✅ Finish Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text("Previous", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
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
                  child: Text("Finish", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 📷 Image Picker Placeholder (Modify to use actual image picker)
  Widget _buildImagePicker() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(Icons.add_a_photo, size: 30, color: Colors.grey),
    );
  }
}
