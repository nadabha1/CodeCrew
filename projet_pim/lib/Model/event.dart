import 'package:latlong2/latlong.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final DateTime startDate; // Ensure this matches your backend response
  final DateTime endDate; // Ensure this matches your backend response
  final LatLng location;
  final List<String> participants;
  final bool isParticipating;
  final int joinPrice;
  final String conversationId; // ➡️ Nouvelle propriété

  final String type; // Add event type

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.participants,
    required this.isParticipating,
    required this.joinPrice,
    required this.conversationId, // ➡️ Assure-toi de l'inclure ici aussi

    required this.type, // Initialize type
  });

  factory Event.fromJson(Map<String, dynamic> json, String userId) {
    LatLng parsedLocation = LatLng(0, 0); // Valeur par défaut

    if (json['location'] != null) {
      if (json['location'] is String) {
        try {
          List<String> coordinates = json['location'].split(',');
          parsedLocation = LatLng(
            double.parse(coordinates[0].trim()), // Latitude
            double.parse(coordinates[1].trim()), // Longitude
          );
        } catch (e) {
          print("❌ Erreur parsing location: $e");
        }
      } else if (json['location'] is Map<String, dynamic>) {
        parsedLocation = LatLng(
          (json['location']['latitude'] ?? 0).toDouble(),
          (json['location']['longitude'] ?? 0).toDouble(),
        );
      }
    }
    return Event(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      creatorId: json['creatorId'],
      startDate: DateTime.parse(json['startDate']), // Adjust key if necessary
      endDate: DateTime.parse(json['endDate']), // Adjust key if necessary
      location: parsedLocation, // ✅ Gère string ou Map

      participants: List<String>.from(json['participants']),
      isParticipating: List<String>.from(json['participants']).contains(userId),
      joinPrice: json['joinPrice'] ?? 5,
      conversationId:
          json['conversationId'], // ➡️ Assure-toi de l'inclure ici aussi

      type: json['type'] ?? 'Other', // Handle missing type
    );
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? creatorId,
    DateTime? startDate,
    DateTime? endDate,
    LatLng? location,
    List<String>? participants,
    bool? isParticipating,
    double? joinPrice,
    String? conversationId,
    String? type,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      participants: participants ?? this.participants,
      isParticipating: isParticipating ?? this.isParticipating,
      joinPrice: (joinPrice?.toInt() ?? this.joinPrice),
      conversationId: conversationId ?? this.conversationId,
      type: type ?? this.type,
    );
  }
}
