import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/carnet_provider.dart';

class CreateCarnetScreen extends StatelessWidget {
  final String userId;
  final TextEditingController _titleController = TextEditingController();

  CreateCarnetScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    final carnetProvider = Provider.of<CarnetProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Créer un carnet")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "Titre du carnet"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await carnetProvider.createCarnet(userId, _titleController.text);
                Navigator.pop(context); // ✅ Return to home after creation
              },
              child: Text("Créer"),
            ),
          ],
        ),
      ),
    );
  }
}
