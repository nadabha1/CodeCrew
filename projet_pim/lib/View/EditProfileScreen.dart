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
    super.key,
  });

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
              '/uploads/${uploadedImage['filename']}';
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
              title: const Text('Take a photo'),
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
              title: const Text('Choose from gallery'),
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

  /// ✅ **Send Updated Data to API**
  void _updateProfile() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    debugPrint("🔄 Updating profile...");
    print("🔄 Updating Profile...");
    print("📤 Sending Data:");
    print("   - User ID: ${widget.userId}");
    print("   - Token: ${widget.token}");
    print("   - Name: ${nameController.text}");
    print("   - Job: ${jobController.text}");
    print("   - Bio: ${bioController.text}");
    print("   - Profile Image: $_profileImageUrl");
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
        const SnackBar(
          content: Text("Unable to retrieve location!"),
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
    return "Unknown location";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
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
              decoration: const InputDecoration(labelText: 'Job'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Use my location"),
                Switch(
                  value: _useAutoLocation,
                  onChanged: (value) {
                    setState(() {
                      _useAutoLocation = value;
                      if (value) _getLocation();
                    });
                  },
                  activeColor:
                      const Color(0xFFE8EAF6), // couleur du curseur activé
                  activeTrackColor:
                      const Color(0xFF161055), // couleur de la piste activée
                  inactiveThumbColor: Colors.grey, // curseur désactivé
                  inactiveTrackColor: Colors.black26, // piste désactivée
                ),
              ],
            ),
            Row(
              children: [
                // TextField qui prend le maximum d’espace possible
                Expanded(
                  child: TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: "Location"),
                    readOnly: true,
                  ),
                ),
                const SizedBox(
                    width: 10), // un petit espace entre le champ et le bouton
                // Le bouton pour sélectionner sur la carte
                ElevatedButton.icon(
                  icon: const Icon(Icons.map),
                  label: const Text("Map"),
                  onPressed: _openMapToSelectLocation,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
