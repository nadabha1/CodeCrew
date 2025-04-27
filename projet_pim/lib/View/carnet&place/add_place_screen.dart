import 'package:flutter/material.dart';

class AddPlaceScreen extends StatelessWidget {
  final String carnetId;

  const AddPlaceScreen({super.key, required this.carnetId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter un lieu")),
      body: Center(
        child: Text("Ajout de lieu pour le carnet : $carnetId"),
      ),
    );
  }
}
