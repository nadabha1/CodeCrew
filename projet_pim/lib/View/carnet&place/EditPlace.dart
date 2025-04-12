import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/Providers/carnet_provider.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart'; // Import FlutterMap package
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart'; // Import LatLng

class EditPlace extends StatefulWidget {
  final Place place;

  const EditPlace({Key? key, required this.place}) : super(key: key);

  @override
  _EditPlaceState createState() => _EditPlaceState();
}

class _EditPlaceState extends State<EditPlace> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _carnetId;
  late List<String> _selectedCategories; // Liste des catégories sélectionnées

  List<String> _imageUrls =
      []; // Liste pour stocker les URLs des images téléchargées

  final ImagePicker _picker = ImagePicker();
  List<XFile>? _imageFileList = [];
  File? _selectedImage;

  // Méthode pour sélectionner des images
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Prendre une photo'),
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
              leading: Icon(Icons.photo_library),
              title: Text('Choisir depuis la galerie'),
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

  // Méthode pour uploader une image
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

  // Définir les catégories disponibles
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
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.place.name);
    _descriptionController =
        TextEditingController(text: widget.place.description);

    // Initialiser les catégories déjà sélectionnées à partir de widget.place.categories
    _selectedCategories = List.from(widget.place.categories);

    _imageUrls = List.from(widget.place.images);

    _fetchCarnetId();
  }

  Future<void> _fetchCarnetId() async {
    final carnetId = await Provider.of<CarnetProvider>(context, listen: false)
        .getCarnetIdByPlaceId(widget.place.id);

    setState(() {
      _carnetId = carnetId;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      // Créer un nouvel objet Place mis à jour
      Place updatedPlace = widget.place.copyWith(
        name: _nameController.text,
        description: _descriptionController.text,
        images: _imageUrls, // Mettre à jour les images
        categories: _selectedCategories,
      );

      // Mettez à jour la place dans votre provider
      final carnetProvider =
          Provider.of<CarnetProvider>(context, listen: false);
      carnetProvider.updatePlace(updatedPlace, _carnetId);

      // Fermer la page une fois les modifications enregistrées
      Navigator.pop(context, updatedPlace); // Passer la place mise à jour
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier le lieu"),
        backgroundColor: const Color(0xFFDBD9FE),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Categories ",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
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
                          avatar: Icon(
                            category['icon'],
                            color:
                                isSelected ? Colors.white : category['color'],
                            size: 20,
                          ),
                          label: Text(category['name']),
                          selected: isSelected,
                          selectedColor: category['color'],
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nom"),
                validator: (value) =>
                    value!.isEmpty ? "Veuillez entrer un nom" : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                validator: (value) =>
                    value!.isEmpty ? "Veuillez entrer une description" : null,
              ),
              const SizedBox(height: 8),

              // Ajout de FlutterMap pour afficher la localisation
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: FlutterMap(
                  options: MapOptions(
                    center: LatLng(widget.place.latitude ?? 0.0,
                        widget.place.longitude ?? 0.0),
                    zoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(widget.place.latitude ?? 0.0,
                              widget.place.longitude ?? 0.0),
                          width: 40.0,
                          height: 40.0,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const SizedBox(height: 8),

              // Affichage des images
              const SizedBox(height: 8),
              Text(
                "Images enregistrées",
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
                                  child: CircleAvatar(
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
                      }).toList(),
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          backgroundColor: Colors.orange,
                          radius: 30,
                          child: Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const SizedBox(height: 8),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFE7B32)),
                child: const Text("Enregistrer"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
