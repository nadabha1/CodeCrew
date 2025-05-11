import 'package:flutter/material.dart';
import 'package:projet_pim/ViewModel/api_constants.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TripDetailsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> itinerary;
  final String destination;
  final String startDate;
  final String endDate;
  final String userId;

  const TripDetailsScreen({
    required this.itinerary,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  State<TripDetailsScreen> createState() => _TripCalendarScreenState();
}

class _TripCalendarScreenState extends State<TripDetailsScreen> {
  bool _isAccepting = false;



  int calculateTotalActivities() {
    int total = 0;
    for (var day in widget.itinerary) {
      total += (day['activities'] as List).length;
    }
    return total;
  }

  int calculateNumberOfDays() {
    final start = DateTime.parse(widget.startDate);
    final end = DateTime.parse(widget.endDate);
    return end.difference(start).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    final List<Appointment> events =
        widget.itinerary.expand<Appointment>((day) {
      final date = DateTime.parse(day['date']);
      final activities = List<String>.from(day['activities']);
      return activities.map((activity) {
        final hour = _extractHourFromText(activity) ?? 9;
        final color = _getColorByTime(hour);

        return Appointment(
          startTime: date.add(Duration(hours: hour)),
          endTime: date.add(Duration(hours: hour + 1)),
          subject: activity.length > 60
              ? activity.substring(0, 60) + '...'
              : activity,
          notes: activity,
          color: color,
        );
      }).toList();
    }).toList();

    final DateTime? minDate = widget.itinerary.isNotEmpty
        ? DateTime.parse(widget.itinerary.first['date'])
        : null;
    final DateTime? maxDate = widget.itinerary.isNotEmpty
        ? DateTime.parse(widget.itinerary.last['date'])
            .add(const Duration(days: 1))
        : null;

    final numberOfDays = calculateNumberOfDays();
    final totalActivities = calculateTotalActivities();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Calendar View'),
        backgroundColor: Color(0xFFDBD9FE),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Color(0xFF161055), width: 1.5),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trip Statistics 📈',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF161055))),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFF161055)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text('Destination: ${widget.destination}',
                                style: TextStyle(fontSize: 16))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Color(0xFF161055)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text('Days: $numberOfDays',
                                style: TextStyle(fontSize: 16))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: Color(0xFF161055)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text('Activities: $totalActivities',
                                style: TextStyle(fontSize: 16))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _LegendBadge(
                    color: Colors.orange,
                    label: 'Morning',
                    icon: Icons.wb_sunny),
                _LegendBadge(
                    color: Colors.green,
                    label: 'Afternoon',
                    icon: Icons.wb_cloudy),
                _LegendBadge(
                    color: Colors.indigo,
                    label: 'Evening',
                    icon: Icons.brightness_3),
                _LegendBadge(
                    color: Colors.blueGrey,
                    label: 'Night',
                    icon: Icons.nights_stay),
              ],
            ),
          ),
          Expanded(
            child: SfCalendar(
              view: CalendarView.timelineWeek,
              dataSource: AppointmentDataSource(events),
              initialDisplayDate: minDate,
              firstDayOfWeek: 1,
              showNavigationArrow: true,
              minDate: minDate,
              maxDate: maxDate,
              todayHighlightColor: Colors.red,
              allowViewNavigation: true,
              timeSlotViewSettings: const TimeSlotViewSettings(
                timeIntervalHeight: 60,
              ),
              onTap: (CalendarTapDetails details) {
                if (details.appointments != null &&
                    details.appointments!.isNotEmpty) {
                  final Appointment appt =
                      details.appointments!.first as Appointment;
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(
                        appt.subject,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: SingleChildScrollView(
                        child: Text(
                          appt.notes ?? '',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        )
                      ],
                    ),
                  );
                }
              },
            ),
          ),
         
        ],
      ),
    );
  }

  int? _extractHourFromText(String text) {
    final lower = text.toLowerCase();
    if (lower.contains("morning")) return 8;
    if (lower.contains("afternoon")) return 13;
    if (lower.contains("evening")) return 17;
    if (lower.contains("night")) return 21;
    return null;
  }

  Color _getColorByTime(int hour) {
    if (hour < 12) return Colors.orange;
    if (hour < 17) return Colors.green;
    if (hour < 20) return Colors.indigo;
    return Colors.blueGrey;
  }
}

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}

class _LegendBadge extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;

  const _LegendBadge(
      {required this.color, required this.label, required this.icon, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
