import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projet_pim/View/Event/EventDetailsScreen.dart';
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/Providers/event_provider.dart';

class EventCardMessage extends StatelessWidget {
  final Event event;
  final String userId;
  final String token;
  final EventProvider eventProvider;

  const EventCardMessage({
    Key? key,
    required this.event,
    required this.userId,
    required this.token,
    required this.eventProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Naviguer vers l’écran des détails de l’événement
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailsScreen(
              event: event,
              userId: userId,
              token: token,
              eventProvider: eventProvider,
            ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        color: Color(0xFFEEF1FD),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("📢 ${event.title}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 6),
              Text("📍 ${event.location.latitude.toStringAsFixed(4)}, ${event.location.longitude.toStringAsFixed(4)}"),
              Text("📅 Début : ${DateFormat('dd MMM yyyy, HH:mm').format(event.startDate)}"),
              Text("👥 Participants : ${event.participants.length}"),
              SizedBox(height: 4),
              Text("➡️ Cliquez pour voir plus de détails", style: TextStyle(color: Colors.blue)),
            ],
          ),
        ),
      ),
    );
  }
}
