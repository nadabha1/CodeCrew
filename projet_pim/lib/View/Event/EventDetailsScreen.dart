import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/View/Event/EditEventScreen.dart';
import 'package:projet_pim/View/Event/VideoPlayerScreen.dart';
import 'package:projet_pim/View/chat/group_chat_screen.dart';
import 'package:projet_pim/View/main_screen.dart';
import 'package:projet_pim/View/profile.dart';
import 'package:projet_pim/View/user_profile.dart';
import 'package:projet_pim/ViewModel/activityLoggerService.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:projet_pim/ViewModel/shareEventMessage.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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
      checkReelExists(); // ✅ check si reel existe

  }


Future<String?> pickMusicFile() async {
  // Demande de permission
  if (!await Permission.storage.request().isGranted) {
    print('⛔ Permission refusée');
    return null;
  }

  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['mp3', 'm4a', 'aac'],
  );

  if (result != null && result.files.single.path != null) {
    print("🎵 Musique choisie : ${result.files.single.path}");
    return result.files.single.path;
  } else {
    print("❌ Aucune musique sélectionnée");
    return null;
  }
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
                                        token: widget.token,
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
                                                            eventProvider: EventProvider(userId: widget.userId),

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
                ElevatedButton.icon(
  onPressed: () {
    _showShareInConversationDialog();
  },
  icon: Icon(Icons.share, color: Colors.white),
  label: Text("Partager dans une conversation"),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.deepPurple,
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
),
ElevatedButton.icon(
  onPressed: shareEventToMessenger,
  icon: Icon(Icons.send),
  label: Text("Partager sur Messenger"),
  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
),
ElevatedButton.icon(
  icon: Icon(Icons.camera_alt),
  label: Text("Créer un souvenir"),
  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
  onPressed: () async {
  final picker = ImagePicker();
  final picked = await picker.pickMultiImage();

  if (picked != null && picked.isNotEmpty) {
    final files = picked.map((e) => File(e.path)).toList();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Téléversement en cours...")),
    );

    await uploadReelImages(widget.event.id!, widget.userId, files);
    print(widget.event.id);
    await generateReel(widget.event.id!);
  }
}
,
),
ElevatedButton.icon(
  icon: Icon(Icons.music_note),
  label: Text("Ajouter une musique"),
  onPressed: () async {
    final path = await pickMusicFile();

    if (path != null) {
      // Extraire juste le nom du fichier
      final filename = path.split('/').last;

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/reels/add-music/${widget.event.id}'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"music": filename}),
      );

      if (response.statusCode == 200|| response.statusCode==201) {
        print("✅ Musique ajoutée !");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🎵 Musique ajoutée au souvenir !")),
        );
      } else {
        print("❌ Erreur : ${response.body}");
      }
    }
  },
),

if(_reelExists)
  ElevatedButton.icon(
  icon: Icon(Icons.movie),
  label: Text("🎬 Voir souvenir"),
  onPressed: () {
    final reelUrl = '${ApiConstants.baseUrl}/reels/${widget.event.id}.mp4';
    print("🎥 Requête vers : $reelUrl");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(videoUrl: reelUrl),
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
  }void _showShareInConversationDialog() async {
  final response = await http.get(
    Uri.parse('${ApiConstants.baseUrl}/conversations/${widget.userId}'),
    headers: {'Authorization': 'Bearer ${widget.token}'},
  );

  if (response.statusCode == 200) {
    final conversations = jsonDecode(response.body);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Partager l'événement"),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final List participants = conv['participants'];
              String nameToDisplay;

              if (conv['title'] != null && conv['title'].toString().isNotEmpty) {
                nameToDisplay = conv['title']; // Groupe
              } else {
                final other = participants.firstWhere(
                  (p) => p['_id'] != widget.userId,
                  orElse: () => {'name': 'Utilisateur inconnu'},
                );
                nameToDisplay = other['name'] ?? 'Utilisateur inconnu'; // Privée
              }

              return ListTile(
                title: Text(nameToDisplay),
                onTap: () async {
                  final event = widget.event;

                  final message = """
📢 *${event.title}*
📍 Lieu : ${event.location.latitude.toStringAsFixed(4)}, ${event.location.longitude.toStringAsFixed(4)}
📅 Début : ${_formatDate(event.startDate)}
🔗 Rejoins : ${event.conversationId != null ? "chat/${event.conversationId}" : "cet événement"}
""";

                  await shareEventMessage(
                    conversationId: conv['_id'],
                    userId: widget.userId,
                    eventId: event.id,
                    context: context,
                    msg: message,
                  );

                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  } else {
    print('❌ Erreur lors de la récupération des conversations');
  }
  
}

void shareEventToMessenger() {
  final event = widget.event;
  final message = """
📢 ${event.title}
📍 Lieu : ${event.location.latitude.toStringAsFixed(4)}, ${event.location.longitude.toStringAsFixed(4)}
📅 Début : ${_formatDate(event.startDate)}
🔗 Rejoins : ${event.conversationId != null ? "chat/${event.conversationId}" : "cet événement"}
""";

  Share.share(message);
}
void _shareEventToConversation(String conversationId) async {
  final event = widget.event;

  final message = """
📢 *${event.title}*
📍 Lieu : ${event.location.latitude.toStringAsFixed(4)}, ${event.location.longitude.toStringAsFixed(4)}
📅 Début : ${_formatDate(event.startDate)}
🔗 Rejoins : ${event.conversationId != null ? "chat/${event.conversationId}" : "cet événement"}

""";

  final response = await http.post(
    Uri.parse('${ApiConstants.baseUrl}/messages'),
    headers: {
      'Authorization': 'Bearer ${widget.token}',
      'Content-Type': 'application/json'
    },
    body: jsonEncode({
      "conversationId": conversationId,
      "senderId": widget.userId,
      "content": message,
    }),
  );
  print("🔁 Envoi : $conversationId | sender=${widget.userId}");
  print("🔁 Contenu : $message");


  if (response.statusCode == 201) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Événement partagé avec succès !')),
    );
  } else {
    print("Erreur d'envoi : ${response.body}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Échec du partage de l’événement')),
    );
  }
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
Future<void> uploadReelImages(String eventId, String userId, List<File> images) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('${ApiConstants.baseUrl}/reels/upload'),
  );

  request.fields['eventId'] = eventId;
  request.fields['userId'] = userId;

  for (var image in images) {
    request.files.add(await http.MultipartFile.fromPath('files', image.path));
  }

  var response = await request.send();
  if (response.statusCode == 201) {
    print("✅ Images uploadées avec succès");
  } else {
    print("❌ Erreur d’upload : ${response.statusCode}");
  }
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
  Future<void> generateReel(String eventId) async {
  final response = await http.post(
    Uri.parse('${ApiConstants.baseUrl}/reels/generate/$eventId'),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
  print("🎞️ Reel généré avec succès");
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("🎞️ Souvenir généré !")),
  );
  await checkReelExists(); // 🔁 Ajoute ça pour afficher le bouton "🎬 Voir souvenir"
} else {
  print("❌ Échec de la génération du Reel");
  print(response.body);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Erreur lors de la génération du Reel.")),
  );
}

}
bool _reelExists = false;

Future<void> checkReelExists() async {
  final url = Uri.parse('${ApiConstants.baseUrl}/reels/${widget.event.id}.mp4');
  final response = await http.head(url);
  setState(() {
    _reelExists = response.statusCode == 200;
  });
}


}
