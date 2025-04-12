class Conversation {
  final String id;
  final List<String> participants;
  String? lastMessage;
  String? lastMessageDate;

  Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageDate,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'],
      participants:
          List<String>.from(json['participants'].map((p) => p['username'])),
      lastMessage: json['lastMessage']?['content'],
      lastMessageDate: json['lastMessageDate'],
    );
  }
}
