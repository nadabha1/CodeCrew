import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewGroupConversationScreen extends StatefulWidget {
  @override
  _NewGroupConversationScreenState createState() => _NewGroupConversationScreenState();
}

class _NewGroupConversationScreenState extends State<NewGroupConversationScreen> {
  List users = [];
  List<String> selectedUserIds = [];
  TextEditingController groupNameController = TextEditingController();
  String? _userId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFollowing();
  }

  Future<void> fetchFollowing() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString("user_id");
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/follow/following/${_userId}'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
    final List<dynamic> data = jsonData['following']; // ✅ extract the list

      setState(() {
        users = data;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      throw Exception("Erreur lors du chargement des utilisateurs suivis");
    }
  }

  Future<void> createGroupConversation() async {
    if (groupNameController.text.isEmpty || selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Nom de groupe ou membres manquants.")));
      return;
    }

    final allParticipantIds = [_userId!, ...selectedUserIds];
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/conversations/group'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "participants": allParticipantIds,
        "title": groupNameController.text.trim(),
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      print(response.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de la création du groupe.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Créer un groupe")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: groupNameController,
                    decoration: InputDecoration(labelText: "Nom du groupe"),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final userId = user['_id'];
                        final isSelected = selectedUserIds.contains(userId);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user['profileImage'] != null
                                ? NetworkImage(user['profileImage'])
                                : AssetImage('assets/default_profile.png') as ImageProvider,
                          ),
                          title: Text(user['name']),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (_) {
                              setState(() {
                                if (isSelected) {
                                  selectedUserIds.remove(userId);
                                } else {
                                  selectedUserIds.add(userId);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: createGroupConversation,
                    child: Text("Créer le groupe"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC8C4FF),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
