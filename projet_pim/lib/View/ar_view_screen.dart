import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../Model/carnet.dart';

class ARViewScreen extends StatefulWidget {
  final Place userPlace;
  final List<Place> nearbyPlaces;
  final bool isMockMode;

  const ARViewScreen({
    Key? key,
    required this.userPlace,
    required this.nearbyPlaces,
    this.isMockMode = true,
  }) : super(key: key);

  @override
  _ARViewScreenState createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen> {
  late Place currentUserPlace;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    currentUserPlace = widget.userPlace;
    if (!widget.isMockMode) {
      _errorMessage = 'Real AR not available in mock mode';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isMockMode ? 'AR Explorer (Mock)' : 'AR Explorer'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updateMarkers,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Mock AR View
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 50, color: Colors.blue),
              const SizedBox(height: 20),
              ...widget.nearbyPlaces
                  .where((place) => place.coordinates != null)
                  .map(_buildPlaceCard)
                  .toList(),
            ],
          ),
        ),
        _buildDebugInfo(),
      ],
    );
  }

  Widget _buildPlaceCard(Place place) {
    final distance = _calculateDistance(
      currentUserPlace.coordinates!,
      place.coordinates!,
    );

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white.withOpacity(0.8),
      child: ListTile(
        leading: Icon(
          Icons.location_pin,
          color: _getPlaceColor(place),
          size: 40,
        ),
        title: Text(
          place.name,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${distance.toStringAsFixed(1)} meters away',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Color _getPlaceColor(Place place) {
    if (place.unlockCost > 0) return Colors.orange;
    return place.categories.contains('restaurant') ? Colors.red : Colors.blue;
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const latToMeters = 111320.0;
    final dx = (end.latitude - start.latitude) * latToMeters;
    final dy = (end.longitude - start.longitude) * latToMeters;
    return sqrt(dx * dx + dy * dy);
  }

  Widget _buildDebugInfo() {
    return Positioned(
      bottom: 10,
      left: 10,
      child: FloatingActionButton(
        onPressed: () {
          // Show more detailed debug info if needed
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.info_outline),
      ),
    );
  }

  void _updateMarkers() {
    setState(() {
      // Simulate location update in mock mode
      if (widget.isMockMode) {
        currentUserPlace = currentUserPlace.copyWith(
          latitude: currentUserPlace.coordinates!.latitude + 0.001,
          longitude: currentUserPlace.coordinates!.longitude + 0.001,
        );
      }
    });
  }
}
