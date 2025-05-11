import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Providers/UserPreferences.dart';
import '../../../Providers/auth_provider.dart';

class FinalConfirmationCompletePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final preferences = Provider.of<UserPreferences>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    Future<void> _finish() async {
      await auth.restoreSessionFromPrefs(); // ⬅️ Ensure token/userId loaded

      debugPrint("🧪 [FinalConfirmationPage] User: ${auth.userId}");
      debugPrint("🧪 Submitting preferences for userId: ${auth.userId}");

      final success = await auth.addUserPreferences(preferences);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Your preferences have been saved!")),
        );
        Navigator.pushReplacementNamed(context, "/profile");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Failed to save preferences. Please log in again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Confirmation"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "You're all set!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _finish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 12),
                ),
                child: Text("Finish", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
