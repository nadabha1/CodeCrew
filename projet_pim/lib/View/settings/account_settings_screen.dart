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
        title: Text("Account Settings"),
        backgroundColor:  const Color.fromRGBO(219, 217, 254, 1),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.description,
            title: "Terms and Conditions",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TermsConditionsScreen()),
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip,
            title: "Privacy Policy",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()),
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: "Help",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HelpScreen()),
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: "About",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AboutScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios, size: 18),
      onTap: onTap,
    );
  }
}
