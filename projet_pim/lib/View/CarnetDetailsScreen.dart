import 'package:flutter/material.dart';

class CarnetDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Carnet'),
        backgroundColor: const Color.fromRGBO(219, 217, 254, 1),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Détails du carnet ici...',
              style: TextStyle(fontSize: 18),
            ),
            // Vous pouvez ajouter plus de widgets pour afficher les détails du carnet
          ],
        ),
      ),
    );
  }
}
