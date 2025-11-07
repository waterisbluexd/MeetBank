import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:meetbank/screens/cards/meeting_card.dart';
import 'package:meetbank/models/meeting.dart';
import 'package:uuid/uuid.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({Key? key}) : super(key: key);

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Meeting> meetings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    meetings = _getDummyMeetings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMeetingsList("upcoming"),
          _buildMeetingsList("completed"),
          _buildMeetingsList("all"),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newMeeting = await Navigator.pushNamed(context, '/create-meeting');

          if (newMeeting != null && newMeeting is Meeting) {
            setState(() {
              meetings.add(newMeeting);
            });
          }
        },
        backgroundColor: const Color(0xFFB993D6),
        icon: const Icon(Icons.add),
        label: const Text(
          "New Meeting",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildMeetingsList(String filter) {
    final now = DateTime.now();
    List<Meeting> filtered = [];

    if (filter == "upcoming") {
      filtered = meetings.where((m) => m.startTime.isAfter(now)).toList();
    } else if (filter == "completed") {
      filtered = meetings.where((m) => m.endTime.isBefore(now)).toList();
    } else {
      filtered = meetings;
    }

    // Sort: upcoming meetings first (sorted by date), then completed meetings
    if (filter == "all") {
      final upcoming = filtered.where((m) => m.startTime.isAfter(now)).toList();
      final completed = filtered.where((m) => m.endTime.isBefore(now)).toList();

      upcoming.sort((a, b) => a.startTime.compareTo(b.startTime));
      completed.sort((a, b) => b.startTime.compareTo(a.startTime)); // Most recent first

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
            const SizedBox(height: 8),
            Text(
              "Create your first meeting to get started",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Check if running on web for responsive layout
    if (kIsWeb) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Calculate number of columns based on screen width
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
              mainAxisExtent: 380, // Increased height to prevent overflow
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
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/meeting-details',
                    arguments: meeting.id,
                  );
                },
              );
            },
          );
        },
      );
    }

    // Mobile view - keep list layout
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
            onTap: () {
              Navigator.pushNamed(
                context,
                '/meeting-details',
                arguments: meeting.id,
              );
            },
          ),
        );
      },
    );
  }

  List<Meeting> _getDummyMeetings() {
    final now = DateTime.now();
    return [
      Meeting(
        id: const Uuid().v4(),
        title: 'Board of Directors Q1 Review',
        description:
        'Quarterly review of company performance, strategic initiatives, and financial results for Q1 2025.',
        startTime: now.add(const Duration(days: 2, hours: 10)),
        endTime: now.add(const Duration(days: 2, hours: 12)),
        meetingLink: 'https://meet.google.com/abc-defg-hij',
        linkType: 'google_meet',
        createdBy: 'admin',
        createdAt: now,
      ),
      Meeting(
        id: const Uuid().v4(),
        title: 'Policy Review Committee',
        description:
        'Monthly policy review meeting to discuss updates and changes to institutional policies.',
        startTime: now.add(const Duration(days: 3, hours: 14)),
        endTime: now.add(const Duration(days: 3, hours: 15, minutes: 30)),
        meetingLink: 'https://zoom.us/j/1234567890',
        linkType: 'zoom',
        createdBy: 'admin',
        createdAt: now,
      ),
      Meeting(
        id: const Uuid().v4(),
        title: 'Annual Budget Planning',
        description:
        'Strategic planning session for the 2025-2026 fiscal year budget allocation.',
        startTime: now.add(const Duration(days: 5, hours: 9)),
        endTime: now.add(const Duration(days: 5, hours: 11)),
        meetingLink: 'https://teams.microsoft.com/l/meetup-join/xyz',
        linkType: 'teams',
        createdBy: 'admin',
        createdAt: now,
      ),
      Meeting(
        id: const Uuid().v4(),
        title: 'Team Sync - Marketing',
        description:
        'Weekly marketing team sync to discuss ongoing campaigns and upcoming initiatives.',
        startTime: now.subtract(const Duration(days: 2, hours: 10)),
        endTime: now.subtract(const Duration(days: 2, hours: 11)),
        meetingLink: 'https://meet.google.com/xyz-abcd-efg',
        linkType: 'google_meet',
        createdBy: 'admin',
        createdAt: now,
        status: 'completed',
      ),
    ];
  }
}