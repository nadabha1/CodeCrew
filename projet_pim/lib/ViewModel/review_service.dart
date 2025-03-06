import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:projet_pim/Model/review.dart';

class ReviewService {
  final String baseUrl = 'http://192.168.1.6:3000';

  // Get all reviews for a place
  Future<List<Review>> getAllReviews(String placeId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reviews/$placeId'));

      if (response.statusCode == 200) {
        // Decode the response body as a List of dynamic objects
        List<dynamic> data = jsonDecode(response.body);

        // Convert the List<dynamic> to a List<Review> using map
        return data.map((item) => Review.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load reviews: ${response.body}');
      }
    } catch (e) {
      print("Error in getAllReviews: $e");
      throw Exception('Network error: Unable to fetch reviews.');
    }
  }

  // Add a new review for a place
  Future<void> addReview(String placeId, Review review) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews/$placeId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(review.toJson()),
      );

      if (response.statusCode == 201) {
        print("Review added successfully.");
      } else {
        throw Exception(
            'Failed to add review: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Error in addReview: $e");
      throw Exception('Network error: Unable to add review.');
    }
  }
}
