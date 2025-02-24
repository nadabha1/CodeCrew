import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class UserService {
  final String baseUrl = 'http://10.0.2.2:3000'; // Pour l'émulateur Android

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
 Future<Map<String, dynamic>> deleteUserProfile(String userId, String token) async {
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
        return {'success': true, 'message': response.body}; // Handle plain text response
      }
    } else {
      return {'error': '⚠️ Error ${response.statusCode}: ${response.body}'};
    }
  } catch (e) {
    print("❌ Exception: $e");
    return {'error': '⚠️ Error deleting profile: $e'};
  }
}

}
