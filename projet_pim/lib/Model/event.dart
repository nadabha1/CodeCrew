class Event {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final DateTime startDate; // Ensure this matches your backend response
  final DateTime endDate; // Ensure this matches your backend response
  final String location;
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
    return Event(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      creatorId: json['creatorId'],
      startDate: DateTime.parse(json['startDate']), // Adjust key if necessary
      endDate: DateTime.parse(json['endDate']), // Adjust key if necessary
      location: json['location'],
      participants: List<String>.from(json['participants']),
      isParticipating: List<String>.from(json['participants']).contains(userId),
      joinPrice: json['joinPrice'] ?? 5,
      conversationId:
          json['conversationId'], // ➡️ Assure-toi de l'inclure ici aussi

      type: json['type'] ?? 'Other', // Handle missing type
    );
  }
}
