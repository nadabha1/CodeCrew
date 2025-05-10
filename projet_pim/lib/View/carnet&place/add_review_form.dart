import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:projet_pim/Model/review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddReviewForm extends StatefulWidget {
  final String placeId; // Add placeId as a parameter
  final Function(Review) onSubmit;

  const AddReviewForm({required this.onSubmit, required this.placeId, super.key});

  @override
  _AddReviewFormState createState() => _AddReviewFormState();
}

class _AddReviewFormState extends State<AddReviewForm> {
  final _commentController = TextEditingController();
  double _rating = 0;
  String? _userId; // User ID from SharedPreferences

  // Function to fetch userId from SharedPreferences
  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId =
          prefs.getString("user_id"); // Get the user ID from SharedPreferences
    });
  }

  @override
  void initState() {
    super.initState();
    _getUserId(); // Fetch userId when the widget is initialized
  }

  void _submitReview() {
    final comment = _commentController.text;
    if (comment.isNotEmpty && _rating > 0 && _userId != null) {
      final newReview = Review(
        userId: _userId!, // Assurez-vous que le userId n'est pas null
        placeId: widget.placeId, // Utilisez le placeId passé depuis le parent
        comment: comment,
        rating: _rating.toInt(),
        createdAt: DateTime.now(),
      );
      widget.onSubmit(newReview); // Passez la nouvelle critique au parent

      // Réinitialiser les champs du formulaire
      _commentController.clear(); // Vide le champ commentaire
      setState(() {
        _rating = 0; // Réinitialise la note à 0
      });

      // Afficher un message de confirmation
    } else {
      // Gérer le cas où le formulaire est incomplet
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _commentController,
          decoration: const InputDecoration(labelText: 'Commentaire'),
          maxLines: 3,
        ),
        const SizedBox(height: 10),
        RatingBar.builder(
          initialRating: _rating,
          minRating: 1,
          direction: Axis.horizontal,
          itemCount: 5,
          itemSize: 40,
          itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
          itemBuilder: (context, _) => const Icon(
            Icons.star,
            color: Colors.amber,
          ),
          onRatingUpdate: (rating) {
            setState(() {
              _rating = rating;
            });
          },
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _submitReview,
          child: const Text('Ajouter un avis'),
        ),
      ],
    );
  }
}
