import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:projet_pim/View/main_screen.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:provider/provider.dart';
import '../../Providers/carnet_provider.dart';

class AddPlaceScreenStep2 extends StatefulWidget {
  final String carnetId;
  final String placeName;
  final String placeAddress;
  final double latitude;
  final double longitude;

  const AddPlaceScreenStep2({super.key, 
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
  final TextEditingController _placeNameController = TextEditingController();
  final int _cost = 5;
  final List<String> _selectedCategories = [];
  final List<String> _imageUrls = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _placeNameController.text = widget.placeName;
  }

  Future<void> _uploadImage(XFile image) async {
    try {
      var uri = Uri.parse('${ApiConstants.baseUrl}/upload');
      var request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('photo', image.path));

      var response = await request.send();
      if (response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        final uploadedImage = jsonDecode(responseBody);
        if (uploadedImage != null && uploadedImage['filename'] != null) {
          final fullImageUrl =
              '${ApiConstants.baseUrl}/uploads/${uploadedImage['filename']}';
          setState(() {
            _imageUrls.add(fullImageUrl);
          });
        }
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  await _uploadImage(pickedFile);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  await _uploadImage(pickedFile);
                }
              },
            ),
          ],
        ),
      ),
    );
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
      backgroundColor: const Color(0xFFFDF5E6),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40), // ✅ Ajouter un espace au-dessus du nom
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _placeNameController,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter place name...",
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    onPressed: () {},
                  ),
                ],
              ),
              Text(
                widget.placeAddress,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              const Text(
                "Categories of the address",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
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
              const SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: "Saisir",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  fillColor: Colors.white,
                  filled: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              const Text(
                "Photos de l'adresse",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 90, // Ajuste la hauteur pour contenir les images
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._imageUrls.map((imageUrl) {
                        return Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _imageUrls.remove(imageUrl);
                                    });
                                  },
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red,
                                    child: Icon(Icons.close,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      GestureDetector(
                        onTap: _pickImage,
                        child: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          radius: 30,
                          child: Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final carnetProvider =
                      Provider.of<CarnetProvider>(context, listen: false);
                  await carnetProvider.addPlaceToCarnet(
                    widget.carnetId,
                    _placeNameController.text,
                    _descriptionController.text,
                    _selectedCategories,
                    _cost,
                    _imageUrls,
                    widget.latitude,
                    widget.longitude,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Valider", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
