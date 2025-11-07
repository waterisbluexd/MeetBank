import 'package:flutter/material.dart';
import 'package:meetbank/models/Meeting.dart';
import 'package:meetbank/screens/create_meeting_screen.dart';
import 'package:meetbank/screens/meeting_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  void _navigateAndAddMeeting() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateMeetingScreen()),
    );
  }

  void _navigateToMeetingDetails(Meeting meeting) async {
    final updatedMeeting = await Navigator.push<Meeting>(
      context,
      MaterialPageRoute(
        builder: (context) => MeetingDetailsScreen(meeting: meeting),
      ),
    );

    if (updatedMeeting != null) {
      await FirebaseFirestore.instance
          .collection('meetings')
          .doc(updatedMeeting.id)
          .update(updatedMeeting.toMap());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Meetings",
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('meetings').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final meetings = snapshot.data!.docs
              .map((doc) => Meeting.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

          if (meetings.isEmpty) {
            return _buildEmptyState();
          } else {
            return _buildMeetingList(meetings);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndAddMeeting,
        backgroundColor: const Color(0xFFB993D6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          const Text(
            'No Meetings Found',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first meeting.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingList(List<Meeting> meetings) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: meetings.length,
      itemBuilder: (context, index) {
        final meeting = meetings[index];
        return _buildMeetingCard(meeting);
      },
    );
  }

  Widget _buildMeetingCard(Meeting meeting) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: () => _navigateToMeetingDetails(meeting),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meeting.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                meeting.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${meeting.getFormattedDate()} • ${meeting.getFormattedTime()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(
                    'View Details',
                    style: TextStyle(
                      color: Color(0xFFB993D6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
