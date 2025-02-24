import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/auth_provider.dart';
import '../Providers/UserPreferences.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController     = TextEditingController();
  final TextEditingController emailController    = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _isPasswordObscured         = true;
  bool _isConfirmPasswordObscured  = true;
  bool _isVerificationPending      = false;
  Timer? _verificationTimer;

  void _registerUser(BuildContext context) async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Veuillez remplir tous les champs!", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Les mots de passe ne correspondent pas!", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Affichage d'un SnackBar temporaire pendant le traitement
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Traitement de votre demande..."),
        duration: Duration(seconds: 2),
      ),
    );

    bool success = await authProvider.registerUser(
      nameController.text,
      emailController.text,
      passwordController.text,
      Provider.of<UserPreferences>(context, listen: false),
    );

    ScaffoldMessenger.of(context).clearSnackBars();

    if (success) {
      setState(() {
        _isVerificationPending = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Inscription réussie! Veuillez vérifier votre email.", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
      _startVerificationCheck();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("L'inscription a échoué. Veuillez réessayer.", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Démarrer la vérification périodique de l'email toutes les 5 secondes
  void _startVerificationCheck() {
    _verificationTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      await _checkVerificationStatus();
    });
  }

  // Vérifier le statut de vérification de l'email
  Future<void> _checkVerificationStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool isVerified = await authProvider.checkUserVerification(emailController.text);
    if (isVerified) {
      _verificationTimer?.cancel();
      setState(() {
        _isVerificationPending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Email vérifié avec succès!", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
      Future.delayed(Duration(seconds: 1), () {
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
      labelStyle: TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  // Décoration spécifique pour les champs mot de passe avec bouton de visibilité
  InputDecoration _buildPasswordDecoration(String label, bool isObscured, VoidCallback toggleVisibility) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      suffixIcon: IconButton(
        icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
        onPressed: toggleVisibility,
      ),
    );
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
              decoration: BoxDecoration(
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
              decoration: BoxDecoration(
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
                SizedBox(height: 80),
                Text(
                  "Créer\nCompte",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 40),
                TextField(
                  controller: nameController,
                  decoration: _buildInputDecoration("Nom"),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: _buildInputDecoration("Email"),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: _isPasswordObscured,
                  decoration: _buildPasswordDecoration("Mot de passe", _isPasswordObscured, () {
                    setState(() {
                      _isPasswordObscured = !_isPasswordObscured;
                    });
                  }),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: _isConfirmPasswordObscured,
                  decoration: _buildPasswordDecoration("Confirmer le mot de passe", _isConfirmPasswordObscured, () {
                    setState(() {
                      _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                    });
                  }),
                ),
                SizedBox(height: 40),
                _isVerificationPending
                    ? Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 10),
                            Text(
                              "Veuillez vérifier votre email pour continuer",
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () => _registerUser(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2C2C54), // Bouton bleu marine
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        child: Center(child: Text("S'inscrire")),
                      ),
                SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, "/login"),
                    child: Text(
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
