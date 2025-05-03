/*import 'package:flutter/material.dart';
import 'package:projet_pim/Model/conversation.dart';
import 'package:projet_pim/Providers/conversation_provider.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:provider/provider.dart';

class ChatListPage extends StatefulWidget {
  final String userId;
  const ChatListPage({super.key, required this.userId});

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late Future<void> _loadConversations;

  @override
  void initState() {
    super.initState();
    _loadConversations = _loadUserConversations();
  }

  Future<void> _loadUserConversations() async {
    // Now calling loadConversations and passing context from widget
    await Provider.of<ConversationProvider>(context, listen: false)
        .loadConversations(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversations')),
      body: FutureBuilder<void>(
        future: _loadConversations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else {
            return Consumer<ConversationProvider>(
              builder: (context, conversationProvider, child) {
                final conversations = conversationProvider.conversations;
                if (conversations.isEmpty) {
                  return const Center(child: Text('Aucune conversation.'));
                }

                return ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    var convo = conversations[index];
                    return ListTile(
                      title: Text(convo.participants.join(', ')),
                      subtitle: convo.lastMessage != null &&
                              convo.lastMessage!.isNotEmpty
                          ? Text(convo.lastMessage!)
                          : const Text('Aucun message'),
                      onTap: () {
                        // Redirect to conversation screen
                      },
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
*/
