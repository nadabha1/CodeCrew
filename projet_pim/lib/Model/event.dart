class Event {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final DateTime date;
  final String location;
  final List<String> participants;
  final bool isParticipating;
  final int joinPrice;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.date,
    required this.location,
    required this.participants,
    required this.isParticipating,
    required this.joinPrice,
  });

  factory Event.fromJson(Map<String, dynamic> json, String userId) {
    return Event(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      creatorId: json['creatorId'],
      date: DateTime.parse(json['date']),
      location: json['location'],
      participants: List<String>.from(json['participants']),
      isParticipating: List<String>.from(json['participants']).contains(userId),
      joinPrice: json['joinPrice'] ?? 5,
    );
  }
}