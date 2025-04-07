import 'package:flutter/material.dart';
import 'package:projet_pim/Model/carnet.dart';
import 'package:projet_pim/View/carnet&place/EditPlace.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Details extends StatefulWidget {
  final Place place;

  const Details({required this.place, Key? key}) : super(key: key);

  @override
  _DetailsState createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  late Place place;

  @override
  void initState() {
    super.initState();
    place = widget.place;
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
        title: Text(place.name),
        backgroundColor: const Color(0xFFDBD9FE),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom du lieu
            Text(
              place.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Afficher l'album photo avec un défilement horizontal
            place.images.isNotEmpty
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: place.images.map((imageUrl) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              imageUrl,
                              width: 150, // Set a fixed width for the images
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : const Placeholder(
                    fallbackHeight: 200,
                    fallbackWidth: double.infinity,
                  ),
            const SizedBox(height: 16),

            // Description du lieu
            Text(
              place.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),

            // FlutterMap pour afficher la localisation
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
                  center: LatLng(place.latitude ?? 0.0, place.longitude ?? 0.0),
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
                        point: LatLng(
                            place.latitude ?? 0.0, place.longitude ?? 0.0),
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

            // Bouton pour ouvrir la localisation dans Google Maps
            ElevatedButton(
              onPressed: () {
                if (place.latitude != null && place.longitude != null) {
                  _openInGoogleMaps(place.latitude!, place.longitude!);
                }
              },
              child: const Text("Ouvrir dans Google Maps"),
            ),
          ],
        ),
      ),

      // Ajout du bouton d'édition
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Ouvrir la page d'édition et attendre la réponse
          final updatedPlace = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditPlace(place: place),
            ),
          );

          // Si la place a été mise à jour, actualiser l'état
          if (updatedPlace != null) {
            setState(() {
              place = updatedPlace;
            });
          }
        },
        backgroundColor: const Color(0xFFD4F98F),
        child: const Icon(Icons.edit),
      ),
    );
  }
}
