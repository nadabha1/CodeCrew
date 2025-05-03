import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:projet_pim/Model/event.dart';
import 'package:intl/intl.dart';
import 'package:projet_pim/View/select_location_screen.dart';

class EditEventScreen extends StatefulWidget {
  final Event event;
  final Function(Event) onSave;

  const EditEventScreen({super.key, required this.event, required this.onSave});

  @override
  _EditEventScreenState createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController locationController;
  late DateTime startDate;
  late DateTime endDate;
  String location = ''; // Initialize as an empty string
  bool _useAutoLocation = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.event.title);
    descriptionController =
        TextEditingController(text: widget.event.description);
    locationController = TextEditingController(
        text:
            "${widget.event.location.latitude},${widget.event.location.longitude}");
    startDate = widget.event.startDate;
    endDate = widget.event.endDate;
    location =
        "${widget.event.location.latitude},${widget.event.location.longitude}"; // Initialize with event's coordinates
    _setInitialLocationAddress();
  }

  Future<void> _setInitialLocationAddress() async {
    String address = await getAddressFromLatLng(
      widget.event.location.latitude,
      widget.event.location.longitude,
    );

    setState(() {
      locationController.text = address;
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != startDate) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(startDate),
      );

      if (pickedTime != null) {
        setState(() {
          startDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (endDate.isBefore(startDate)) {
            endDate = startDate.add(const Duration(hours: 1));
          }
        });
      }
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate,
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != endDate) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(endDate),
      );

      if (pickedTime != null) {
        setState(() {
          endDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _saveChanges() {
    if (titleController.text.isNotEmpty &&
        location.isNotEmpty &&
        endDate.isAfter(startDate)) {
      // Convert the location string back to a LatLng object
      List<String> coords = location.split(',');
      LatLng latLngLocation = LatLng(
        double.parse(coords[0]),
        double.parse(coords[1]),
      );

      // Create an updated Event object
      Event updatedEvent = Event(
        id: widget.event.id,
        title: titleController.text,
        description: descriptionController.text,
        creatorId: widget.event.creatorId,
        startDate: startDate,
        endDate: endDate,
        location: latLngLocation, // Pass the LatLng object
        participants: widget.event.participants,
        isParticipating: widget.event.isParticipating,
        joinPrice: widget.event.joinPrice,
        conversationId: widget.event.conversationId,
        type: widget.event.type,
      );

      // Pass the updated Event object to the onSave callback
      widget.onSave(updatedEvent);

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please ensure all fields are filled out correctly."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  Future<String> getAddressFromStringCoords(String coords) async {
    try {
      final parts = coords.split(',');
      if (parts.length != 2) return "Invalid coordinates";

      final lat = double.parse(parts[0]);
      final lng = double.parse(parts[1]);
      return await getAddressFromLatLng(lat, lng);
    } catch (e) {
      print("Erreur lors de la conversion des coordonnées : $e");
      return "Unknown loaction";
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
    return "Unknown loaction";
  }

  // Fonction pour obtenir la localisation automatique et l'afficher dans le TextField
  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String address =
          await getAddressFromLatLng(position.latitude, position.longitude);

      setState(() {
        location =
            "${position.latitude},${position.longitude}"; // Store only the coordinates
        locationController.text = address; // Display the address
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to retrieve the location!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fonction pour ouvrir la carte et sélectionner une localisation
  void _openMapToSelectLocation() async {
    LatLng? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SelectLocationScreen()),
    );

    if (selectedLocation != null) {
      String address = await getAddressFromLatLng(
          selectedLocation.latitude, selectedLocation.longitude);

      setState(() {
        location =
            "${selectedLocation.latitude},${selectedLocation.longitude}"; // Store only the coordinates
        locationController.text = address; // Display the address
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Event", style: TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFFEDE7F6),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              _buildTextField(titleController, "Title"),
              const SizedBox(height: 16),
              _buildTextField(descriptionController, "Description",
                  maxLines: 3),
              const SizedBox(height: 16),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Use my location"),
                  Switch(
                    value: _useAutoLocation,
                    onChanged: (value) {
                      setState(() {
                        _useAutoLocation = value;
                        if (value) _getLocation();
                      });
                    },
                    activeColor:
                        const Color(0xFFE8EAF6), // couleur du curseur activé
                    activeTrackColor:
                        const Color(0xFF161055), // couleur de la piste activée
                    inactiveThumbColor: Colors.grey, // curseur désactivé
                    inactiveTrackColor: const Color.fromARGB(
                        66, 161, 161, 161), // piste désactivée
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                          labelText: "Location (address)"),
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(
                      width: 8), // Ajout d'un petit espace entre les éléments
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text("Map"),
                    onPressed: _openMapToSelectLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 220, 168, 227),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDateRow("start", startDate, _selectStartDate),
              const SizedBox(height: 16),
              _buildDateRow("end", endDate, _selectEndDate),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      maxLines: maxLines,
    );
  }

  Widget _buildDateRow(
      String label, DateTime date, Function(BuildContext) onTap) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(date),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.calendar_today,
                color: Theme.of(context).primaryColor),
            onPressed: () => onTap(context),
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 220, 168, 227),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text("Save",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
