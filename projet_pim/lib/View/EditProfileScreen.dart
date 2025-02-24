import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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
  File? _profileImage;

  final ImagePicker _picker = ImagePicker();
  final UserService userService = UserService(); // ✅ UserService Instance

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
      final directory = await getApplicationDocumentsDirectory();
      final newPath = '${directory.path}/${pickedFile.name}';
      final newImage = await File(pickedFile.path).copy(newPath);

      setState(() {
        _profileImage = newImage;
      });

      print("Image enregistrée à : ${_profileImage!.path}");
    }
  }

  /// ✅ **Send Updated Data to API**
  void _updateProfile() async {
    setState(() => isLoading = true);

    print("🔄 Updating Profile...");
    print("📤 Sending Data:");
    print("   - User ID: ${widget.userId}");
    print("   - Token: ${widget.token}");
    print("   - Name: ${nameController.text}");
    print("   - Job: ${jobController.text}");
    print("   - Location: ${locationController.text}");
    print("   - Bio: ${bioController.text}");
    print("   - Profile Image: ${_profileImage?.path ?? 'No Image Selected'}");

    final result = await userService.updateUserProfile(
      widget.userId,
      widget.token,
      nameController.text,
      jobController.text,
      locationController.text,
      bioController.text,
      //_profileImage?.path ?? '', // Pass image path or empty string
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
        'profileImage': _profileImage?.path ?? widget.currentProfilePicture,
      });
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
                        : const AssetImage('assets/default_avatar.png')
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
