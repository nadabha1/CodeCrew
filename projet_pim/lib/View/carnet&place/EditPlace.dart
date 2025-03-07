import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/Providers/carnet_provider.dart';
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
              SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection:
                    Axis.horizontal, // Permet le défilement horizontal
                child: Row(
                  children: [
                    // Afficher les images existantes
                    ..._imageUrls.map((imageUrl) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: Stack(
                          children: [
                            // Afficher l'image
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // Ajouter un bouton de suppression
                            Positioned(
                              top: 45,
                              right: -15,
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white, // Fond blanc pour l'icône
                                  borderRadius: BorderRadius.circular(
                                      30), // Arrondir les coins
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12, // Ombre légère
                                      blurRadius: 4.0,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                                // Réduire l'espace autour de l'icône

                                child: IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Color.fromARGB(
                                        255, 255, 0, 0), // Couleur de l'icône
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    // Gérer la suppression de l'image
                                    setState(() {
                                      _imageUrls.remove(
                                          imageUrl); // Supprimer l'image de la liste
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    // Ajouter un bouton + à la fin des images
                    IconButton(
                      icon: const Icon(Icons.add,
                          size: 30, color: Color(0xFFFE7B32)),
                      onPressed:
                          _pickImage, // Ouvre la galerie pour ajouter une image
                    ),
                  ],
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
