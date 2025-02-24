import 'package:flutter/material.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/View/carnet&place/AddPlaceScreenStep1.dart';
import 'package:projet_pim/View/carnet&place/PlaceDetailsScreen.dart';
import 'package:projet_pim/View/carnet&place/carnet_dtetails_screen.dart';
import 'package:provider/provider.dart';
import '../Providers/carnet_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CarnetProvider? provider;

  void _reloadData() async {
    if (provider != null) {
      await provider!.fetchCarnetsExcludingUser(widget.userId);
      await provider!.fetchUnlockedPlaces(widget.userId);
      if (mounted) setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    provider ??= Provider.of<CarnetProvider>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadData());
  }

  @override
  void dispose() {
    provider = null;
    super.dispose();
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
              onPressed: () => Navigator.of(context).pop(), // Close the dialog
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                // Proceed to unlock the place
                try {
                  await provider!.unlockPlace(
                      widget.userId, place.id); // Use the instance method
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
    final carnetProvider = Provider.of<CarnetProvider>(context, listen: true);
    final otherCarnets =
        carnetProvider.carnets.where((c) => c.owner != widget.userId).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FC),
      body: SafeArea(
        child: carnetProvider.isLoading
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
                              backgroundImage:
                                  AssetImage('assets/default_profile.png'),
                              radius: 22,
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Hey User!",
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
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
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("Near Your Location",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  otherCarnets.isEmpty
                      ? Center(child: Text("No other carnets available"))
                      : Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Other Carnets",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
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
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      children: carnet.places.map((place) {
                                        bool isUnlocked = carnetProvider
                                            .isPlaceUnlocked(place.id);
                                        return ListTile(
                                          title: Text(place.name),
                                          subtitle: Text(place.description),
                                          leading: Icon(
                                            isUnlocked
                                                ? Icons.lock_open
                                                : Icons.lock,
                                            color: isUnlocked
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                          trailing: ElevatedButton(
                                            onPressed: isUnlocked
                                                ? null
                                                : () async {
                                                    _showConfirmUnlockDialog(
                                                        place.name,
                                                        place.unlockCost,
                                                        place); // Pass the place
                                                  },
                                            child: Text(
                                              "Unlock (5 coins)",
                                              style: TextStyle(
                                                  color: Colors.black),
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
                                                      builder: (context) =>
                                                          PlaceDetailsScreen(
                                                              place: place),
                                                    ),
                                                  );
                                                }
                                              : null,
                                          onLongPress: () {
                                            // Open place in Google Maps on long press
                                            if (place.latitude != null &&
                                                place.longitude != null) {
                                              _openInGoogleMaps(place.latitude!,
                                                  place.longitude!);
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
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 248, 214, 253),
        child: Icon(Icons.add),
        onPressed: () async {
          await carnetProvider.checkUserCarnet(widget.userId);
          if (carnetProvider.userCarnet == null ||
              !carnetProvider.userCarnet!['hasCarnet']) {
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
                  carnetId: carnetProvider.userCarnet!['carnet']['_id'],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
