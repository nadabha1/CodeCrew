import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'package:projet_pim/Model/trip.dart';
import 'package:projet_pim/View/TripCalendarScreen.dart';
import 'package:projet_pim/View/tripdetails.dart'; // For the TripCalendarScreen page

class MyTripsScreen extends StatelessWidget {
  final List<Trip> trips;

  MyTripsScreen({required this.trips});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My trips'),
      ),
      body: trips.isEmpty
          ? const Center(
              child: Text('No trips Found'),
            )
          : ListView.builder(
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16), // Added horizontal padding
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 10), // Reduced margin
                    decoration: BoxDecoration(
                      color: Colors.white, // Set background to white
                      borderRadius:
                          BorderRadius.circular(20), // Adjusted border radius
                      border: Border.all(
                        color: Color(0xFF1A1055), // Border color
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurpleAccent.withOpacity(0.2),
                          blurRadius: 4, // Reduced blur radius
                          offset: Offset(0, 2), // Adjusted shadow offset
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.all(12), // Reduced padding
                      leading: CircleAvatar(
                        radius: 25, // Reduced size
                        backgroundColor: Color(0xFF1A1055),
                        child: Icon(Icons.flight_takeoff,
                            color: Colors.white,
                            size: 24), // Adjusted icon size
                      ),
                      title: Text(
                        trip.destination,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16, // Reduced font size
                          color: Color(0xFF1A1055), // Text color
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2), // Reduced spacing
                          Text(
                            '🗓️ ${DateFormat.yMMMd().format(trip.startDate)} - ${DateFormat.yMMMd().format(trip.endDate)}',
                            style: const TextStyle(
                                color: Color(0xFF1A1055),
                                fontSize: 14), // Adjusted font size
                          ),
                          const SizedBox(height: 2), // Reduced spacing
                          Text(
                            '🎯 ${trip.totalActivities} activities • ${trip.numberOfDays} days',
                            style: const TextStyle(
                                color: Color(0xFF1A1055),
                                fontSize: 14), // Adjusted font size
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Color(0xFF1A1055),
                          size: 18), // Reduced icon size
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripDetailsScreen(
                              itinerary: trip.itinerary,
                              destination: trip.destination,
                              startDate: trip.startDate.toIso8601String(),
                              endDate: trip.endDate.toIso8601String(),
                              userId: trip
                                  .userId, // Adjust to match the userId in your trip model
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
