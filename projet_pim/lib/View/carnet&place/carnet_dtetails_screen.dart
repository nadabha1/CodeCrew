import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/carnet_provider.dart';

class CreateCarnetScreen extends StatelessWidget {
  final String userId;
  final TextEditingController _titleController = TextEditingController();

  CreateCarnetScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final carnetProvider = Provider.of<CarnetProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Create a notebook")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Notebook title"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await carnetProvider.createCarnet(
                    userId, _titleController.text);
                Navigator.pop(context); // ✅ Return to home after creation
              },
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }
}
