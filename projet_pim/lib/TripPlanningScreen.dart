/*import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
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
        const SnackBar(content: Text('Please enter destination and select date range')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _showResults = false;
    });

    final dateOnlyFormat = DateFormat('yyyy-MM-dd');

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/trip/generate'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
                child: Text("• $activity", style: const TextStyle(fontSize: 14)),
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
          color: Colors.blue.shade50,
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
                      color: Colors.blue,
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
        foregroundColor: Colors.blue.shade800,
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
                        onPressed: () => generateTripPlan(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Generate My Itinerary'),
                      ),
                    ),
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
        startDate: DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start),
        endDate: DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end),
        userId: widget.userId,
      ),
    ),
  );
},
                icon: const Icon(Icons.calendar_month),
                label: const Text('View in Calendar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => generateTripPlan(regenerate: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Regenerate a New Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
*/
