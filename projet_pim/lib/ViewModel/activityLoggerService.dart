import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:projet_pim/ViewModel/api_constants.dart';

class ActivityLoggerService {
  static const String _baseUrl = "${ApiConstants.baseUrl}/analyse/log";

  static Future<void> logAction({
    required String userId,
    required String type,
    required String value,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "userId": userId,
          "type": type,
          "value": value,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Activité enregistrée : [$type] $value");
      } else {
        print("❌ Erreur API: ${response.statusCode}");
      }
    } catch (e) {
      print("🚨 Exception lors de l'envoi de l'action : $e");
    }
  }
}
