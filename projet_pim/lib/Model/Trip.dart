class Trip {
  final String id;
  final String userId;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final List<Map<String, dynamic>> itinerary;
  final String status;
  final int numberOfDays;
  final int totalActivities;

  Trip({
    required this.id,
    required this.userId,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.itinerary,
    required this.status,
    required this.numberOfDays,
    required this.totalActivities,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['_id'],
      userId: json['userId'],
      destination: json['destination'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      itinerary: List<Map<String, dynamic>>.from(json['itinerary']),
      status: json['status'],
      numberOfDays: json['numberOfDays'],
      totalActivities: json['totalActivities'],
    );
  }
}
