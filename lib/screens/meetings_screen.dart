import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:meetbank/screens/cards/meeting_card.dart';
import 'package:meetbank/models/Meeting.dart';
import 'package:meetbank/screens/create_meeting_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({Key? key}) : super(key: key);

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deleteMeeting(String meetingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('meetings')
          .doc(meetingId)
          .delete();
    } catch (e) {
      // Handle errors, maybe show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting meeting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFB993D6),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFFB993D6),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: "Upcoming"),
                Tab(text: "Completed"),
                Tab(text: "All"),
              ],
            ),
          ),
        ),
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

          return TabBarView(
            controller: _tabController,
            children: [
              _buildMeetingsList(meetings, "upcoming"),
              _buildMeetingsList(meetings, "completed"),
              _buildMeetingsList(meetings, "all"),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateMeetingScreen()));
        },
        backgroundColor: const Color(0xFFB993D6),
        icon: const Icon(Icons.add, color: Colors.white,),
        label: const Text(
          "New Meeting",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildMeetingsList(List<Meeting> meetings, String filter) {
    final now = DateTime.now();
    List<Meeting> filtered = [];

    if (filter == "upcoming") {
      filtered = meetings.where((m) => m.startTime.isAfter(now)).toList();
    } else if (filter == "completed") {
      filtered = meetings.where((m) => m.endTime.isBefore(now)).toList();
    } else {
      filtered = meetings;
    }

    if (filter == "all") {
      final upcoming = filtered.where((m) => m.startTime.isAfter(now)).toList();
      final completed = filtered.where((m) => m.endTime.isBefore(now)).toList();

      upcoming.sort((a, b) => a.startTime.compareTo(b.startTime));
      completed.sort((a, b) => b.startTime.compareTo(a.startTime));

      filtered = [...upcoming, ...completed];
    } else {
      filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No meetings found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (kIsWeb) {
      return LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 1;
          if (constraints.maxWidth > 1200) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth > 800) {
            crossAxisCount = 2;
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: 380,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final meeting = filtered[index];
              return MeetingCard(
                id: meeting.id,
                title: meeting.title,
                description: meeting.description,
                startTime: meeting.startTime,
                endTime: meeting.endTime,
                meetingLink: meeting.meetingLink,
                linkType: meeting.linkType,
                onTap: () {},
                onDelete: () => _deleteMeeting(meeting.id),
              );
            },
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final meeting = filtered[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: MeetingCard(
            id: meeting.id,
            title: meeting.title,
            description: meeting.description,
            startTime: meeting.startTime,
            endTime: meeting.endTime,
            meetingLink: meeting.meetingLink,
            linkType: meeting.linkType,
            onTap: () {},
            onDelete: () => _deleteMeeting(meeting.id),
          ),
        );
      },
    );
  }
}
