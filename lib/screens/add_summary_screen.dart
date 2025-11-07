import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:meetbank/models/Meeting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meetbank/secrets.dart';

class AddSummaryScreen extends StatefulWidget {
  final Meeting meeting;

  const AddSummaryScreen({Key? key, required this.meeting}) : super(key: key);

  @override
  State<AddSummaryScreen> createState() => _AddSummaryScreenState();
}

class _AddSummaryScreenState extends State<AddSummaryScreen> {
  late TextEditingController _summaryController;
  late TextEditingController _summaryKeywordsController;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _summaryController = TextEditingController(text: widget.meeting.summary);
    _summaryKeywordsController =
        TextEditingController(text: widget.meeting.summaryKeywords.join(', '));
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _summaryKeywordsController.dispose();
    super.dispose();
  }

  Future<void> _generateKeywords() async {
    if (_summaryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a summary first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _isGenerating = true;
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: googleApiKey,
      );
      final prompt = 'Generate 5 to 7 keywords for the following meeting summary, separated by commas: ${_summaryController.text}';
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null) {
        _summaryKeywordsController.text = response.text!;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating keywords: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _saveSummary() async {
    try {
      final keywords = _summaryKeywordsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await FirebaseFirestore.instance
          .collection('meetings')
          .doc(widget.meeting.id)
          .update({
        'summary': _summaryController.text,
        'summaryKeywords': keywords,
      });
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
            TextField(
              controller: _summaryKeywordsController,
              decoration: const InputDecoration(
                labelText: 'Generative summary keywords',
                hintText: 'Enter keywords separated by commas',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_isGenerating)
              const CircularProgressIndicator()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _generateKeywords,
                    child: const Text('Generate Keywords'),
                  ),
                  ElevatedButton(
                    onPressed: _saveSummary,
                    child: const Text('Save Summary'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
