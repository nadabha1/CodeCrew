import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:projet_pim/View/select_location_screen.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:provider/provider.dart';
import '../Providers/auth_provider.dart';
import '../Providers/UserPreferences.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController locationController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isVerificationPending = false;
  bool _useAutoLocation = false;

  Timer? _verificationTimer;
  String? latitudeLongitude; // Stocke les coordonnées pour la base
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
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

  void _registerUser(BuildContext context) async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs!",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Les mots de passe ne correspondent pas!",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Si aucune image n’est sélectionnée, utiliser l’image par défaut
    final imageUrlToSend =
        _profileImageUrl ?? '${ApiConstants.baseUrl}/uploads/default_image.png';
    debugPrint(
        "🌐 URL de l'image utilisée pour l'inscription : $imageUrlToSend");

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Affichage d'un SnackBar temporaire pendant le traitement
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Traitement de votre demande..."),
        duration: Duration(seconds: 2),
      ),
    );

    bool success = await authProvider.registerUser(
      nameController.text,
      emailController.text,
      passwordController.text,
      latitudeLongitude!,
      Provider.of<UserPreferences>(context, listen: false),
      imageUrlToSend, // <-- ici on envoie soit l'image choisie soit l'image par défaut
    );

    ScaffoldMessenger.of(context).clearSnackBars();

    if (success) {
      setState(() {
        _isVerificationPending = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Inscription réussie! Veuillez vérifier votre email.",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
      _startVerificationCheck();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("L'inscription a échoué. Veuillez réessayer.",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Démarrer la vérification périodique de l'email toutes les 5 secondes
  void _startVerificationCheck() {
    _verificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _checkVerificationStatus();
    });
  }

  // Vérifier le statut de vérification de l'email
  Future<void> _checkVerificationStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool isVerified =
        await authProvider.checkUserVerification(emailController.text);
    if (isVerified) {
      _verificationTimer?.cancel();
      setState(() {
        _isVerificationPending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email vérifié avec succès! Redirection...",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(context, "/gender-selection");
      });
    }
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    super.dispose();
  }

  // Méthode de décoration pour les champs de saisie
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  // Décoration spécifique pour les champs mot de passe avec bouton de visibilité
  InputDecoration _buildPasswordDecoration(
      String label, bool isObscured, VoidCallback toggleVisibility) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      suffixIcon: IconButton(
        icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey),
        onPressed: toggleVisibility,
      ),
    );
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Formes de fond
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                color: Color(0xFFE8EAF6), // Violet clair
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                color: Color(0xFFF8BBD0), // Rose clair
                shape: BoxShape.circle,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),

                const SizedBox(height: 20),

                // Cercle pour l'ajout de la photo de profil
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                        child: _profileImageUrl == null
                            ? const Icon(Icons.person, size: 50, color: Colors.white)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blueAccent,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: _buildInputDecoration("Nom"),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: _buildInputDecoration("Email"),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Utiliser ma localisation automatique"),
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
                  decoration: _buildInputDecoration("Localisation"),
                  readOnly: true,
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.map),
                  label: const Text("Sélectionner sur la carte"),
                  onPressed: _openMapToSelectLocation,
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: passwordController,
                  obscureText: _isPasswordObscured,
                  decoration: _buildPasswordDecoration(
                      "Mot de passe", _isPasswordObscured, () {
                    setState(() {
                      _isPasswordObscured = !_isPasswordObscured;
                    });
                  }),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: _isConfirmPasswordObscured,
                  decoration: _buildPasswordDecoration(
                      "Confirmer le mot de passe", _isConfirmPasswordObscured,
                      () {
                    setState(() {
                      _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                    });
                  }),
                ),

                const SizedBox(height: 40),
                _isVerificationPending
                    ? const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 10),
                            Text(
                              "Veuillez vérifier votre email pour continuer",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () => _registerUser(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF2C2C54), // Bouton bleu marine
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        child: const Center(child: Text("S'inscrire")),
                      ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, "/login"),
                    child: const Text(
                      "Vous avez déjà un compte ? Connectez-vous",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
