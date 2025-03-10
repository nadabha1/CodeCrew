import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'package:projet_pim/View/Event/EventDetailsScreen.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';

class AllEventsScreen extends StatefulWidget {
  final String userId;
  final String token;

  const AllEventsScreen({Key? key, required this.userId, required this.token}) : super(key: key);

  @override
  _AllEventsScreenState createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  List<Event> _events = [];
  bool _isLoading = true;
  late EventProvider _eventProvider;  // 🟢 Créer un `EventProvider` valide

  @override
  void initState() {
    super.initState();
    _eventProvider = EventProvider(userId: widget.userId);  // 🟢 Initialiser `EventProvider`
    _fetchAllEvents();
  }

  Future<void> _fetchAllEvents() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/events/all'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _events = data.map((json) => Event.fromJson(json, widget.userId)).toList();
          _isLoading = false;
        });
      } else {
        print('🔴 Erreur: ${response.body}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('🔴 Exception: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tous les événements")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                return ListTile(
                  title: Text(event.title),
                  subtitle: Text(event.description),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailsScreen(
                          event: event,
                          userId: widget.userId,
                          token: widget.token,
                          eventProvider: _eventProvider,  // 🟢 Passer un `EventProvider` valide
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
