import 'package:cloud_firestore/cloud_firestore.dart';

import './ActionItem.dart';

class Meeting {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String meetingLink;
  final String linkType;
  final String createdBy;
  final DateTime createdAt;
  String status;
  String minutes;
  List<ActionItem> actionItems;
  String summary;
  List<String> summaryKeywords;

  Meeting({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.meetingLink,
    required this.linkType,
    required this.createdBy,
    required this.createdAt,
    this.status = 'upcoming',
    this.minutes = '',
    this.actionItems = const [],
    this.summary = '',
    this.summaryKeywords = const [],
  });

  // Converts a Meeting object to a map, using Firestore's native Timestamp format.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'meetingLink': meetingLink,
      'linkType': linkType,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'minutes': minutes,
      'actionItems': actionItems.map((item) => item.toMap()).toList(),
      'summary': summary,
      'summaryKeywords': summaryKeywords,
    };
  }

  // Creates a Meeting object from a Firestore map.
  // It robustly handles both old (String) and new (Timestamp) date formats.
  factory Meeting.fromMap(Map<String, dynamic> map) {
    return Meeting(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startTime: _parseDate(map['startTime']),
      endTime: _parseDate(map['endTime']),
      meetingLink: map['meetingLink'] ?? '',
      linkType: map['linkType'] ?? 'google_meet',
      createdBy: map['createdBy'] ?? '',
      createdAt: _parseDate(map['createdAt']),
      status: map['status'] ?? 'upcoming',
      minutes: map['minutes'] ?? '',
      actionItems: (map['actionItems'] as List?)
              ?.map((item) => ActionItem.fromMap(item))
              .toList() ??
          [],
      summary: map['summary'] ?? '',
      summaryKeywords: List<String>.from(map['summaryKeywords'] ?? []),
    );
  }

  // Helper function to flexibly parse dates, preventing crashes from old data formats.
  static DateTime _parseDate(dynamic date) {
    if (date is Timestamp) {
      return date.toDate(); // Handles new data.
    } else if (date is String) {
      return DateTime.parse(date); // Handles old data.
    } else {
      // Fallback for any unexpected null or invalid data.
      return DateTime.now();
    }
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
      final hour = time.hour > 12 ? time.hour - 12 : time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }
    return '${formatTime(startTime)} - ${formatTime(endTime)}';
  }

  int getDurationInMinutes() {
    return endTime.difference(startTime).inMinutes;
  }
}
