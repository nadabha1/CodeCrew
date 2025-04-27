import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TripPlanningScreen extends StatefulWidget {
  final String userId;

  TripPlanningScreen({required this.userId});

  @override
  _TripPlanningScreenState createState() => _TripPlanningScreenState();
}

class _TripPlanningScreenState extends State<TripPlanningScreen> {
  final _destinationController = TextEditingController();
  final _daysController = TextEditingController();
  final _budgetController = TextEditingController();
  final _preferencesController = TextEditingController();
  String _generatedPlan = '';
  bool _isLoading = false;

  Future<void> generateTripPlan() async {
    setState(() {
      _isLoading = true;
    });

    final destination = _destinationController.text;
    final days = int.parse(_daysController.text);
    final budget = int.parse(_budgetController.text);
    final preferences = _preferencesController.text;

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/trip-planning/plan'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'destination': destination,
        'days': days,
        'budget': budget,
        'preferences': preferences,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _generatedPlan = data['plan'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _generatedPlan = 'Failed to generate trip plan.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Plan Your Trip"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _destinationController,
              decoration: InputDecoration(labelText: 'Destination'),
            ),
            TextField(
              controller: _daysController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Number of Days'),
            ),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Budget'),
            ),
            TextField(
              controller: _preferencesController,
              decoration: InputDecoration(
                  labelText: 'Preferences (e.g., nature, food, etc.)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: generateTripPlan,
              child: Text('Generate Trip Plan'),
            ),
            if (_isLoading) Center(child: CircularProgressIndicator()),
            if (_generatedPlan.isNotEmpty && !_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  _generatedPlan,
                  style: TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
