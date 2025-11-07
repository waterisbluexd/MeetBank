import 'package:flutter/material.dart';
import 'package:meetbank/models/Events.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final venueController = TextEditingController();
  String? documentUrl;
  bool _isSaving = false;

  DateTime? startTime;
  DateTime? endTime; // Added endTime
  String selectedEventType = 'conference';

  final List<Map<String, dynamic>> eventTypes = [
    {'value': 'conference', 'label': 'Conference', 'icon': Icons.business_center},
    {'value': 'seminar', 'label': 'Seminar', 'icon': Icons.school},
    {'value': 'workshop', 'label': 'Workshop', 'icon': Icons.construction},
    {'value': 'webinar', 'label': 'Webinar', 'icon': Icons.wifi},
    {'value': 'training', 'label': 'Training', 'icon': Icons.model_training},
  ];

  // Modified to handle both start and end time
  Future<void> _pickDateTime(bool isStart) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFB993D6),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate == null) return;

    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFB993D6),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
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
      if (isStart) {
        startTime = dateTime;
      } else {
        endTime = dateTime;
      }
    });
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        documentUrl = result.files.single.path;
      });
    }
  }

  Future<void> _saveEvent() async {
    // Added validation for endTime
    if (!_formKey.currentState!.validate() || startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields, including start and end times.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (endTime!.isBefore(startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time cannot be before the start time.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create an event.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    // Added endTime to the Event object
    final event = Event(
      id: const Uuid().v4(),
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      startTime: startTime!,
      endTime: endTime!,
      venue: venueController.text.trim(),
      eventType: selectedEventType,
      organizer: user.displayName ?? 'Admin',
      createdAt: DateTime.now(),
      documentUrl: documentUrl,
      createdBy: user.uid,
    );

    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(event.id)
          .set(event.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save event: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    venueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Create New Event",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 600 : double.infinity),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isWeb ? 24 : 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      controller: titleController,
                      label: 'Event Title',
                      hint: 'e.g., Annual Conference 2025',
                      icon: Icons.event_note,
                      validator: (v) =>
                      v == null || v.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: descriptionController,
                      label: 'Description',
                      hint: 'What\'s this event about?',
                      icon: Icons.description_outlined,
                      maxLines: 4,
                      validator: (v) =>
                      v == null || v.isEmpty ? 'Description is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: venueController,
                      label: 'Venue',
                      hint: 'e.g., Main Auditorium, Building A',
                      icon: Icons.location_on_outlined,
                      validator: (v) =>
                      v == null || v.isEmpty ? 'Venue is required' : null,
                    ),
                    const SizedBox(height: 24),
                    _buildEventTypeSelector(),
                    const SizedBox(height: 24),
                    _buildDateTimeCard(
                      title: 'Start Time',
                      dateTime: startTime,
                      icon: Icons.calendar_today_rounded,
                      onTap: () => _pickDateTime(true), // Point to the modified picker
                    ),
                    const SizedBox(height: 12),
                    // Added the End Time picker
                    _buildDateTimeCard(
                      title: 'End Time',
                      dateTime: endTime,
                      icon: Icons.event_available_rounded,
                      onTap: () => _pickDateTime(false),
                    ),
                    const SizedBox(height: 16),
                    _buildDocumentPicker(),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB993D6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                          : const Text(
                        "Create Event",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFFB993D6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFB993D6), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  Widget _buildEventTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category_outlined, color: const Color(0xFFB993D6), size: 20),
              const SizedBox(width: 8),
              Text(
                'Event Type',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: eventTypes.map((type) {
              final isSelected = selectedEventType == type['value'];
              return InkWell(
                onTap: () {
                  setState(() {
                    selectedEventType = type['value'] as String;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFB993D6).withOpacity(0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFB993D6)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type['icon'] as IconData,
                        size: 18,
                        color: isSelected
                            ? const Color(0xFFB993D6)
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        type['label'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFFB993D6)
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeCard({
    required String title,
    required DateTime? dateTime,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dateTime != null
                ? const Color(0xFFB993D6).withOpacity(0.3)
                : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFB993D6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFB993D6),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateTime != null
                        ? DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime)
                        : 'Select date and time',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: dateTime != null
                          ? const Color(0xFF1A1A2E)
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentPicker() {
    return InkWell(
      onTap: _pickDocument,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: documentUrl != null
                ? const Color(0xFFB993D6).withOpacity(0.3)
                : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFB993D6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.attach_file,
                color: Color(0xFFB993D6),
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                documentUrl ?? 'Attach a document',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: documentUrl != null
                      ? const Color(0xFF1A1A2E)
                      : Colors.grey.shade400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
