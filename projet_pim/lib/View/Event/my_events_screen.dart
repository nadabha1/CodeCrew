import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/View/chat/group_chat_screen.dart';
import 'package:projet_pim/View/select_location_screen.dart';
import 'package:provider/provider.dart';

class MyEventsScreen extends StatefulWidget {
  final String userId;
  final String token;

  const MyEventsScreen({super.key, required this.userId, required this.token});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  late EventProvider eventProvider;
  final List<String> _eventTypes = [
    "Concerts", "Workshops", "Networking Events", "Sports Activities",
    "Cultural Festivals", "Tech Meetups", "Art Exhibitions", "Other"
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      eventProvider = Provider.of<EventProvider>(context, listen: false);
      _loadUserEvents();
    });
  }

  Future<void> _loadUserEvents() async {
    await eventProvider.fetchSpecificEvents(widget.userId);
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

  void _showCreateEventDialog() {
    String title = '', description = '', location = '';
    DateTime? startDate, endDate;
    int joinPrice = 5;
    String selectedType = _eventTypes.first;
    TextEditingController locationController = TextEditingController();
    bool useAutoLocation = false;

    Future<void> getLocation() async {
      try {
        final pos = await Geolocator.getCurrentPosition();
        final address = await getAddressFromLatLng(pos.latitude, pos.longitude);
        setState(() {
          location = "${pos.latitude},${pos.longitude}";
          locationController.text = address;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur de géolocalisation")),
        );
      }
    }

    void openMap() async {
      final LatLng? selected = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SelectLocationScreen()),
      );
      if (selected != null) {
        final address = await getAddressFromLatLng(selected.latitude, selected.longitude);
        setState(() {
          location = "${selected.latitude},${selected.longitude}";
          locationController.text = address;
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Créer un événement"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Titre"),
                onChanged: (v) => title = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Description"),
                onChanged: (v) => description = v,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Utiliser ma localisation automatique"),
                  Switch(
                    value: useAutoLocation,
                    onChanged: (v) {
                      setState(() {
                        useAutoLocation = v;
                        if (v) getLocation();
                      });
                    },
                  )
                ],
              ),
              TextField(
                controller: locationController,
                readOnly: true,
                decoration: const InputDecoration(labelText: "Localisation (adresse)"),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text("Choisir sur la carte"),
                onPressed: openMap,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Prix de participation"),
                keyboardType: TextInputType.number,
                onChanged: (v) => joinPrice = int.tryParse(v) ?? 5,
              ),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: "Type d'événement"),
                items: _eventTypes.map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                )).toList(),
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
                      startDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                    }
                  }
                },
                child: const Text("Choisir date et heure de début"),
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
                      endDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                    }
                  }
                },
                child: const Text("Choisir date et heure de fin"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          TextButton(
            onPressed: () async {
              if (title.isNotEmpty && location.isNotEmpty && startDate != null && endDate != null) {
                await eventProvider.createEvent(
                  widget.userId,
                  title,
                  description,
                  startDate!.toIso8601String(),
                  endDate!.toIso8601String(),
                  location,
                  joinPrice,
                  selectedType,
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Remplissez tous les champs.")),
                );
              }
            },
            child: const Text("Créer"),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      child: ListTile(
        title: Text(event.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.description),
            Text("📍 ${event.location.latitude}, ${event.location.longitude}"),
            Text("📅 ${event.startDate.toLocal().toString().split(' ')[0]}"),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            if (event.isParticipating) {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => GroupChatScreen(
                                                    eventProvider: EventProvider(userId: widget.userId),
                  conversationId: event.conversationId,
                  groupName: event.title,
                ),
              ));
            } else {
              eventProvider.joinEvent(widget.userId, event.id);
            }
          },
          child: Text(event.isParticipating ? "Chat" : "Rejoindre"),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEvents = Provider.of<EventProvider>(context).userEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes événements"),
        backgroundColor: const Color(0xFFDBD9FE),
      ),
      body: userEvents.isEmpty
          ? const Center(child: Text("Aucun événement pour l’instant."))
          : ListView.builder(
              itemCount: userEvents.length,
              itemBuilder: (context, index) => _buildEventCard(userEvents[index]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateEventDialog,
        backgroundColor: const Color(0xFFD4F98F),
        child: const Icon(Icons.add),
      ),
    );
  }
}
