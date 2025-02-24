import 'package:flutter/material.dart';

class AddPlaceScreen extends StatelessWidget {
  final String carnetId;

  AddPlaceScreen({required this.carnetId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ajouter un lieu")),
      body: Center(
        child: Text("Ajout de lieu pour le carnet : $carnetId"),
      ),
    );
  }
}
