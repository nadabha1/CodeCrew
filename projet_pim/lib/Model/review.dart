class Review {
  final String placeId;
  final String userId;
  final int rating;
  final String comment;
  final DateTime createdAt; // Change to DateTime

  Review({
    required this.placeId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  // Modify fromJson to handle the response format
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      placeId: json['placeId'],
      userId: json['userId']['_id'], // Access the nested _id from userId object
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(
          json['createdAt']), // Parse the createdAt string to DateTime
    );
  }

  // Modify toJson if necessary
  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt
          .toIso8601String(), // Convert DateTime to string when sending data
    };
  }
}
