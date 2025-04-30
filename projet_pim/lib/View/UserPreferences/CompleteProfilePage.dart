import 'package:flutter/material.dart';

class CompleteProfilePage extends StatefulWidget {
  final String userId;
  final String token;

  const CompleteProfilePage(
      {required this.userId, required this.token, Key? key})
      : super(key: key);

  @override
  _CompleteProfilePageState createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  String? selectedGender;
  List<String> selectedActivities = [];
  List<String> selectedEventPreferences = [];
  String? selectedSocialPreference;
  String? selectedPreferredTime;

  void _submitProfile() {
    // 🚀 Submit all the data at once here
    print('Gender: $selectedGender');
    print('Activities: $selectedActivities');
    print('Events: $selectedEventPreferences');
    print('Social: $selectedSocialPreference');
    print('Time: $selectedPreferredTime');

    // TODO: call your API to save the profile
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Your Profile'),
        backgroundColor: const Color.fromRGBO(219, 217, 254, 1),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎯 Gender Selection
            Text('Select Gender',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                ChoiceChip(
                  label: Text('Male'),
                  selected: selectedGender == 'Male',
                  onSelected: (_) => setState(() => selectedGender = 'Male'),
                ),
                SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Female'),
                  selected: selectedGender == 'Female',
                  onSelected: (_) => setState(() => selectedGender = 'Female'),
                ),
              ],
            ),
            SizedBox(height: 20),

            // 🎯 Activity Selection
            Text('Favorite Activities',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: ['Hiking', 'Swimming', 'Reading', 'Traveling']
                  .map((activity) {
                return FilterChip(
                  label: Text(activity),
                  selected: selectedActivities.contains(activity),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        selectedActivities.add(activity);
                      } else {
                        selectedActivities.remove(activity);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 20),

            // 🎯 Event Preference
            Text('Event Preferences',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: ['Music', 'Sports', 'Art', 'Tech'].map((event) {
                return FilterChip(
                  label: Text(event),
                  selected: selectedEventPreferences.contains(event),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        selectedEventPreferences.add(event);
                      } else {
                        selectedEventPreferences.remove(event);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 20),

            // 🎯 Social Interaction Preference
            Text('Social Preference',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Column(
              children:
                  ['Small Groups', 'Large Events', 'One-on-One'].map((social) {
                return RadioListTile<String>(
                  title: Text(social),
                  value: social,
                  groupValue: selectedSocialPreference,
                  onChanged: (value) =>
                      setState(() => selectedSocialPreference = value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),

            // 🎯 Preferred Event Time
            Text('Preferred Event Time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Column(
              children:
                  ['Morning', 'Afternoon', 'Evening', 'Night'].map((time) {
                return RadioListTile<String>(
                  title: Text(time),
                  value: time,
                  groupValue: selectedPreferredTime,
                  onChanged: (value) =>
                      setState(() => selectedPreferredTime = value),
                );
              }).toList(),
            ),
            SizedBox(height: 30),

            // 🎯 Submit Button
            Center(
              child: ElevatedButton(
                onPressed: _submitProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFDBD9FE),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: Text('Save Profile', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
