class Place {
  final String id;
  final String name;
  final double? latitude;
  final double? longitude;
  final String description;
  final List<String> categories;
  final int unlockCost;
  final List<String> images;

  Place({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    required this.description,
    required this.categories,
    required this.unlockCost,
    required this.images,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      categories: List<String>.from(json['categories']),
      unlockCost: json['unlockCost'],
      images: List<String>.from(json['images']),
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
  var placesList = (json['places'] as List)
      .map((i) => Place.fromJson(i))
      .toList();

  return Carnet(
    id: json['_id'],
    title: json['title'],
      owner: json['owner'] ?? "",  // 🔥 Ensure owner is never null
    places: placesList,
  );
}

}
