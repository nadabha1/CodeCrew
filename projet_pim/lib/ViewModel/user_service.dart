import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final String baseUrl = 'http://localhost:3000'; // Pour l'émulateur Android

  final http.Client client = http.Client();

  Future<Map<String, dynamic>> getUserById(String userId, String token) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'error': 'Erreur ${response.statusCode}: ${response.body}'};
      }
    } catch (e) {
      return {'error': 'Erreur lors de la récupération de l’utilisateur: $e'};
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(
    String userId,
    String token,
    String name,
    String job,
    String location,
    String bio,
    String profileImage,
  ) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/users/$userId/update'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['name'] = name;
      request.fields['job'] = job;
      request.fields['location'] = location;

      if (profileImage.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('profileImage', profileImage),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return {'success': true, 'message': jsonDecode(response.body)};
      } else {
        return {'error': 'Erreur ${response.statusCode}: ${response.body}'};
      }
    } catch (e) {
      return {'error': 'Erreur lors de la mise à jour du profil: $e'};
    }
  }
}
