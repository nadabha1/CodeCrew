import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewGroupConversationScreen extends StatefulWidget {
  @override
  _NewGroupConversationScreenState createState() =>
      _NewGroupConversationScreenState();
}

class _NewGroupConversationScreenState
    extends State<NewGroupConversationScreen> {
  List users = [];
  List<String> selectedUserIds = [];
  TextEditingController groupNameController = TextEditingController();
  String? userId;
  String? token;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? _userId = prefs.getString("user_id");
    String? _token = prefs.getString("jwt_token");

    if (_userId != null && _token != null) {
      setState(() {
        userId = _userId;
        token = _token;
      });
      // Now call getFollowing to fetch followed users
      await getFollowing(_userId!); // Pass the userId to getFollowing
    } else {
      print("User ID or Token is not available");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Call getFollowing via UserService
  Future<void> getFollowing(String userId) async {
    try {
      // Récupérer la liste des utilisateurs suivis
      UserService userService = UserService();
      List<String> following = await userService.getFollowing(userId);

      // Appeler la fonction pour récupérer les détails des utilisateurs suivis
      List<Map<String, dynamic>> fetchedUsers =
          await getUserById(following, token!);

      setState(() {
        users =
            fetchedUsers; // Mettre à jour la liste des utilisateurs avec les données récupérées
        isLoading = false;
      });
    } catch (e) {
      print("Erreur lors de la récupération des utilisateurs suivis: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> getUserById(
      List<String> userIds, String token) async {
    List<Map<String, dynamic>> fetchedUsers = [];

    for (String userId in userIds) {
      try {
        final user = await UserService().getUserById(userId, token);
        if (user.containsKey('_id')) {
          fetchedUsers.add(user); // Ajouter l'utilisateur dans la liste
        }
      } catch (e) {
        print(
            "Erreur lors de la récupération des détails de l'utilisateur $userId: $e");
      }
    }

    return fetchedUsers;
  }

  // Fonction pour créer une conversation de groupe
  Future<void> createGroupConversation() async {
    if (groupNameController.text.isEmpty || selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Nom de groupe ou membres manquants.")));
      return;
    }

    final allParticipantIds = [userId!, ...selectedUserIds];
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la création du groupe.")));
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
                                : AssetImage('assets/default_profile.png')
                                    as ImageProvider,
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
