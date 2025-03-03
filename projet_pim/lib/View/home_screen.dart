import 'package:flutter/material.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/View/carnet&place/AddPlaceScreenStep1.dart';
import 'package:projet_pim/View/carnet&place/PlaceDetailsScreen.dart';
import 'package:projet_pim/View/carnet&place/carnet_dtetails_screen.dart';
import 'package:projet_pim/View/profile.dart';
import 'package:provider/provider.dart';
import '../Providers/carnet_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:projet_pim/ViewModel/user_service.dart';
import 'package:projet_pim/Model/event.dart';
import 'package:projet_pim/Providers/event_provider.dart';
import 'event_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  CarnetProvider? carnetProvider;
  EventProvider? eventProvider;
  List<dynamic> users = [];
  bool isLoadingUsers = true;
  late AnimationController _cardAnimationController;
  late Animation<double> _cardFadeAnimation;

  void _reloadData() async {
    if (carnetProvider != null && eventProvider != null) {
      await carnetProvider!.fetchCarnetsExcludingUser(widget.userId);
      await carnetProvider!.fetchUnlockedPlaces(widget.userId);
      await fetchUsers();
      await eventProvider!.fetchAllEvents();
      if (mounted) setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    carnetProvider ??= Provider.of<CarnetProvider>(context, listen: false);
    eventProvider ??= Provider.of<EventProvider>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _cardFadeAnimation = CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeInOut);
    _cardAnimationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadData());
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    carnetProvider = null;
    eventProvider = null;
    super.dispose();
  }

  Future<void> fetchUsers() async {
    try {
      UserService userService = UserService();
      List<dynamic> fetchedUsers = await userService.getAllUsers(widget.userId);
      setState(() {
        users = fetchedUsers;
        isLoadingUsers = false;
      });
    } catch (e) {
      print("Error fetching users: $e");
      setState(() => isLoadingUsers = false);
    }
  }

  void _showCreateEventDialog() {
    String title = '';
    String description = '';
    DateTime date = DateTime.now();
    String location = '';
    int joinPrice = 5; // Default join price

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Title'),
                onChanged: (value) => title = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Description'),
                onChanged: (value) => description = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Location'),
                onChanged: (value) => location = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Join Price (coins)'),
                keyboardType: TextInputType.number,
                onChanged: (value) => joinPrice = int.tryParse(value) ?? 5,
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  ) ?? date;
                },
                child: Text('Pick Date'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (title.isNotEmpty && location.isNotEmpty) {
                eventProvider!.createEvent(widget.userId, title, description, date, location, joinPrice);
                Navigator.pop(context);
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showUnlockDialog(String placeName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Success!"),
          content: Text("You have successfully unlocked $placeName!"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmUnlockDialog(String placeName, int placePrice, place) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Payment Confirmation"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Do you want to unlock '$placeName'?"),
              SizedBox(height: 10),
              Text("Price to unlock: $placePrice coins"),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await carnetProvider!.unlockPlace(widget.userId, place.id);
                  _showUnlockDialog(placeName);
                  _reloadData();
                } catch (e) {
                  _showErrorDialog(e.toString());
                }
              },
              child: Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  void _openInGoogleMaps(double latitude, double longitude) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _showJoinConfirmationDialog(Event event) {
    showDialog(
      context: context, // Now defined within the class
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Join Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Do you want to join "${event.title}"?'),
              SizedBox(height: 10),
              Text('Join Price: ${event.joinPrice} coins'), // Display join price
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                eventProvider!.joinEvent(widget.userId, event.id); // Now eventProvider is accessible
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final carnetProvider = Provider.of<CarnetProvider>(context, listen: true);
    final eventProvider = Provider.of<EventProvider>(context, listen: true);
    final otherCarnets = carnetProvider.carnets.where((c) => c.owner != widget.userId).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FC),
      body: SafeArea(
        child: eventProvider.isLoading || carnetProvider.isLoading || isLoadingUsers
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFFDBD9FE),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.menu, color: Colors.black, size: 28),
                            CircleAvatar(
                              backgroundImage: AssetImage('assets/default_profile.png'),
                              radius: 22,
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Hey User!",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Where's your next trip going to be?",
                          style: TextStyle(fontSize: 16, color: Colors.brown),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  // Carnet Section
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("Near Your Location", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  otherCarnets.isEmpty
                      ? Center(child: Text("No other carnets available"))
                      : Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Other Carnets",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: otherCarnets.length,
                                itemBuilder: (context, index) {
                                  final carnet = otherCarnets[index];
                                  return Card(
                                    margin: EdgeInsets.symmetric(vertical: 10),
                                    child: ExpansionTile(
                                      title: Text(
                                        carnet.title,
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      children: carnet.places.map((place) {
                                        bool isUnlocked = carnetProvider.isPlaceUnlocked(place.id);
                                        return ListTile(
                                          title: Text(place.name),
                                          subtitle: Text(place.description),
                                          leading: Icon(
                                            isUnlocked ? Icons.lock_open : Icons.lock,
                                            color: isUnlocked ? Colors.green : Colors.red,
                                          ),
                                          trailing: ElevatedButton(
                                            onPressed: isUnlocked
                                                ? null
                                                : () => _showConfirmUnlockDialog(place.name, place.unlockCost, place),
                                            child: Text(
                                              "Unlock (5 coins)",
                                              style: TextStyle(color: Colors.black),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isUnlocked
                                                  ? const Color(0xFF9E9E9E)
                                                  : const Color(0xFFD4F98F),
                                              foregroundColor: Colors.black,
                                            ),
                                          ),
                                          onTap: isUnlocked
                                              ? () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => PlaceDetailsScreen(place: place),
                                                    ),
                                                  );
                                                }
                                              : null,
                                          onLongPress: () {
                                            if (place.latitude != null && place.longitude != null) {
                                              _openInGoogleMaps(place.latitude!, place.longitude!);
                                            }
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                      ),

                  // Events Section
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Upcoming Events", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: _showCreateEventDialog,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  eventProvider.events.isEmpty
                      ? Center(child: Text("No events available"))
                      : SizedBox(
                          height: 200, // Fixed height for the carousel
                          child: FadeTransition(
                            opacity: _cardFadeAnimation,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              itemCount: eventProvider.events.length,
                              itemBuilder: (context, index) {
                                final event = eventProvider.events[index];
                                print('Event: ${event.title}, isParticipating: ${event.isParticipating}');
                                return Padding(
                                  padding: EdgeInsets.only(right: 10),
                                  child: Card(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Container(
                                      width: 300,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Text(
                                              event.title,
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 12),
                                            child: Text(
                                              event.description,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.white70,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 12),
                                            child: Text(
                                              'Date: ${event.date.toLocal().toString().split(' ')[0]}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white54,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 12),
                                            child: Text(
                                              'Location: ${event.location}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white54,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 12),
                                            child: Text(
                                              'Participants: ${event.participants.length}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white54,
                                              ),
                                            ),
                                          ),
                                          Spacer(),
                                          Align(
                                            alignment: Alignment.bottomCenter,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                if (event.isParticipating) {
                                                  Navigator.pushNamed(
                                                    context,
                                                    '/event-chat',
                                                    arguments: event.id,
                                                  );
                                                } else {
                                                  _showJoinConfirmationDialog(event); // Show confirmation dialog
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: event.isParticipating ? Color(0xFF50E3C2) : Color(0xFFF4A261),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.only(
                                                    bottomLeft: Radius.circular(15),
                                                    bottomRight: Radius.circular(15),
                                                  ),
                                                ),
                                                padding: EdgeInsets.symmetric(vertical: 10),
                                              ),
                                              child: Text(
                                                event.isParticipating ? 'Chat' : 'Join',
                                                style: TextStyle(fontSize: 16, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                  // Users Section
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Find Your Similar Traveler",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 10),
                  isLoadingUsers
                      ? const Center(child: CircularProgressIndicator())
                      : users.isEmpty
                          ? Center(child: Text("No travelers found"))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TravelerProfileScreen(
                                          travelerId: user['_id'],
                                          loggedInUserId: widget.userId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    title: Text(user['name']),
                                    subtitle: Text(user['email']),
                                    leading: CircleAvatar(
                                      backgroundImage: user['profileImageUrl'] != null &&
                                              user['profileImageUrl'].isNotEmpty
                                          ? NetworkImage(user['profileImageUrl'])
                                          : AssetImage('assets/default_profile.png') as ImageProvider,
                                    ),
                                  ),
                                );
                              },
                            ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 248, 214, 253),
        child: Icon(Icons.add),
        onPressed: () async {
          await carnetProvider!.checkUserCarnet(widget.userId);
          if (carnetProvider!.userCarnet == null || !carnetProvider!.userCarnet!['hasCarnet']) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateCarnetScreen(userId: widget.userId),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddPlaceScreenStep1(
                  carnetId: carnetProvider!.userCarnet!['carnet']['_id'],
                ),
              ),
            );
          }
        },
      ),
    );
  }

}