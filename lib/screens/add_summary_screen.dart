import 'package:flutter/material.dart';
import 'package:meetbank/models/Meeting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSummaryScreen extends StatefulWidget {
  final Meeting meeting;

  const AddSummaryScreen({Key? key, required this.meeting}) : super(key: key);

  @override
  State<AddSummaryScreen> createState() => _AddSummaryScreenState();
}

class _AddSummaryScreenState extends State<AddSummaryScreen> {
  late TextEditingController _summaryController;

  @override
  void initState() {
    super.initState();
    _summaryController = TextEditingController(text: widget.meeting.summary);
  }

  Future<void> _saveSummary() async {
    try {
      await FirebaseFirestore.instance
          .collection('meetings')
          .doc(widget.meeting.id)
          .update({'summary': _summaryController.text});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Summary saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving summary: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add/Edit Summary'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _summaryController,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Meeting Summary',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveSummary,
              child: const Text('Save Summary'),
            ),
          ],
        ),
      ),
    );
  }
}
