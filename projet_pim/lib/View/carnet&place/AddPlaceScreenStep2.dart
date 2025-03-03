import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../Providers/carnet_provider.dart';

class AddPlaceScreenStep2 extends StatefulWidget {
  final String carnetId;
  final String placeName;
  final String placeAddress;
  final double latitude;
  final double longitude;

  AddPlaceScreenStep2({
    required this.carnetId,
    required this.placeName,
    required this.placeAddress,
    required this.latitude,
    required this.longitude,
  });

  @override
  _AddPlaceScreenStep2State createState() => _AddPlaceScreenStep2State();
}

class _AddPlaceScreenStep2State extends State<AddPlaceScreenStep2> {
  final TextEditingController _descriptionController = TextEditingController();
  int _cost = 5;
  List<String> _selectedCategories = [];
  List<String> _imageUrls =
      []; // Liste pour stocker les URLs des images téléchargées

  final ImagePicker _picker = ImagePicker();
  List<XFile>? _imageFileList = [];
  File? _selectedImage;

  // Méthode pour sélectionner des images
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      // Upload the image after picking it
      final carnetProvider =
          Provider.of<CarnetProvider>(context, listen: false);
      String? imageUrl = await carnetProvider.uploadImage(pickedFile);
      if (imageUrl != null) {
        setState(() {
          _imageUrls.add(imageUrl); // Add URL to list
        });
      }
    }
  }

  // Méthode pour uploader une image
  Future<void> _uploadImage(XFile image) async {
    try {
      var uri = Uri.parse('http://localhost:3000/upload'); // URL de ton serveur

      var request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('photo', image.path));

      var response = await request.send();

      if (response.statusCode == 201) {
        // HTTP 201 Created
        final responseBody = await response.stream.bytesToString();
        final uploadedImage = jsonDecode(responseBody);

        // Vérifie si l'URL est bien présente dans la réponse
        if (uploadedImage != null &&
            uploadedImage['response'] != null &&
            uploadedImage['response']['url'] is String &&
            uploadedImage['response']['url'].isNotEmpty) {
          setState(() {
            _imageUrls
                .add(uploadedImage['response']['url']); // Utilisation de l'URL
            _imageFileList?.add(
                image); // Optionnellement, ajouter l'image à la liste des fichiers
          });

          print(
              'Image uploaded successfully: ${uploadedImage['response']['url']}');
        } else {
          print('Error: URL is null, empty, or invalid');
        }
      } else {
        print('Failed to upload image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.restaurant, 'name': 'Food', 'color': Colors.red},
    {'icon': Icons.shopping_bag, 'name': 'Shopping', 'color': Colors.blue},
    {'icon': Icons.park, 'name': 'Nature', 'color': Colors.green},
    {'icon': Icons.museum, 'name': 'Culture', 'color': Colors.orange},
    {'icon': Icons.fitness_center, 'name': 'Sports', 'color': Colors.purple},
    {'icon': Icons.local_bar, 'name': 'Nightlife', 'color': Colors.pink},
    {'icon': Icons.hotel, 'name': 'Hotels', 'color': Colors.indigo},
    {'icon': Icons.directions_bus, 'name': 'Transport', 'color': Colors.brown},
    {
      'icon': Icons.theater_comedy,
      'name': 'Entertainment',
      'color': Colors.teal
    },
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
            Text(
              widget.placeName,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple),
            ),
            Text(
              widget.placeAddress,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 20),
            Text(
              "Categories of the address",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              height: 80,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((category) {
                    bool isSelected =
                        _selectedCategories.contains(category['name']);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: ChoiceChip(
                        avatar: Icon(category['icon'],
                            color:
                                isSelected ? Colors.white : category['color'],
                            size: 20),
                        label: Text(category['name']),
                        selected: isSelected,
                        selectedColor: category['color'],
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black),
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
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: "Enter a description...",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                fillColor: Colors.white,
                filled: true,
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),
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
            Text("Add photos",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              children: [
                ..._imageFileList!.map((image) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: FileImage(File(image.path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Icon(Icons.add, size: 30, color: Colors.grey),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child:
                      Text("Previous", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final carnetProvider =
                        Provider.of<CarnetProvider>(context, listen: false);
                    await carnetProvider.addPlaceToCarnet(
                      widget.carnetId,
                      widget.placeName,
                      _descriptionController.text,
                      _selectedCategories,
                      _cost,
                      _imageUrls, // Use URLs directly
                      widget.latitude,
                      widget.longitude,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
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
