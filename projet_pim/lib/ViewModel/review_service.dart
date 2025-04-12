import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:projet_pim/Model/review.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';

class ReviewService {
  // Get all reviews for a place
  Future<List<Review>> getAllReviews(String placeId) async {
    final url = '${ApiConstants.baseUrl}/reviews/$placeId';
    print("Fetching reviews from $url");

    try {
      final response = await http.get(Uri.parse(url));

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
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
  Future<bool> addReview(String placeId, Review review) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/reviews/$placeId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(review.toJson()),
      );

      if (response.statusCode == 201) {
        print("Review added successfully.");
        // Call to refresh the reviews after a successful submission
        await getAllReviews(placeId);
        return true; // Return true if successful
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Unknown error');
      }
    } catch (e) {
      print("Error in addReview: $e");
      throw e; // Rethrow to show an error in the UI
    }
  }

  // Update a review
  Future<bool> editReview(String placeId, Review review) async {
    final url = '${ApiConstants.baseUrl}/reviews/$placeId';

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(review.toJson()),
      );

      print("PUT $url → ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        await getAllReviews(placeId);
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update review');
      }
    } catch (e) {
      print("Error in editReview: $e");
      throw Exception("Error editing review: $e");
    }
  }
}
