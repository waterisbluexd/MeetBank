import 'package:cloud_firestore/cloud_firestore.dart';

class ActionItem {
  final String id;
  final String taskDescription;
  final String assignedTo;
  final DateTime dueDate;
  bool isCompleted;

  ActionItem({
    required this.id,
    required this.taskDescription,
    required this.assignedTo,
    required this.dueDate,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskDescription': taskDescription,
      'assignedTo': assignedTo,
      'dueDate': Timestamp.fromDate(dueDate),
      'isCompleted': isCompleted,
    };
  }

  factory ActionItem.fromMap(Map<String, dynamic> map) {
    return ActionItem(
      id: map['id'] ?? '',
      taskDescription: map['taskDescription'] ?? '',
      assignedTo: map['assignedTo'] ?? '',
      dueDate: _parseDate(map['dueDate']),
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date is Timestamp) {
      return date.toDate();
    } else if (date is String) {
      return DateTime.parse(date);
    } else {
      return DateTime.now();
    }
  }
}
