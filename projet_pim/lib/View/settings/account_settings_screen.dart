import 'package:flutter/material.dart';
import 'terms_conditions_screen.dart';
import 'privacy_policy_screen.dart';
import 'help_screen.dart';
import 'about_screen.dart';

class AccountSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Account Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor:  const Color.fromRGBO(219, 217, 254, 1),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Manage your account",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            _buildSettingsTile(
              context,
              icon: Icons.description,
              title: "Terms and Conditions",
              onTap: () => _navigateTo(context, TermsConditionsScreen()),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.privacy_tip,
              title: "Privacy Policy",
              onTap: () => _navigateTo(context, PrivacyPolicyScreen()),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.help_outline,
              title: "Help",
              onTap: () => _navigateTo(context, HelpScreen()),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.info_outline,
              title: "About",
              onTap: () => _navigateTo(context, AboutScreen()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              spreadRadius: 1,
              offset: Offset(2, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurpleAccent, size: 28),
                const SizedBox(width: 15),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}
