import 'package:flutter/material.dart';
import 'package:projet_pim/Model/review.dart';
import 'package:projet_pim/ViewModel/review_service.dart';

class ReviewProvider with ChangeNotifier {
  final ReviewService _reviewService = ReviewService();

  List<Review> _reviews = [];
  List<Review> get reviews => _reviews;

  // Track loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Fetch reviews for a place
  Future<void> fetchReviews(String placeId) async {
    if (_isLoading) return; // Avoid fetching while already loading

    try {
      _isLoading = true;
      notifyListeners(); // Notify listeners that loading state has changed

      final reviews = await _reviewService.getAllReviews(placeId);
      _reviews = reviews;
    } catch (e) {
      print("Error fetching reviews: $e");
      // Handle error here (e.g., show message to user)
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify listeners that loading has finished
    }
  }

  // Add a review for a place
  Future<void> addReview(String placeId, Review review) async {
    try {
      await _reviewService.addReview(placeId, review);
      await fetchReviews(placeId);
    } catch (e) {
      print("Error in addReview: $e");
      // Relance l’erreur pour qu’elle soit captée dans le `onSubmit`
      rethrow;
    }
  }

  Future<void> editReview(String placeId, Review review) async {
    try {
      await _reviewService.editReview(placeId, review);
      await fetchReviews(placeId); // Refresh list
      notifyListeners();
    } catch (e) {
      print("Error editing review: $e");
      throw e; // Pour capter l'erreur dans l'UI
    }
  }
}
