import 'package:flutter/material.dart';
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/View/Event/EditEventScreen.dart';
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
    for (String userId in widget.event.participants) {
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

  // Show confirmation dialog before deleting the event
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Supprimer l'événement"),
          content: Text("Êtes-vous sûr de vouloir supprimer cet événement ?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Annuler"),
            ),
            TextButton(
              onPressed: () async {
                // Delete event
                await _deleteEvent();
                Navigator.of(context).pop();
              },
              child: Text("Supprimer", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEvent() async {
    try {
      // Your logic for deleting the event, e.g. calling a delete method in eventProvider
      await widget.eventProvider.deleteEvent(widget.event.id);
      // Go back to the previous screen after deleting
      Navigator.pop(context);
    } catch (e) {
      print("❌ Erreur lors de la suppression de l'événement : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 247, 248, 249),
            )),
        backgroundColor: const Color.fromARGB(207, 196, 189, 255),
        actions: [
          // Add the delete icon to the app bar
          if (widget.event.creatorId == widget.userId)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmation(
                    context); // Show delete confirmation dialog
              },
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(207, 196, 189, 255),
              Color.fromARGB(185, 217, 212, 255),
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.event.title,
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Text(widget.event.description,
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[700])),
                      SizedBox(height: 15),
                      _buildDetailRow(
                          Icons.location_on, "Lieu", widget.event.location,
                          iconColor: const Color.fromARGB(255, 255, 201,
                              148), // Example: Change the icon color to blue
                          textColor: const Color.fromARGB(255, 0, 0,
                              0) // Example: Change the text color to white
                          ),
                      _buildDetailRow(Icons.event, "Date",
                          "${widget.event.date.toLocal()}".split(' ')[0],
                          iconColor: const Color.fromARGB(255, 255, 169,
                              104), // Example: Change the icon color to green
                          textColor: const Color.fromARGB(255, 0, 0,
                              0) // Example: Change the text color to white
                          ),
                      _buildDetailRow(Icons.people, "Participants",
                          "${widget.event.participants.length} inscrits",
                          iconColor: const Color.fromARGB(255, 244, 120,
                              54), // Example: Change the icon color to red
                          textColor: const Color.fromARGB(255, 0, 0,
                              0) // Example: Change the text color to white
                          ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text("Participants",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(height: 10),
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : widget.event.participants.isEmpty
                      ? Text("Aucun participant pour l’instant.",
                          style: TextStyle(color: Colors.white))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: widget.event.participants.length,
                          itemBuilder: (context, index) {
                            String userId = widget.event.participants[index];
                            var user = participantDetails[userId];

                            return Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: user?["profileImage"] != null
                                      ? NetworkImage(user["profileImage"])
                                      : AssetImage("assets/default_avatar.png")
                                          as ImageProvider,
                                ),
                                title: Text(user?["name"] ?? "Inconnu",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                subtitle:
                                    Text(user?["email"] ?? "Email inconnu"),
                              ),
                            );
                          },
                        ),
              SizedBox(height: 20),
              if (widget.event.creatorId == widget.userId)
                _buildActionButton(
                  icon: Icons.edit,
                  label: "Modifier l'événement",
                  color: Colors.orange,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditEventScreen(
                          event: widget.event,
                          onSave: (updatedEvent) {
                            widget.eventProvider.updateEvent(updatedEvent);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {Color iconColor = Colors.white, Color textColor = Colors.white}) {
    return Row(
      children: [
        Icon(icon, color: iconColor), // Use the dynamic icon color
        SizedBox(width: 8),
        Text("$label : ",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor)), // Use the dynamic text color
        Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 16,
                    color: textColor))), // Use the dynamic text color
      ],
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required Color color,
      VoidCallback? onPressed}) {
    return Center(
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
