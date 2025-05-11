import 'package:flutter/material.dart';
import 'package:projet_pim/Model/conversation.dart';
import 'package:projet_pim/ViewModel/user_service.dart';

class ConversationProvider with ChangeNotifier {
  List<Conversation> _conversations = [];

  List<Conversation> get conversations => _conversations;

  void setConversations(List<Conversation> newConversations) {
    _conversations = newConversations;
    notifyListeners();
  }

  void updateLastMessage(String conversationId, String newMessage) {
    for (var convo in _conversations) {
      if (convo.id == conversationId) {
        convo.lastMessage =
            newMessage.isNotEmpty ? newMessage : 'Aucun message';
        notifyListeners();
        break;
      }
    }
  }

  Future<void> loadConversations(String userId) async {
    final conversations = await UserService.getUserConversations(userId);
    _conversations = conversations;
    notifyListeners();
  }
}
