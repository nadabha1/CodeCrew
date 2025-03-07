import 'package:http/http.dart' as http;
import 'dart:convert';

class FollowService {
  final String baseUrl = 'http://localhost:3000/follow';

  // Suivre un utilisateur
  Future<void> followUser(String targetUserId, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$targetUserId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Échec du suivi');
    }
  }

  // Se désabonner d'un utilisateur
  Future<void> unfollowUser(String targetUserId, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$targetUserId/unfollow'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Échec du désabonnement');
    }
  }

  // 🔹 Get followers
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/followers/$userId'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load followers');
    }
  }

  // 🔹 Get following users
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/following/$userId'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load following');
    }
  }
}
