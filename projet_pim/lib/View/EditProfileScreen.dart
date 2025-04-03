import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:projet_pim/View/select_location_screen.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'dart:io';
import 'package:projet_pim/ViewModel/user_service.dart'; // Import the UserService
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  final String token;
  final Map<String, dynamic>? userData;
  final String name;
  final String job;
  final String location;
  final String? currentProfilePicture;

  const EditProfileScreen({
    required this.userId,
    required this.token,
    required this.userData,
    required this.name,
    required this.job,
    required this.location,
    this.currentProfilePicture,
    Key? key,
  }) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController jobController;
  late TextEditingController locationController;
  late TextEditingController bioController;
  bool isLoading = false;
  bool _useAutoLocation = false;
  File? _profileImage;
  String? _profileImageUrl;
  String? latitudeLongitude; // Stocke les coordonnées pour la base

  final ImagePicker _picker = ImagePicker();
  final UserService userService = UserService(); // ✅ UserService Instance

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    jobController = TextEditingController(text: widget.job);
    bioController = TextEditingController(text: widget.userData?['bio'] ?? '');
    locationController = TextEditingController(text: widget.location);
  }

  // Fonction pour télécharger l'image sur le serveur
  Future<void> _uploadImage(XFile image) async {
    try {
      var uri = Uri.parse('${ApiConstants.baseUrl}/upload');
      var request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('photo', image.path));

      debugPrint("📤 Envoi de l'image à : $uri");
      var response = await request.send();

      if (response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        debugPrint("✅ Réponse du serveur : $responseBody");

        final uploadedImage = jsonDecode(responseBody);
        if (uploadedImage != null && uploadedImage['filename'] != null) {
          final fullImageUrl =
              '${ApiConstants.baseUrl}/uploads/${uploadedImage['filename']}';
          setState(() {
            _profileImageUrl = fullImageUrl;
          });
          debugPrint("🌐 URL de l'image mise à jour : $_profileImageUrl");
        } else {
          debugPrint(
              "⚠️ Erreur : La réponse ne contient pas de champ 'filename'.");
        }
      } else {
        debugPrint("❌ Échec de l'upload. Code : ${response.statusCode}");
        final errorResponse = await response.stream.bytesToString();
        debugPrint("❌ Détails de l'erreur : $errorResponse");
      }
    } catch (e) {
      debugPrint("❌ Erreur lors de l'upload de l'image : $e");
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      await _uploadImage(pickedFile);
    }
  }

  /// ✅ **Send Updated Data to API**
  void _updateProfile() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    debugPrint("🔄 Mise à jour du profil...");
    print("🔄 Updating Profile...");
    print("📤 Sending Data:");
    print("   - User ID: ${widget.userId}");
    print("   - Token: ${widget.token}");
    print("   - Name: ${nameController.text}");
    print("   - Job: ${jobController.text}");
    print("   - Bio: ${bioController.text}");
    print("   - Profile Image: ${_profileImageUrl}");
    print("   - Location: $latitudeLongitude"); // ✅ Log coordinates

    final result = await userService.updateUserProfile(
      widget.userId,
      widget.token,
      nameController.text,
      jobController.text,
      bioController.text,
      _profileImageUrl ?? widget.currentProfilePicture,
      latitudeLongitude, // ✅ Include coordinates in the API call
    );

    setState(() => isLoading = false);

    if (result.containsKey('error')) {
      print("❌ Error Updating Profile: ${result['error']}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'])),
      );
    } else {
      print("✅ Profile Updated Successfully!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      // ✅ Optionally navigate back or refresh data
      Navigator.pop(context, {
        'name': nameController.text,
        'job': jobController.text,
        'location': locationController.text,
        'bio': bioController.text,
        'profileImage': _profileImageUrl ?? widget.currentProfilePicture,
        'latitudeLongitude': latitudeLongitude, // ✅ Pass coordinates back
      });
    }
  }

  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String address =
          await getAddressFromLatLng(position.latitude, position.longitude);

      setState(() {
        locationController.text = address; // Affiche le nom du lieu
        latitudeLongitude =
            "${position.latitude},${position.longitude}"; // Stocke les coordonnées
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Impossible de récupérer la localisation!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openMapToSelectLocation() async {
    LatLng? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SelectLocationScreen()),
    );

    if (selectedLocation != null) {
      String address = await getAddressFromLatLng(
          selectedLocation.latitude, selectedLocation.longitude);

      setState(() {
        locationController.text = address; // Affiche l'adresse
        latitudeLongitude =
            "${selectedLocation.latitude},${selectedLocation.longitude}"; // Stocke les coordonnées
      });
    }
  }

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.locality}, ${place.country}"; // Exemple: Paris, France
      }
    } catch (e) {
      print("Erreur de conversion: $e");
    }
    return "Localisation inconnue";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: const Color(0xFFDBD9FE),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!) as ImageProvider
                    : (widget.currentProfilePicture != null &&
                            widget.currentProfilePicture!.isNotEmpty
                        ? NetworkImage(widget.currentProfilePicture!)
                        : const AssetImage('assets/default_avatar.png')
                            as ImageProvider),
                child: _profileImageUrl == null
                    ? const Icon(Icons.camera_alt,
                        size: 40, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: jobController,
              decoration: const InputDecoration(labelText: 'Métier'),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Utiliser ma localisation automatique"),
                Switch(
                  value: _useAutoLocation,
                  onChanged: (value) {
                    setState(() {
                      _useAutoLocation = value;
                      if (value) _getLocation();
                    });
                  },
                ),
              ],
            ),
            TextField(
              controller: locationController,
              decoration: InputDecoration(labelText: "Localisation"),
              readOnly: true,
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.map),
              label: Text("Sélectionner sur la carte"),
              onPressed: _openMapToSelectLocation,
            ),
            SizedBox(height: 20),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isLoading ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFE9332),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
