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
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'meetingLink': meetingLink,
      'linkType': linkType,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'minutes': minutes,
      'actionItems': actionItems.map((item) => item.toMap()).toList(),
      'summary': summary,
    };
  }

  factory Meeting.fromMap(Map<String, dynamic> map) {
    return Meeting(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      meetingLink: map['meetingLink'] ?? '',
      linkType: map['linkType'] ?? 'google_meet',
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      status: map['status'] ?? 'upcoming',
      minutes: map['minutes'] ?? '',
      actionItems: (map['actionItems'] as List?)
          ?.map((item) => ActionItem.fromMap(item))
          .toList() ??
          [],
      summary: map['summary'] ?? '',
    );
  }

  String getFormattedDate() {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[startTime.month - 1]} ${startTime.day}, ${startTime.year}';
  }

  // Get formatted time string
  String getFormattedTime() {
    String formatTime(DateTime time) {
      final hour = time.hour > 12 ? time.hour - 12 : time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }
    return '${formatTime(startTime)} - ${formatTime(endTime)}';
  }

  // Get meeting duration in minutes
  int getDurationInMinutes() {
    return endTime.difference(startTime).inMinutes;
  }
}
