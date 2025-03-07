import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_pim/Model/conversation.dart';

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

  Future<void> followUser(String loggedInUserId, String travelerId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/follow'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"follower": loggedInUserId, "following": travelerId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ Follow successful");
    } else if (response.statusCode == 409) {
      print("⚠️ Already following this user.");
    } else {
      print("❌ Follow failed: ${response.body}");
      throw Exception("Failed to follow user");
    }
  }

  Future<void> unfollowUser(String loggedInUserId, String travelerId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/follow'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"follower": loggedInUserId, "following": travelerId}),
    );

    if (response.statusCode == 200) {
      print("✅ Unfollow successful");
    } else {
      print("❌ Unfollow failed: ${response.body}");
      throw Exception("Failed to unfollow user");
    }
  }

  // ✅ Get Followers List
  Future<List<String>> getFollowers(String userId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/follow/followers/$userId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['followers']);
    } else {
      throw Exception("Failed to fetch followers");
    }
  }

  // ✅ Get Following List
  Future<List<String>> getFollowing(String userId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/follow/following/$userId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['following']);
    } else {
      throw Exception("Failed to fetch following");
    }
  }

  // ✅ Get Followers Count
  Future<int> getFollowersCount(String userId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/follow/followers/count/$userId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['followersCount'];
    } else {
      throw Exception("Failed to fetch followers count");
    }
  }

  // ✅ Get Following Count
  Future<int> getFollowingCount(String userId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/follow/following/count/$userId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['followingCount'];
    } else {
      throw Exception("Failed to fetch following count");
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(
    String userId,
    String token,
    String name,
    String job,
    String location,
    String bio,
  ) async {
    try {
      print("🔄 Preparing Profile Update Request...");

      var response = await http.put(
        Uri.parse('$baseUrl/users/$userId/update'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'job': job,
          'location': location,
          'bio': bio,
        }),
      );

      // ✅ Debug API Response
      print("📬 Response Status: ${response.statusCode}");
      print("📬 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': '⚠️ Error ${response.statusCode}: ${response.body}'};
      }
    } catch (e) {
      print("❌ Exception: $e");
      return {'error': '⚠️ Error updating profile: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteUserProfile(
      String userId, String token) async {
    try {
      print("🗑 Deleting User Profile: $userId");

      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("📬 Response Status: ${response.statusCode}");
      print("📬 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // ✅ Check if response body is plain text
        try {
          return jsonDecode(response.body);
        } catch (_) {
          return {
            'success': true,
            'message': response.body
          }; // Handle plain text response
        }
      } else {
        return {'error': '⚠️ Error ${response.statusCode}: ${response.body}'};
      }
    } catch (e) {
      print("❌ Exception: $e");
      return {'error': '⚠️ Error deleting profile: $e'};
    }
  }

  Future<List<String>> getUserFavorites(String userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/favorites'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("API Response: $data"); // Debugging the response

        // Directly return the 'favorites' list as a List<String>
        return List<String>.from(data);
      } else {
        throw Exception("Failed to fetch favorites: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching favorites: $e");
      throw Exception("Error fetching favorites: $e");
    }
  }

  // ✅ Add a Place to Favorites
  Future<void> addPlaceToFavorites(
      String userId, String placeId, String token) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/users/$userId/favorites/$placeId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'placeId': placeId}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Place added to favorites successfully!");
      } else {
        throw Exception("Failed to add place to favorites");
      }
    } catch (e) {
      throw Exception("Error adding place to favorites: $e");
    }
  }

  Future<Map<String, dynamic>> getPlaceById(
      String placeId, String token) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/carnets/place/$placeId'), // Updated endpoint
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        print('❌ Place not found: ${response.body}');
        throw Exception('Place not found: ${response.body}');
      } else {
        print('❌ Failed to fetch place details: ${response.body}');
        throw Exception('Failed to fetch place details: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching place details: $e');
      throw Exception('Error fetching place details: $e');
    }
  }

  static final String baseUrl2 = 'http://10.0.2.2:3000';

  static Future<List<Conversation>> getUserConversations(String userId) async {
    final response =
        await http.get(Uri.parse('$baseUrl2/conversations/$userId'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Conversation.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors du chargement des conversations');
    }
  }

  void startConversation(BuildContext context, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/conversations'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"participantId": userId}),
    );

    if (response.statusCode == 201) {
      // Fermer l'écran et retourner la conversation créée
      Navigator.pop(context, json.decode(response.body));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Erreur lors de la création de la conversation")),
      );
    }
  }
}
