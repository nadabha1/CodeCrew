// review_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:projet_pim/Model/review.dart'; // Dépendance à ajouter

class ReviewWidget extends StatelessWidget {
  final Review review;

  const ReviewWidget({required this.review, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Avis de ${review.userId}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RatingBarIndicator(
            rating: review.rating.toDouble(),
            itemCount: 5,
            itemSize: 20.0,
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 8),
          Text(review.comment),
          const SizedBox(height: 8),
          Text('Publié le: ${review.createdAt.toLocal()}'),
        ],
      ),
    );
  }
}
