import 'package:latlong2/latlong.dart';
import 'package:projet_pim/Model/review.dart';

class Place {
  final String id;
  final String name;
  final double? latitude;
  final double? longitude;
  final String description;
  final List<String> categories;
  final int unlockCost;
    LatLng? get coordinates {
    return (latitude != null && longitude != null) 
        ? LatLng(latitude!, longitude!)
        : null;
  }
  final List<String> images; // Liste des URLs des images
  final List<Review> reviews; // Liste des avis associés au lieu
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
    );
  }
}

class Carnet {
  final String id;
  final String title;
  final String owner;
  final List<Place> places;

  Carnet({
    required this.id,
    required this.title,
    required this.owner,
    required this.places,
  });

  factory Carnet.fromJson(Map<String, dynamic> json) {
    var placesList =
        (json['places'] as List).map((i) => Place.fromJson(i)).toList();

    return Carnet(
      id: json['_id'],
      title: json['title'],
      owner: json['owner'],
      places: placesList,
    );
  }
}
