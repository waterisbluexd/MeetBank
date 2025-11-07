import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:meetbank/models/Meeting.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meetbank/secrets.dart';

class AddSummaryScreen extends StatefulWidget {
  final Meeting meeting;

  const AddSummaryScreen({super.key, required this.meeting});

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

  Future<void> _generateSummaryAndKeywords() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: googleApiKey,
      );

      final bool useDescription = _summaryController.text.trim().isEmpty;
      final String sourceText =
          useDescription ? widget.meeting.description : _summaryController.text;
      final String sourceLabel =
          useDescription ? 'meeting description' : 'user notes';

      final prompt =
          '''Based on the following $sourceLabel, create a concise summary with 5-6 bullet points and also provide 5 to 7 relevant keywords separated by commas.

$sourceLabel:
$sourceText

Return ONLY the summary and keywords in the following format:

Summary:
* Bullet point 1
* Bullet point 2
* Bullet point 3
* Bullet point 4
* Bullet point 5

Keywords:
keyword1, keyword2, keyword3, keyword4, keyword5''';
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null) {
        final responseText = response.text!;
        final summaryMarker = 'Summary:';
        final keywordsMarker = 'Keywords:';

        final summaryIndex = responseText.indexOf(summaryMarker);
        final keywordsIndex = responseText.indexOf(keywordsMarker);

        if (summaryIndex != -1 && keywordsIndex != -1) {
          // Summary is between "Summary:" and "Keywords:"
          String summary = responseText
              .substring(summaryIndex + summaryMarker.length, keywordsIndex)
              .trim();
          _summaryController.text = summary;

          // Keywords are after "Keywords:"
          String keywords =
              responseText.substring(keywordsIndex + keywordsMarker.length).trim();
          _summaryKeywordsController.text = keywords;
        } else {
          // Fallback if markers are not found
          _summaryController.text =
              responseText; // Put the whole response in the summary.
          _summaryKeywordsController.text = ''; // Clear keywords
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating summary: $e'),
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
                hintText: 'Enter any notes here to help generate the summary.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _summaryKeywordsController,
              decoration: const InputDecoration(
                labelText: 'Keywords',
                hintText: 'Keywords will be generated here.',
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
                    onPressed: _generateSummaryAndKeywords,
                    child: const Text('Generate Summary & Keywords'),
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
