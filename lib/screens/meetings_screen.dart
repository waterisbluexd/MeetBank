import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:meetbank/screens/cards/meeting_card.dart';
import 'package:meetbank/models/Meeting.dart';
import 'package:meetbank/screens/create_meeting_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meetbank/screens/add_summary_screen.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({Key? key}) : super(key: key);

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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

  void _editMeetingSummary(Meeting meeting) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSummaryScreen(meeting: meeting),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meetings"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search meetings...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.background,
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: "Upcoming"),
                    Tab(text: "Completed"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('meetings').orderBy('startTime', descending: false).snapshots(),
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
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateMeetingScreen()));
        },
        label: const Text("New Meeting"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMeetingsList(List<Meeting> meetings, String filter) {
    final now = DateTime.now();
    List<Meeting> filtered = [];

    if (filter == "upcoming") {
      filtered = meetings.where((m) => m.endTime.isAfter(now)).toList();
    } else if (filter == "completed") {
      filtered = meetings.where((m) => m.endTime.isBefore(now)).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((m) => m.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Sort upcoming meetings with ongoing at the top
    if (filter == "upcoming") {
      filtered.sort((a, b) {
        final aIsOngoing = a.startTime.isBefore(now) && a.endTime.isAfter(now);
        final bIsOngoing = b.startTime.isBefore(now) && b.endTime.isAfter(now);
        if (aIsOngoing && !bIsOngoing) return -1;
        if (!aIsOngoing && bIsOngoing) return 1;
        return a.startTime.compareTo(b.startTime);
      });
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? "No meetings found" : "No meetings match your search",
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
                onEdit: () => _editMeetingSummary(meeting),
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
            onEdit: () => _editMeetingSummary(meeting),
          ),
        );
      },
    );
  }
}
