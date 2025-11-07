class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final String venue;
  final String eventType; // conference, seminar, workshop, etc.
  final String organizer;
  final DateTime createdAt;
  final String status;
  final String? documentUrl;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.venue,
    required this.eventType,
    required this.organizer,
    required this.createdAt,
    this.status = 'upcoming',
    this.documentUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'venue': venue,
      'eventType': eventType,
      'organizer': organizer,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'documentUrl': documentUrl,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      venue: map['venue'] ?? '',
      eventType: map['eventType'] ?? 'conference',
      organizer: map['organizer'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      status: map['status'] ?? 'upcoming',
      documentUrl: map['documentUrl'],
    );
  }

  String getFormattedDate() {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[startTime.month - 1]} ${startTime.day}, ${startTime.year}';
  }

  String getFormattedTime() {
    String formatTime(DateTime time) {
      final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }
    return formatTime(startTime);
  }

  String getEventTypeLabel() {
    switch (eventType.toLowerCase()) {
      case 'conference':
        return 'Conference';
      case 'seminar':
        return 'Seminar';
      case 'workshop':
        return 'Workshop';
      case 'webinar':
        return 'Webinar';
      case 'training':
        return 'Training';
      default:
        return 'Event';
    }
  }
}