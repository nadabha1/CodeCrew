import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  final String baseUrl = 'http://localhost:3000'; // Pour l'émulateur Android
  final http.Client client = http.Client();

  // Récupérer les informations de l'utilisateur avec un token
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

  // Mettre à jour le profil utilisateur
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
      request.fields['bio'] = bio;

      // Ajouter l'image de profil si elle est fournie
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

  // Récupérer la liste de tous les utilisateurs
  Future<List<Map<String, dynamic>>> getAllUsers(String token) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/users/all'), // Assure-toi que cette route correspond à celle de ton backend
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> users = json.decode(response.body);
        return users.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des utilisateurs: $e');
    }
  }
}
