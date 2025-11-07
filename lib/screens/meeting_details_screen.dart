import 'package:flutter/material.dart';
import 'package:meetbank/models/ActionItem.dart';
import 'package:meetbank/models/Meeting.dart';
import 'package:uuid/uuid.dart';

class MeetingDetailsScreen extends StatefulWidget {
  final Meeting meeting;

  const MeetingDetailsScreen({super.key, required this.meeting});

  @override
  State<MeetingDetailsScreen> createState() => _MeetingDetailsScreenState();
}

class _MeetingDetailsScreenState extends State<MeetingDetailsScreen> {
  late TextEditingController _minutesController;

  @override
  void initState() {
    super.initState();
    _minutesController = TextEditingController(text: widget.meeting.minutes);
  }

  void _addActionItem() {
    showDialog(
      context: context,
      builder: (context) {
        final taskController = TextEditingController();
        final assignedToController = TextEditingController();
        DateTime? dueDate;

        return AlertDialog(
          title: const Text('Add Action Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: taskController,
                decoration: const InputDecoration(labelText: 'Task Description'),
              ),
              TextField(
                controller: assignedToController,
                decoration: const InputDecoration(labelText: 'Assigned To'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (pickedDate != null) {
                    dueDate = pickedDate;
                  }
                },
                child: const Text('Select Due Date'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (taskController.text.isNotEmpty &&
                    assignedToController.text.isNotEmpty &&
                    dueDate != null) {
                  final newItem = ActionItem(
                    id: const Uuid().v4(),
                    taskDescription: taskController.text,
                    assignedTo: assignedToController.text,
                    dueDate: dueDate!,
                  );
                  setState(() {
                    widget.meeting.actionItems.add(newItem);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meeting.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              widget.meeting.minutes = _minutesController.text;
              Navigator.pop(context, widget.meeting);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Meeting Minutes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _minutesController,
              maxLines: 10,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter meeting minutes here...',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Action Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addActionItem,
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.meeting.actionItems.length,
                itemBuilder: (context, index) {
                  final item = widget.meeting.actionItems[index];
                  return ListTile(
                    title: Text(item.taskDescription),
                    subtitle: Text('Assigned to: ${item.assignedTo}\nDue: ${item.dueDate.toLocal().toString().split(' ')[0]}'),
                    trailing: Checkbox(
                      value: item.isCompleted,
                      onChanged: (value) {
                        setState(() {
                          item.isCompleted = value!;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
