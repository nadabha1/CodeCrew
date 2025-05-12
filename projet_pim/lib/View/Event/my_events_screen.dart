import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/View/Event/EventDetailsScreen.dart';
import 'package:projet_pim/View/chat/group_chat_screen.dart';
import 'package:projet_pim/View/select_location_screen.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:provider/provider.dart';

class MyEventsScreen extends StatefulWidget {
  final String userId;
  final String token;

  const MyEventsScreen({required this.userId, required this.token});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  late EventProvider eventProvider;
  late List<Event> userEvents = [];
  final List<String> _eventTypes = [
    "Concerts",
    "Workshops",
    "Networking Events",
    "Sports Activities",
    "Cultural Festivals",
    "Tech Meetups",
    "Art Exhibitions",
    "Other"
  ];
  bool isGeneratingImage = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      eventProvider = Provider.of<EventProvider>(context, listen: false);
      _loadUserEvents(widget.userId, widget.token);
      print(
          "Nombre d'événements récupérés : ${eventProvider.userEvents.length}");
    });
  }

  Future<void> _loadUserEvents(String userId, String token) async {
    userEvents = await eventProvider.fetchUserEvents(
        userId, token); // ← Fixed syntax and type mismatch
    setState(() {});
  }

  Future<void> _uploadGeneratedImage(String base64Image, Event event) async {
    try {
      // Validate base64Image
      if (base64Image.isEmpty || !base64Image.contains(',')) {
        throw Exception("Invalid image data");
      }

      final imageBytes = base64Decode(base64Image.split(',').last);
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/generated_image.png';

      final file = File(filePath)..writeAsBytesSync(imageBytes);

      var uri = Uri.parse('${ApiConstants.baseUrl}/upload');
      var request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('photo', file.path));

      var response = await request.send();
      if (response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        final uploadedImage = jsonDecode(responseBody);

        if (uploadedImage != null && uploadedImage['filename'] != null) {
          final fullImageUrl = '/uploads/${uploadedImage['filename']}';

          // Use this URL to create the event
          await eventProvider.createEvent(
            widget.userId,
            event.title,
            event.description,
            event.startDate.toIso8601String(),
            event.endDate.toIso8601String(),
            "${event.location.latitude},${event.location.longitude}",
            event.joinPrice,
            event.type,
            imagePath: fullImageUrl, // Pass the image URL
          );
          print("Event created with image: $fullImageUrl");
        }
      } else {
        print("Error during upload: ${response.statusCode}");
      }
    } catch (e) {
      print('Error during image upload: $e');
    }
  }

  Future<String?> generateEventPoster(String description, Event event) async {
    setState(() {
      isGeneratingImage = true; // Affiche le message de génération
    });

    // Afficher un Dialog pour indiquer que l'image est en train de se générer
    showDialog(
      context: context,
      barrierDismissible: false, // Empêche de fermer le dialog avant la fin
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: <Widget>[
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Image generation in progress...'),
            ],
          ),
        );
      },
    );

    try {
      print("Génération du poster pour l'événement : ${event.title}");

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/ai/generate-poster-flux'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "description": description,
          "title": event.title,
          "startDate": event.startDate.toIso8601String(),
          "endDate": event.endDate.toIso8601String(),
          "location": event.location,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Réponse de l'API reçue.");
        final base64Image = jsonDecode(response.body)['image'];
        await _uploadGeneratedImage(base64Image, event);
        return base64Image;
      } else {
        print("Erreur API : ${response.statusCode}");
      }
    } catch (e) {
      print("Erreur réseau : $e");
    }

    setState(() {
      isGeneratingImage = false; // Arrêter d'afficher le message
    });

    // Fermer le Dialog après avoir reçu l'image
    Navigator.of(context).pop();

    return null;
  }

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.locality}, ${place.country}";
      }
    } catch (e) {
      print("Erreur de géocodage : $e");
    }
    return "Adresse inconnue";
  }

  Future<void> _showCreateEventDialog() async {
    String title = '', description = '', location = '';
    DateTime? startDate, endDate;
    int joinPrice = 5;
    String selectedType = _eventTypes.first;
    TextEditingController locationController = TextEditingController();
    bool _useAutoLocation = false;

    Future<void> _getLocation() async {
      try {
        final pos = await Geolocator.getCurrentPosition();
        final address = await getAddressFromLatLng(pos.latitude, pos.longitude);
        setState(() {
          location = "${pos.latitude},${pos.longitude}";
          locationController.text = address;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Geolocation error")),
        );
      }
    }

    void _openMap() async {
      final LatLng? selected = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SelectLocationScreen()),
      );
      if (selected != null) {
        final address =
            await getAddressFromLatLng(selected.latitude, selected.longitude);
        setState(() {
          location = "${selected.latitude},${selected.longitude}";
          locationController.text = address;
        });
      }
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Create an event"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(labelText: "Title"),
                onChanged: (v) => title = v,
              ),
              TextField(
                decoration: InputDecoration(labelText: "Description"),
                onChanged: (v) => description = v,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Use my location"),
                  Switch(
                    value: _useAutoLocation,
                    onChanged: (v) {
                      setState(() {
                        _useAutoLocation = v;
                        if (v) _getLocation();
                      });
                    },
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextField(
                      controller: locationController,
                      readOnly: true,
                      decoration:
                          InputDecoration(labelText: "Location (address)"),
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.map),
                    label: Text("Map"),
                    onPressed: _openMap,
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    ),
                  ),
                ],
              ),
              TextField(
                decoration: InputDecoration(labelText: "Participation fee"),
                keyboardType: TextInputType.number,
                onChanged: (v) => joinPrice = int.tryParse(v) ?? 5,
              ),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(labelText: "Event type"),
                items: _eventTypes
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                onChanged: (v) => selectedType = v!,
              ),
              ElevatedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      startDate = DateTime(date.year, date.month, date.day,
                          time.hour, time.minute);
                    }
                  }
                },
                child: Text("Choose start date and time"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      endDate = DateTime(date.year, date.month, date.day,
                          time.hour, time.minute);
                    }
                  }
                },
                child: Text("Choose end date and time"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Ensure the dialog is dismissed
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (title.isNotEmpty &&
                  location.isNotEmpty &&
                  startDate != null &&
                  endDate != null) {
                await generateEventPoster(
                  description,
                  Event(
                    id: '',
                    title: title,
                    description: description,
                    creatorId: widget.userId,
                    startDate: startDate!,
                    endDate: endDate!,
                    location: LatLng(
                      double.parse(location.split(',')[0]),
                      double.parse(location.split(',')[1]),
                    ),
                    participants: [],
                    isParticipating: false,
                    joinPrice: joinPrice,
                    conversationId: '',
                    type: selectedType,
                  ),
                );

                Navigator.pop(context); // Close the create event dialog
                await _loadUserEvents(widget.userId, widget.token);

                // Show success dialog directly
                Future.delayed(Duration.zero, () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text(
                        "Let’s Get This Party Started! 🎉",
                        style: TextStyle(fontSize: 18), // Adjusted font size
                      ),
                      content: const Text(
                          "Event created! You scored 5 coins for your awesome effort! 💥"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close the success dialog
                            Navigator.pop(
                                context); // Ensure all dialogs are closed
                          },
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Please fill out all the fields.")),
                );
              }
            },
            child: Text("Create"),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final hasImage = event.imagePath != null && event.imagePath!.isNotEmpty;

    return InkWell(
      onTap: () async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailsScreen(
              event: event,
              userId: widget.userId,
              token: widget.token,
              eventProvider: eventProvider,
            ),
          ),
        );
        await _loadUserEvents(widget.userId, widget.token);
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              Image.network(
                '${ApiConstants.baseUrl}' + event.imagePath!,
                height: 500,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(event.description),
                  SizedBox(height: 4),
                  FutureBuilder<String>(
                    future: getAddressFromLatLng(
                      event.location.latitude,
                      event.location.longitude,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text("Location error");
                      } else if (snapshot.hasData) {
                        return Text("📍 ${snapshot.data}");
                      } else {
                        return Text("📍 Unknown location");
                      }
                    },
                  ),
                  SizedBox(height: 4),
                  Text(
                      "📅 ${event.startDate.toLocal().toString().split(' ')[0]}"),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (event.isParticipating) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GroupChatScreen(
                                  eventProvider:
                                      EventProvider(userId: widget.userId),
                                  conversationId: event.conversationId,
                                  groupName: event.title,
                                  userId: widget.userId,
                                ),
                              ),
                            );
                          } else {
                            eventProvider.joinEvent(widget.userId, event.id);
                          }
                        },
                        child: Text(event.isParticipating ? "Chat" : "Join"),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Sure About That?"),
                              content: Text(
                                  "Poof! This event will be gone forever. Are you sure?"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, false); // Cancel
                                  },
                                  child: Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, true); // Confirm
                                  },
                                  child: Text("Delete"),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await eventProvider.deleteEvent(event.id);
                            await _loadUserEvents(widget.userId, widget.token);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Events"),
        backgroundColor: Color(0xFFDBD9FE),
      ),
      body: userEvents.isEmpty
          ? Center(child: Text("No events yet."))
          : ListView.builder(
              itemCount: userEvents.length,
              itemBuilder: (context, index) =>
                  _buildEventCard(userEvents[index]),
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
            bottom: 40.0), // Adjusted padding to raise the button
        child: FloatingActionButton(
          onPressed: () async {
            await _showCreateEventDialog(); // Wait for the dialog to close
          },
          backgroundColor: Color(0xFFD4F98F),
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
