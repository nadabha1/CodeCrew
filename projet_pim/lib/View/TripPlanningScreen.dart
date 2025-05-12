import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'TripCalendarScreen.dart';

class TripPlanningScreen extends StatefulWidget {
  final String userId;

  const TripPlanningScreen({required this.userId, Key? key}) : super(key: key);

  @override
  _TripPlanningScreenState createState() => _TripPlanningScreenState();
}

class _TripPlanningScreenState extends State<TripPlanningScreen> {
  final _destinationController = TextEditingController();
  bool _isLoading = false;
  bool _showResults = false;
  List<dynamic> _itinerary = [];
  DateTimeRange? _selectedDateRange;
  Color primaryColor = Color(0xFF8A56AC); // violet doux
  Color secondaryColor = Color(0xFFB388FF); // violet clair
  Color accentColor = Color(0xFFFFC107); // jaune-orangé doux
  Color bgColor = Color(0xFFF9F6FF); // fond pastel

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> generateTripPlan({bool regenerate = false}) async {
    if (_destinationController.text.isEmpty || _selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter destination and select date range')),
      );
      return;
    }

    final confirmed = await showTripConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _showResults = false;
    });

    final dateOnlyFormat = DateFormat('yyyy-MM-dd');

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/trip/generate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'destination': _destinationController.text,
          'startDate': dateOnlyFormat.format(_selectedDateRange!.start),
          'endDate': dateOnlyFormat.format(_selectedDateRange!.end),
          'userId': widget.userId,
          'regenerate': regenerate, // <<< NEW: Send regenerate flag
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          _itinerary = List<Map<String, dynamic>>.from(data['itinerary']);
          _showResults = true;
        });
      } else {
        final errorMessage = data['message'] ?? 'Failed to generate plan';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error: $e');

      String errorMsg = e.toString();

      if (errorMsg.contains("Not enough coins")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "⛔ You don’t have enough coins to generate this trip.",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.grey.shade800,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> showTripConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text("Trip Generation Confirmation"),
              content: const Text(
                "Generating your trip itinerary will cost 20 coins.\nDo you want to continue?",
                style: TextStyle(fontSize: 15),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF673AB7), // Couleur texte
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple, // Couleur de fond
                    foregroundColor: Colors.white, // Couleur du texte
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text("Confirm"),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false; // si annulé
  }

  void _onDayClicked(int dayIndex) {
    final dayActivities = _itinerary[dayIndex]['activities'];
    final date = _itinerary[dayIndex]['date'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Day ${dayIndex + 1} – $date'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: dayActivities.map<Widget>((activity) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child:
                    Text("• $activity", style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryCard() {
    return ListView.builder(
      itemCount: _itinerary.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final dayActivities = _itinerary[index]['activities'];
        final shortPreview = dayActivities.take(2).join('\n');
        final date = _itinerary[index]['date'];

        return Card(
          elevation: 6,
          color: Colors.purple.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: InkWell(
            onTap: () => _onDayClicked(index),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day ${index + 1} – $date',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color.fromARGB(255, 210, 184, 251),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shortPreview + (dayActivities.length > 2 ? '\n...' : ''),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Planner'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF673AB7),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _destinationController,
                      decoration: InputDecoration(
                        labelText: 'Where to?',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _selectDateRange(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Select travel date range',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        child: Text(
                          _selectedDateRange == null
                              ? 'No date selected'
                              : '${dateFormat.format(_selectedDateRange!.start)} → ${dateFormat.format(_selectedDateRange!.end)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => generateTripPlan(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              primaryColor.withOpacity(0.6),
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text("Generate My Itinerary"),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_showResults) ...[
              _buildItineraryCard(),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TripCalendarScreen(
                        itinerary: List<Map<String, dynamic>>.from(_itinerary),
                        destination: _destinationController.text,
                        startDate: DateFormat('yyyy-MM-dd')
                            .format(_selectedDateRange!.start),
                        endDate: DateFormat('yyyy-MM-dd')
                            .format(_selectedDateRange!.end),
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_month),
                label: const Text('View in Calendar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => generateTripPlan(regenerate: true),
                icon: Icon(Icons.refresh, color: primaryColor),
                label: Text(
                  'Regenerate Plan',
                  style: TextStyle(color: primaryColor),
                ),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: primaryColor.withOpacity(0.5)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
