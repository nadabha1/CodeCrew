import 'package:latlong2/latlong.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final DateTime startDate;
  final DateTime endDate;
  final LatLng location;
  final List<Map<String, dynamic>> participants;
  final bool isParticipating;
  final int joinPrice;
  final String conversationId;
  final String type;
  String? imagePath; // Add imagePath here

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
    required this.conversationId,
    required this.type,
    this.imagePath, // Add this to the constructor
  });

  factory Event.fromJson(Map<String, dynamic> json, String userId) {
    LatLng parsedLocation = LatLng(0, 0);

    if (json['location'] != null) {
      if (json['location'] is String) {
        try {
          List<String> coordinates = json['location'].split(',');
          if (coordinates.length == 2) {
            parsedLocation = LatLng(
              double.parse(coordinates[0].trim()),
              double.parse(coordinates[1].trim()),
            );
          } else {
            throw FormatException("Invalid location format");
          }
        } catch (e) {
          print("❌ Error parsing location string: $e");
        }
      } else if (json['location'] is Map<String, dynamic>) {
        try {
          parsedLocation = LatLng(
            (json['location']['latitude'] ?? 0).toDouble(),
            (json['location']['longitude'] ?? 0).toDouble(),
          );
        } catch (e) {
          print("❌ Error parsing location map: $e");
        }
      }
    }

    final participantsList = (json['participants'] as List)
        .map((e) {
          if (e is String) {
            return {'_id': e}; // Wrap the string in a map with `_id` as the key
          } else if (e is Map) {
            return Map<String, dynamic>.from(
                e as Map); // Explicitly cast to Map<String, dynamic>
          } else {
            return <String, dynamic>{}; // Handle unexpected cases gracefully
          }
        })
        .toList()
        .cast<
            Map<String,
                dynamic>>(); // Ensure the list is of type List<Map<String, dynamic>>

    return Event(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      creatorId: json['creatorId'] is Map<String, dynamic>
          ? json['creatorId']['_id']
          : json['creatorId'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      location: parsedLocation,
      participants: participantsList,
      isParticipating: participantsList.any((p) => p['_id'] == userId),
      joinPrice: json['joinPrice'] ?? 5,
      conversationId: json['conversationId'] ?? '',
      type: json['type'] ?? 'Other',
      imagePath: json['imagePath'], // Parse the imagePath here
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
    List<Map<String, dynamic>>? participants,
    bool? isParticipating,
    int? joinPrice,
    String? conversationId,
    String? type,
    String? imagePath, // Add imagePath as an optional parameter
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
      joinPrice: joinPrice ?? this.joinPrice,
      conversationId: conversationId ?? this.conversationId,
      type: type ?? this.type,
      imagePath: imagePath ?? this.imagePath, // Update copyWith for imagePath
    );
  }
}
