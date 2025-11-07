import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String venue;
  final String eventType;
  final String organizer;
  final DateTime createdAt;
  final String status;
  final String? documentUrl;
  final String createdBy;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.venue,
    required this.eventType,
    required this.organizer,
    required this.createdAt,
    this.status = 'upcoming',
    this.documentUrl,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'venue': venue,
      'eventType': eventType,
      'organizer': organizer,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'documentUrl': documentUrl,
      'createdBy': createdBy,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    DateTime _parseTimestamp(dynamic value, DateTime fallback) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.tryParse(value) ?? fallback;
      }
      return fallback;
    }

    final now = DateTime.now();
    final createdAt = _parseTimestamp(map['createdAt'], now);
    final startTime = _parseTimestamp(map['startTime'], createdAt);
    final endTime = _parseTimestamp(map['endTime'], startTime);

    return Event(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled Event',
      description: map['description'] as String? ?? '',
      startTime: startTime,
      endTime: endTime,
      venue: map['venue'] as String? ?? 'No venue specified',
      eventType: map['eventType'] as String? ?? 'general',
      organizer: map['organizer'] as String? ?? '',
      createdAt: createdAt,
      status: map['status'] as String? ?? 'upcoming',
      documentUrl: map['documentUrl'] as String?,
      createdBy: map['createdBy'] as String? ?? '',
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
    final hour = startTime.hour > 12 ? startTime.hour - 12 : (startTime.hour == 0 ? 12 : startTime.hour);
    final minute = startTime.minute.toString().padLeft(2, '0');
    final period = startTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
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
