import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/View/Event/EditEventScreen.dart';
import 'package:projet_pim/View/chat/group_chat_screen.dart';
import 'package:projet_pim/View/main_screen.dart';
import 'package:projet_pim/View/profile.dart';
import 'package:projet_pim/View/user_profile.dart';
import 'package:projet_pim/ViewModel/activityLoggerService.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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


  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date); // Format personnalisé
  }

  Future<String> getAddressFromStringCoords(String coords) async {
    try {
      final parts = coords.split(',');
      if (parts.length != 2) return "Coordonnées invalides";

      final lat = double.parse(parts[0]);
      final lng = double.parse(parts[1]);
      return await getAddressFromLatLng(lat, lng);
    } catch (e) {
      print("Erreur lors de la conversion des coordonnées : $e");
      return "Adresse inconnue";
    }
  }

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.locality}, ${place.country}"; // Example: Paris, France
      }
    } catch (e) {
      print("Erreur de conversion: $e");
    }
    return "Localisation inconnue";
  }

  void _openInGoogleMaps(double latitude, double longitude) async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
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
        actions: [
          if (widget.event.creatorId == widget.userId)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.orange),
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
                      _buildLocationDetailRow(
                          "${widget.event.location.latitude},${widget.event.location.longitude}"),
                      SizedBox(height: 15),
                      _buildDetailRow(
                        Icons.event,
                        "Début",
                        _formatDate(widget.event.startDate),
                        iconColor: Color(0xFF4CAF50),
                      ),
                      SizedBox(height: 6),
                      _buildDetailRow(
                        Icons.event_available,
                        "Fin",
                        _formatDate(widget.event.endDate),
                        iconColor: Color(0xFF81C784),
                      ),
                      _buildDetailRow(Icons.people, "Participants",
                          "${widget.event.participants.length} inscrits",
                          iconColor: Color(0xFF29B6F6)),
                    ],
                  ),
                ),
              ),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: FlutterMap(
                  options: MapOptions(
                    center: LatLng(widget.event.location.latitude ?? 0.0,
                        widget.event.location.longitude ?? 0.0),
                    zoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(widget.event.location.latitude ?? 0.0,
                              widget.event.location.longitude ?? 0.0),
                          width: 40.0,
                          height: 40.0,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  {
                    _openInGoogleMaps(widget.event.location.latitude!,
                        widget.event.location.longitude!);
                  }
                },
                child: const Text("Ouvrir dans Google Maps"),
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

  Widget _buildLocationDetailRow(String coords) {
    return FutureBuilder<String>(
      future: getAddressFromStringCoords(coords),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildDetailRow(
            Icons.location_on,
            "Lieu",
            snapshot.data!,
            iconColor: Color(0xFFFF8A65),
          );
        } else {
          // Si l'adresse n'est pas encore disponible, on ne montre rien.
          return SizedBox.shrink();
        }
      },
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
