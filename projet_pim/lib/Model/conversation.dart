class Conversation {
  final String id;
  final List<String> participants;
  final String? lastMessage;

  Conversation({required this.id, required this.participants, this.lastMessage});

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'],
      participants: List<String>.from(json['participants'].map((p) => p['username'])),
      lastMessage: json['lastMessage']?['content'],
    );
  }
}
