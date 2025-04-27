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
import 'package:projet_pim/View/Event/ReelStoryView.dart';
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
    super.key,
    required this.event,
    required this.userId,
    required this.token,
    required this.eventProvider,
  });

  @override
  _EventDetailsScreenState createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final UserService userService = UserService();
  Map<String, dynamic> participantDetails = {};
  bool isLoading = true;
  bool _reelExists = false;
  List<String> reelsUrls = [];
  bool isShared = true; // ✅ valeur choisie par l'utilisateur

  @override
  void initState() {
    super.initState();
    _fetchParticipants();
    fetchReels(); // ✅ récupérer tous les reels
  }

  Future<void> _generateReel() async {
    final response = await http.post(
      Uri.parse(
          '${ApiConstants.baseUrl}/reels/generate/${widget.event.id}/${widget.userId}'),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      print("🎞️ Reel généré avec succès");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎞️ Souvenir généré !")),
      );
      await _checkReels();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur de génération du Reel.")),
      );
    }
  }

  Future<void> fetchReels() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/reels?eventId=${widget.event.id}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isEmpty) {
          _reelExists = false;
          return;
        }
        print("✅ Reels récupérés : ${data.length}");
        // 🔥 filtrer les reels visibles :
        reelsUrls = [];
        for (var reel in data) {
          if (reel['isShared'] == true || reel['userId'] == widget.userId) {
            reelsUrls.add('${ApiConstants.baseUrl}/${reel['videoUrl']}');
          }
        }
        _reelExists = reelsUrls.isNotEmpty;
      } else {
        _reelExists = false;
      }
    } catch (e) {
      _reelExists = false;
      print('Erreur récupération reels: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _checkReels() async {
    setState(() => isLoading = true);
    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/reels/${widget.event.id}'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          reelsUrls = List<String>.from(data.map((r) => r['videoUrl']));
          print("✅ Reels récupérés : ${reelsUrls.length}");
          _reelExists = true;
        } else {
          _reelExists = false;
        }
      } else {
        _reelExists = false;
      }
    } catch (e) {
      _reelExists = false;
    }
    setState(() => isLoading = false);
  }

  Future<void> _uploadAndGenerateReel({required bool isShared}) async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();

    if (picked.isNotEmpty) {
      final files = picked.map((e) => File(e.path)).toList();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Téléversement en cours...")),
      );

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/reels/upload'),
      );
      request.fields['eventId'] = widget.event.id;
      request.fields['userId'] = widget.userId;
      request.fields['isShared'] =
          isShared.toString(); // 👈✅ on ajoute le choix

      for (var file in files) {
        request.files
            .add(await http.MultipartFile.fromPath('files', file.path));
      }

      var response = await request.send();
      if (response.statusCode == 201 || response.statusCode == 200) {
        print("✅ Images uploadées avec succès");
        await _generateReel();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur d’upload.")),
        );
      }
    }
  }

  void _openStoryView() {
    if (reelsUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucun souvenir disponible.")),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReelStoryView(reelsUrls: reelsUrls),
        //  builder: (_) => TestVideoScreen(),
      ),
    );
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 0, 0),
            )),
        backgroundColor: const Color(0xFFEDE7F6),
        actions: [
          if (widget.event.creatorId == widget.userId)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
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
        decoration: const BoxDecoration(
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
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                      const SizedBox(height: 10),
                      Text(widget.event.description,
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[800])),
                      const SizedBox(height: 15),
                      _buildLocationDetailRow(
                          "${widget.event.location.latitude},${widget.event.location.longitude}"),
                      const SizedBox(height: 15),
                      _buildDetailRow(
                        Icons.event,
                        "Début",
                        _formatDate(widget.event.startDate),
                        iconColor: const Color(0xFF4CAF50),
                      ),
                      const SizedBox(height: 6),
                      _buildDetailRow(
                        Icons.event_available,
                        "Fin",
                        _formatDate(widget.event.endDate),
                        iconColor: const Color(0xFF81C784),
                      ),
                      _buildDetailRow(Icons.people, "Participants",
                          "${widget.event.participants.length} inscrits",
                          iconColor: const Color(0xFF29B6F6)),
                    ],
                  ),
                ),
              ),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
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
                      subdomains: const ['a', 'b', 'c'],
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
                    _openInGoogleMaps(widget.event.location.latitude,
                        widget.event.location.longitude);
                  }
                },
                child: const Text("Ouvrir dans Google Maps"),
              ),
              const SizedBox(height: 20),
              const Text("Participants",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4E4E4E))),
              const SizedBox(height: 10),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : widget.event.participants.isEmpty
                      ? Text("Aucun participant pour l’instant.",
                          style: TextStyle(color: Colors.grey[700]))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.event.participants.length,
                          itemBuilder: (context, index) {
                            final participant =
                                widget.event.participants[index];
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
                                          const MainScreen(initialIndex: 4),
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
                                            : const AssetImage(
                                                    "assets/default_avatar.png")
                                                as ImageProvider,
                                  ),
                                  title: Text(
                                    "${user?["name"] ?? "Inconnu"} ${isCurrentUser ? "(moi)" : ""}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle:
                                      Text(user?["email"] ?? "Email inconnu"),
                                ),
                              ),
                            );
                          },
                        ),
              const SizedBox(height: 20),
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
                          userId: widget.userId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text("Rejoindre le Chat"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 221, 170, 228),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: () {
                  _showShareInConversationDialog();
                },
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text("Partager dans une conversation"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: shareEventToMessenger,
                icon: const Icon(Icons.send),
                label: const Text("Partager sur Messenger"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text("Créer un souvenir"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Souhaites-tu partager ce souvenir ?'),
                      actions: [
                        TextButton(
                          child: const Text('Privé 🔒'),
                          onPressed: () {
                            Navigator.pop(context);
                            _uploadAndGenerateReel(
                                isShared: false); // 🚀 upload privé
                          },
                        ),
                        TextButton(
                          child: const Text('Public 🌍'),
                          onPressed: () {
                            Navigator.pop(context);
                            _uploadAndGenerateReel(
                                isShared: true); // 🚀 upload public
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
/*if(_reelExists)
  ElevatedButton.icon(
  icon: const Icon(Icons.movie),
  label: const Text("🎬 Voir souvenir"),
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
),*/
              if (_reelExists)
                ElevatedButton.icon(
                  onPressed: _openStoryView,
                  icon: const Icon(Icons.movie),
                  label: const Text("🎬 Voir souvenirs"),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                ),
              if (!_reelExists)
                const Center(
                  child: Text(
                    "Pas encore de souvenirs 🎬",
                    style: TextStyle(color: Colors.grey),
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
        const SizedBox(width: 8),
        Text("$label : ",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black)),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 16, color: Colors.black))),
      ],
    );
  }

  void _showShareInConversationDialog() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/conversations/${widget.userId}'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      final conversations = jsonDecode(response.body);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Partager l'événement"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conv = conversations[index];
                final List participants = conv['participants'];
                String nameToDisplay;

                if (conv['title'] != null &&
                    conv['title'].toString().isNotEmpty) {
                  nameToDisplay = conv['title']; // Groupe
                } else {
                  final other = participants.firstWhere(
                    (p) => p['_id'] != widget.userId,
                    orElse: () => {'name': 'Utilisateur inconnu'},
                  );
                  nameToDisplay =
                      other['name'] ?? 'Utilisateur inconnu'; // Privée
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
        const SnackBar(content: Text('✅ Événement partagé avec succès !')),
      );
    } else {
      print("Erreur d'envoi : ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Échec du partage de l’événement')),
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
            iconColor: const Color(0xFFFF8A65),
          );
        } else {
          // Si l'adresse n'est pas encore disponible, on ne montre rien.
          return const SizedBox.shrink();
        }
      },
    );
  }

  Future<void> uploadReelImages(
      String eventId, String userId, List<File> images) async {
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> generateReel(String eventId) async {
    final response = await http.post(
      Uri.parse(
          '${ApiConstants.baseUrl}/reels/generate/${widget.event.id}/${widget.userId}'),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("🎞️ Reel généré avec succès");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎞️ Souvenir généré !")),
      );
      await fetchReels(); // 🔁 Ajoute ça pour afficher le bouton "🎬 Voir souvenir"
    } else {
      print("❌ Échec de la génération du Reel");
      print(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la génération du Reel.")),
      );
    }
  }
}
