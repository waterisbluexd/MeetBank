import 'package:flutter/material.dart';
import 'package:meetbank/models/meeting.dart';
import 'package:uuid/uuid.dart';

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final linkController = TextEditingController();

  DateTime? startTime;
  DateTime? endTime;

  Future<void> _pickDateTime(bool isStart) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2030),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null) return;

    final dateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) startTime = dateTime;
      else endTime = dateTime;
    });
  }

  void _saveMeeting() {
    if (!_formKey.currentState!.validate() ||
        startTime == null ||
        endTime == null) return;

    final meeting = Meeting(
      id: const Uuid().v4(),
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      startTime: startTime!,
      endTime: endTime!,
      meetingLink: linkController.text.trim(),
      linkType: 'google_meet',
      attendees: [],
      createdBy: 'admin',
      createdAt: DateTime.now(),
    );

    Navigator.pop(context, meeting);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Meeting"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Meeting Title'),
                validator: (v) =>
                v == null || v.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration:
                const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: linkController,
                decoration:
                const InputDecoration(labelText: 'Meeting Link'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                    startTime == null
                        ? "Select Start Time"
                        : "Start: ${startTime.toString()}"),
                trailing: const Icon(Icons.access_time),
                onTap: () => _pickDateTime(true),
              ),
              ListTile(
                title: Text(
                    endTime == null
                        ? "Select End Time"
                        : "End: ${endTime.toString()}"),
                trailing: const Icon(Icons.access_time),
                onTap: () => _pickDateTime(false),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveMeeting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB993D6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Save Meeting",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
