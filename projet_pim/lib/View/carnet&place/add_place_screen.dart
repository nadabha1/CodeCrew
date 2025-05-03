import 'package:flutter/material.dart';

class AddPlaceScreen extends StatelessWidget {
  final String carnetId;

  const AddPlaceScreen({super.key, required this.carnetId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add a location")),
      body: Center(
        child: Text("Adding location to notebook : $carnetId"),
      ),
    );
  }
}
