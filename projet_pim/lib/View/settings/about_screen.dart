import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About")),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            "This is an application built using Flutter.\n\nVersion: 1.0.0",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
