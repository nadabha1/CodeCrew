import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';

Future<void> shareEventMessage({
  required String conversationId,
  required String userId,
  required String eventId,
    required String msg,

  required BuildContext context,
}) async {
  final url = Uri.parse('${ApiConstants.baseUrl}/messages');
  
  final body = {
    "type": "shared_event",
    "eventId": eventId,
    "conversationId": conversationId,
    "senderId": userId,
    "content": msg,

  };

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ Événement partagé avec succès"),
        backgroundColor: Colors.green,
      ));
    } else {
      print("Erreur: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Échec du partage de l'événement"),
        backgroundColor: Colors.red,
      ));
    }
  } catch (e) {
    print("Exception: $e");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("❌ Erreur réseau"),
      backgroundColor: Colors.red,
    ));
  }
}
