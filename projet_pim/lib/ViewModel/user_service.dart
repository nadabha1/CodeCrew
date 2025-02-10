import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  final String baseUrl =
      'http://localhost:3000'; // Remplace avec l'URL de ton API

  Future<Map<String, dynamic>> getUserById(String userId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la récupération des données utilisateur');
    }
  }
}
