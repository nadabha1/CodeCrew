import 'package:flutter/material.dart';
import 'package:projet_pim/Model/conversation.dart';
import 'package:projet_pim/ViewModel/user_service.dart';

class ChatListPage extends StatefulWidget {
  final String userId;
  const ChatListPage({super.key, required this.userId});

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late Future<List<Conversation>> _conversations;

  @override
  void initState() {
    super.initState();
    _conversations = UserService.getUserConversations(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversations')),
      body: FutureBuilder<List<Conversation>>(
        future: _conversations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune conversation.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var convo = snapshot.data![index];
              return ListTile(
                title: Text(convo.participants.join(', ')),
                subtitle: Text(convo.lastMessage ?? 'Aucun message'),
                onTap: () {
                  // Rediriger vers la page de discussion
                },
              );
            },
          );
        },
      ),
    );
  }
}
