import 'package:geolocator/geolocator.dart';
import 'package:projet_pim/CustomAnnotation.dart';
import 'package:projet_pim/Model/review.dart';

class Place {
  final String id;
  final String name;
  final double? latitude;
  final double? longitude;
  final String description;
  final List<String> categories;
  final int unlockCost;
  final List<String> images; // Liste des URLs des images
  final List<Review> reviews; // Liste des avis associés au lieu
  final double averageRating;

  Place({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    required this.description,
    required this.categories,
    required this.unlockCost,
    required this.images,
    this.reviews = const [],
    this.averageRating = 0.0, // Valeur par défaut
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['_id'],
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      description: json['description'],
      categories: List<String>.from(json['categories']),
      unlockCost: json['unlockCost'],
      images: List<String>.from(json['images']), // Initialisation des images
      averageRating:
          (json['averageRating'] ?? 0).toDouble(), // Récupérer la note moyenne
    );
  }

  // The copyWith method
  Place copyWith({
    String? name,
    String? description,
    List<String>? images,
    List<String>? categories, // Add categories to the copyWith method
    int? unlockCost,
    double? latitude,
    double? longitude,
    double? averageRating,
  }) {
    return Place(
      id: this.id, // Keep the same ID
      name: name ??
          this.name, // If a new name is passed, use it; otherwise, keep the current one
      description: description ?? this.description,
      images: images ?? this.images,
      categories:
          categories ?? this.categories, // Update categories if provided
      unlockCost: unlockCost ?? this.unlockCost,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      averageRating: averageRating ?? this.averageRating,
    );
  }

  CustomAnnotation toAnnotation() {
    return CustomAnnotation(
      uid: this.id,
      position: Position(
        latitude: this.latitude ?? 0.0,
        longitude: this.longitude ?? 0.0,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 5.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 1.0,
      ),
      title: this.name,
      imageUrl:
          images.isNotEmpty ? images[0] : null, // Utiliser la première image
    );
  }
}

class Carnet {
  final String id;
  final String title;
  final String owner;
  final List<Place> places;
  final double globalAverageRating;

  Carnet({
    required this.id,
    required this.title,
    required this.owner,
    required this.places,
    this.globalAverageRating = 0.0, // Valeur par défaut
  });

  factory Carnet.fromJson(Map<String, dynamic> json) {
    var placesList =
        (json['places'] as List).map((i) => Place.fromJson(i)).toList();

    return Carnet(
      id: json['_id'],
      title: json['title'],
      owner: json['owner'],
      places: placesList,
      globalAverageRating: (json['globalAverageRating'] ?? 0).toDouble(),
    );
  }
}
