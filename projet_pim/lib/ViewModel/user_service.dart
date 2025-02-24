import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  String? _userId;
  String? _token;


  //final String baseUrl = 'http://localhost:3000'; // Pour l'émulateur Android
final String baseUrl =
      "http://10.0.2.2:3000"; 
  final http.Client client = http.Client();
  Future<List<dynamic>> getAllUsers(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId/others'));

    if (response.statusCode == 200|| response.statusCode==201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load users');
    }
  }
Future<Map<String, dynamic>> getUserById(String userId, String token) async {
  try {
    if (token.isEmpty) throw Exception("Token is empty");

    print("🔹 Fetching user with token: $token"); // Debugging

    final response = await client.get(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      print("❌ Unauthorized: Invalid or expired token");
      throw Exception("Unauthorized: Invalid token");
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
      body: jsonEncode({
        "follower": loggedInUserId,
        "following": travelerId
      }),
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
    final response = await http.get(Uri.parse('$baseUrl/follow/followers/$userId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['followers']);
    } else {
      throw Exception("Failed to fetch followers");
    }
  }

  // ✅ Get Following List
  Future<List<String>> getFollowing(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/follow/following/$userId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['following']);
    } else {
      throw Exception("Failed to fetch following");
    }
  }

  // ✅ Get Followers Count
  Future<int> getFollowersCount(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/follow/followers/count/$userId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['followersCount'];
    } else {
      throw Exception("Failed to fetch followers count");
    }
  }

  // ✅ Get Following Count
  Future<int> getFollowingCount(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/follow/following/count/$userId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['followingCount'];
    } else {
      throw Exception("Failed to fetch following count");
    }
  }
}
