import 'package:flutter/material.dart';

class UserPreferences with ChangeNotifier {
  String? gender;
  List<String> favoriteActivities = [];
  List<String> eventPreferences = [];
  String? socialPreference;
  String? preferredEventTime;

  void setGender(String selectedGender) {
    gender = selectedGender;
    notifyListeners();
  }

  void setFavoriteActivities(List<String> activities) {
    favoriteActivities = activities;
    notifyListeners();
  }

  void setEventPreferences(List<String> preferences) {
    eventPreferences = preferences;
    notifyListeners();
  }

  void setSocialPreference(String preference) {
    socialPreference = preference;
    notifyListeners();
  }

  void setPreferredEventTime(String eventTime) {
    preferredEventTime = eventTime;
    notifyListeners();
  }
}
