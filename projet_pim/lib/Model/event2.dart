class Event2 {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final DateTime date;
  final String location;
  final List<dynamic> participants;
  final bool isParticipating;
  final int joinPrice;
  final String conversationId;
  final String type;

  Event2({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.date,
    required this.location,
    required this.participants,
    required this.isParticipating,
    required this.joinPrice,
    required this.conversationId,
    required this.type,
  });

  factory Event2.fromJson(Map<String, dynamic> json, String userId) {
    return Event2(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      creatorId: json['creatorId'],
      date: DateTime.parse(json['date']),
      location: json['location'],
      participants: json['participants'] ?? [],
      isParticipating: (json['participants'] as List)
          .any((p) => p is Map && p['_id'] == userId),
      joinPrice: json['joinPrice'] ?? 5,
      conversationId: json['conversationId'],
      type: json['type'] ?? 'Other',
    );
  }
}
