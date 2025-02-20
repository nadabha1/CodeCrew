import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:projet_pim/Model/carnet.dart';

class PlaceDetailsScreen extends StatelessWidget {
  final Place place;

  const PlaceDetailsScreen({required this.place});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(place.name), // Utilisation de place.name
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(
                    place.latitude ?? 0.0,
                    place.longitude ??
                        0.0), // Utilisation des coordonnées de place
                zoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                          place.latitude ?? 0.0,
                          place.longitude ??
                              0.0), // Utilisation des coordonnées de place
                      width: 40,
                      height: 40,
                      child:
                          Icon(Icons.location_pin, size: 40, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(place.description,
                style: TextStyle(
                    fontSize: 16)), // Utilisation de place.description
          ),
        ],
      ),
    );
  }
}
