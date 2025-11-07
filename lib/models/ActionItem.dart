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
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory ActionItem.fromMap(Map<String, dynamic> map) {
    return ActionItem(
      id: map['id'] ?? '',
      taskDescription: map['taskDescription'] ?? '',
      assignedTo: map['assignedTo'] ?? '',
      dueDate: DateTime.parse(map['dueDate']),
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}
