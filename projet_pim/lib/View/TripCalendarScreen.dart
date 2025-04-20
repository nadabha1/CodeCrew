import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class TripCalendarScreen extends StatelessWidget {
  final List<Map<String, dynamic>> itinerary;

  const TripCalendarScreen({required this.itinerary, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Appointment> events = itinerary.expand<Appointment>((day) {
      final date = DateTime.parse(day['date']);
      final activities = List<String>.from(day['activities']);

      return activities.map((activity) {
        final hour = _extractHourFromText(activity) ?? 9;
        final color = _getColorByTime(hour);

        return Appointment(
          startTime: date.add(Duration(hours: hour)),
          endTime: date.add(Duration(hours: hour + 1)),
          subject: activity.length > 60 ? activity.substring(0, 60) + '...' : activity,
          notes: activity,
          color: color,
        );
      }).toList();
    }).toList();

    final DateTime? minDate = itinerary.isNotEmpty ? DateTime.parse(itinerary.first['date']) : null;
    final DateTime? maxDate = itinerary.isNotEmpty ? DateTime.parse(itinerary.last['date']).add(const Duration(days: 1)) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Calendar View'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _LegendBadge(color: Colors.orange, label: 'Morning'),
                _LegendBadge(color: Colors.green, label: 'Afternoon'),
                _LegendBadge(color: Colors.indigo, label: 'Evening'),
                _LegendBadge(color: Colors.blueGrey, label: 'Night'),
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
                if (details.appointments != null && details.appointments!.isNotEmpty) {
                  final Appointment appt = details.appointments!.first;
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(appt.subject),
                      content: Text(appt.notes ?? ''),
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
    final regex = RegExp(r'(\d{1,2}):(\d{2})');
    final match = regex.firstMatch(text);
    if (match != null) {
      final hour = int.tryParse(match.group(1)!);
      return hour;
    }

    final lower = text.toLowerCase();
    if (lower.contains("morning")) return 9;
    if (lower.contains("lunch")) return 13;
    if (lower.contains("afternoon")) return 15;
    if (lower.contains("evening")) return 18;
    if (lower.contains("night")) return 21;
    return null;
  }

  Color _getColorByTime(int hour) {
    if (hour < 12) return Colors.orange;         // Morning
    if (hour < 17) return Colors.green;          // Afternoon
    if (hour < 20) return Colors.indigo;         // Evening
    return Colors.blueGrey;                      // Night
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

  const _LegendBadge({required this.color, required this.label, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
