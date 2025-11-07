import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
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

  void _showSummaryDialog() {
    showDialog(
      context: context,
      // Use a barrier to prevent dismissal on outside tap
      barrierDismissible: false,
      builder: (context) {
        return SummaryDialog(meeting: widget.meeting);
      },
    ).then((_) {
      // Re-render the screen to show the updated summary and keywords
      setState(() {});
    });
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
              // Pass the updated meeting object back to the previous screen
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
            // Display Summary and Keywords
            const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (widget.meeting.summary.isNotEmpty)
              Text(widget.meeting.summary)
            else
              const Text('No summary added yet.', style: TextStyle(fontStyle: FontStyle.italic)),
            if(widget.meeting.summaryKeywords.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: widget.meeting.summaryKeywords.map((k) => Chip(label: Text(k))).toList(),
                ), 
              ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(widget.meeting.summary.isEmpty ? 'Add Summary' : 'Edit Summary'),
                onPressed: _showSummaryDialog,
              ),
            ),
            const Divider(height: 40),

            // Action Items Section
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

// Stateful Dialog for adding/editing a summary and generating keywords
class SummaryDialog extends StatefulWidget {
  final Meeting meeting;

  const SummaryDialog({super.key, required this.meeting});

  @override
  State<SummaryDialog> createState() => _SummaryDialogState();
}

class _SummaryDialogState extends State<SummaryDialog> {
  late final TextEditingController _summaryController;
  late List<String> _generatedKeywords;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _summaryController = TextEditingController(text: widget.meeting.summary);
    _generatedKeywords = List<String>.from(widget.meeting.summaryKeywords);
  }

  Future<void> _generateKeywords() async {
    // WARNING: Paste your secret API key here. Do not commit it to a public repository.
    const apiKey = 'PASTE_YOUR_API_KEY_HERE'; 

    if (_summaryController.text.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a summary first.')));
        return;
    }

    setState(() => _isGenerating = true);

    try {
        final model = GenerativeModel(
            model: 'gemini-pro',
            apiKey: apiKey,
            generationConfig: GenerationConfig(responseMimeType: 'application/json'),
        );
        final prompt =
            'Analyze the following meeting summary and extract a list of 5-10 searchable keywords. Return the output as a valid JSON object with a single key: "keywords" (an array of strings).\n\nSummary: ${_summaryController.text}';

        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);

        if (response.text != null) {
            final jsonResponse = jsonDecode(response.text!) as Map<String, dynamic>;
            final keywords = List<String>.from(jsonResponse['keywords'] as List? ?? []);
            setState(() {
                _generatedKeywords = keywords;
            });
        } else {
            throw Exception('Failed to get a response from the model.');
        }
    } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
        setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add/Edit Summary'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8, // Set a width for the dialog
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _summaryController,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter meeting summary here...',
                ),
              ),
              const SizedBox(height: 16),
              if (_isGenerating)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                    onPressed: _generateKeywords,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Generate Keywords'),
                ),
              const SizedBox(height: 16),
              if (_generatedKeywords.isNotEmpty)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _generatedKeywords.map((k) => Chip(label: Text(k))).toList(),
                )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            widget.meeting.summary = _summaryController.text;
            widget.meeting.summaryKeywords = _generatedKeywords;
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
