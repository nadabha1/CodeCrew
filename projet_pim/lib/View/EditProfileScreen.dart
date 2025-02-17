import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io'; // Pour gérer les fichiers
import 'package:flutter/foundation.dart' as Foundation;

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
  File? _profileImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    jobController = TextEditingController(text: widget.job);
    locationController = TextEditingController(text: widget.location);
    bioController = TextEditingController(text: widget.userData?['bio'] ?? '');
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Sur iOS, on enregistre dans le répertoire des documents de l'application
      final directory = await getApplicationDocumentsDirectory();
      final newPath = '${directory.path}/${pickedFile.name}';

      final newImage = await File(pickedFile.path).copy(newPath);

      setState(() {
        _profileImage = newImage;
      });

      print("Image enregistrée à : ${_profileImage!.path}");
    }
  }

  Future<void> _updateProfile() async {
    if (nameController.text.isEmpty ||
        jobController.text.isEmpty ||
        locationController.text.isEmpty ||
        bioController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Logique pour mettre à jour le profil (inclut l'upload de l'image)
      // Appel API avec les nouvelles données et l'image.
      // Remplace cette partie par ton appel à ton service backend.
      print("Profil mis à jour avec image : ${_profileImage?.path}");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès!')),
      );
      Navigator.pop(context, {
        'name': nameController.text,
        'job': jobController.text,
        'location': locationController.text,
        'bio': bioController.text,
        'profileImage': _profileImage?.path ?? widget.currentProfilePicture,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
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
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!) as ImageProvider
                    : (widget.currentProfilePicture != null &&
                            widget.currentProfilePicture!.isNotEmpty
                        ? NetworkImage(widget.currentProfilePicture!)
                        : const AssetImage('assets/default_profile.png')
                            as ImageProvider),
                child: _profileImage == null
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
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Localisation'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
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
