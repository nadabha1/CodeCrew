import 'package:flutter/material.dart';
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/View/chat/group_chat_screen.dart';
import 'package:projet_pim/View/main_screen.dart';
import 'package:projet_pim/View/profile.dart';
import 'package:projet_pim/View/user_profile.dart';
import 'package:projet_pim/ViewModel/activityLoggerService.dart';
import 'package:projet_pim/ViewModel/user_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final Event event;
  final String userId;
  final String token;
  final EventProvider eventProvider;

  const EventDetailsScreen({
    Key? key,
    required this.event,
    required this.userId,
    required this.token,
    required this.eventProvider,
  }) : super(key: key);

  @override
  _EventDetailsScreenState createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final UserService userService = UserService();
  Map<String, dynamic> participantDetails = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchParticipants();
  }

  Future<void> _fetchParticipants() async {
  Map<String, dynamic> details = {};
  for (var participant in widget.event.participants) {
    final userId = participant['_id'];
    try {
      var user = await userService.getUserById(userId, widget.token);
      details[userId] = user;
    } catch (e) {
      print("❌ Erreur lors de la récupération de l'utilisateur $userId : $e");
    }
  }
  setState(() {
    participantDetails = details;
    isLoading = false;
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 0, 0, 0),
            )),
        backgroundColor: const Color(0xFFEDE7F6),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEDE7F6),
              Color(0xFFD1C4E9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 5,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.event.title,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                      SizedBox(height: 10),
                      Text(widget.event.description,
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[800])),
                      SizedBox(height: 15),
                      _buildDetailRow(
                          Icons.location_on, "Lieu", widget.event.location,
                          iconColor: Color(0xFFFF8A65)),
                      _buildDetailRow(Icons.event, "Date",
                          "${widget.event.date.toLocal()}".split(' ')[0],
                          iconColor: Color(0xFF4CAF50)),
                      _buildDetailRow(Icons.people, "Participants",
                          "${widget.event.participants.length} inscrits",
                          iconColor: Color(0xFF29B6F6)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text("Participants",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4E4E4E))),
              SizedBox(height: 10),
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : widget.event.participants.isEmpty
                      ? Text("Aucun participant pour l’instant.",
                          style: TextStyle(color: Colors.grey[700]))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: widget.event.participants.length,
                          itemBuilder: (context, index) {
final participant = widget.event.participants[index];
final userId = participant['_id'];
                            var user = participantDetails[userId];
                            bool isCurrentUser = userId == widget.userId;

                            return GestureDetector(
                              onTap: () {
                                if (isCurrentUser) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MainScreen(initialIndex: 4),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TravelerProfileScreen(
                                        travelerId: userId,
                                        loggedInUserId: widget.userId,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage:
                                        user?["profileImage"] != null
                                            ? NetworkImage(user["profileImage"])
                                            : AssetImage(
                                                    "assets/default_avatar.png")
                                                as ImageProvider,
                                  ),
                                  title: Text(
                                    "${user?["name"] ?? "Inconnu"} ${isCurrentUser ? "(moi)" : ""}",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle:
                                      Text(user?["email"] ?? "Email inconnu"),
                                ),
                              ),
                            );
                          },
                        ),
              SizedBox(height: 20),
              if (widget.event.participants.contains(widget.userId))
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupChatScreen(
                          conversationId: widget.event.conversationId,
                          groupName: widget.event.title,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.chat, color: Colors.white),
                  label: Text("Rejoindre le Chat"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 221, 170, 228),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {Color iconColor = Colors.black}) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        SizedBox(width: 8),
        Text("$label : ",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        Expanded(
            child: Text(value,
                style: TextStyle(fontSize: 16, color: Colors.black))),
      ],
    );
  }
}
